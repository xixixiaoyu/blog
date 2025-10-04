我们不妨从一个最根本的问题开始：当我们在一个 App 的网页里点击一个按钮，希望能调用原生的摄像头，或者在原生界面发生某个操作后，希望能通知网页更新内容，这两个看似在“不同世界”的技术，是如何实现对话的呢？
### 1. JSBridge：横跨 JavaScript 与 Native 的鸿沟之桥
在 Hybrid 应用中，WebView 运行着我们的前端代码，而 Native（Android 或 iOS）则掌控着设备和底层能力。
它们之间隔着一道无形的墙，而 JSBridge，就是在这道墙上搭建的一座精密桥梁，让信息可以双向通行。
#### 1.1 这座桥怎么用？——JSBridge 的三种基本对话模式
想象一下，这座桥上有三种不同的交通方式：
1. **单向广播**：你只需要向 Native 发送一个消息，不关心它是否收到，也不需要回复。比如上报一些用户行为日志。
```js
const payload = {
  name: '跨端开发指南',
  author: '云牧'
}
// 假设 JSBridge 已被注入
JSBridge.postMessage({
  type: 'webview_event',
  payload
})
```
2. **请求与响应**：你请求 Native 做一件事（如获取设备信息），并且需要它把结果返回给你。这是最常用的一种模式。
```js
JSBridge.invoke('getDeviceInfo', {}, function(res) {
  // 这里的回调函数会在 Native 操作完成后被调用
  console.log('设备信息是：', res)
})
```
3. **事件监听**：你告诉 Native：“嘿，如果某个特定事件发生了（比如用户按了返回键），请务必通知我。”
```js
JSBridge.registerEvent('onNativeBackPressed', function() {
  // 当 Native 触发 'onNativeBackPressed' 事件时，这个函数会执行
  console.log('用户点击了返回键！')
})
```
#### 1.2 桥梁是如何建造的？——JSBridge 的实现原理
JSBridge 的实现并非一方之功，而是 Native 与 JavaScript 共同遵守的“约定”。我们来看看 JavaScript 是如何“呼叫” Native 的。
##### 方式一：API 注入 (Native “送礼”给 JavaScript)

这是最直接、也是目前最主流的方式。
Native 在加载 WebView 时，主动将一个对象“注入”到 JavaScript 的全局环境 `window` 对象上。这个对象里的方法，就映射着 Native 的功能。
- **在 Android 端**，通过 `addJavascriptInterface` 方法，可以将一个 Java 类的方法映射到 JavaScript 中。
```java
// Android 代码示例
WebView webView = findViewById(R.id.webview);
// 将名为 JavaScriptInterface 的类映射为 "JSBridge" 对象
webView.addJavascriptInterface(new JavaScriptInterface(), "JSBridge");
```
这样，在 JavaScript 中就可以直接调用 `window.JSBridge.xxx()` 了。
- **在 iOS 端 (WKWebView)**，则通过 `addScriptMessageHandler` 来配置消息处理。
```Objective-c
// iOS 代码示例
[userContentController addScriptMessageHandler:self name:@"JSBridge"];
```
iOS 的调用路径稍有不同，需要通过 `window.webkit.messageHandlers.JSBridge` 来访问。
因此，为了屏蔽这种差异，我们前端需要做一层兼容处理：
```js

function callNative(message) {
  const isAndroid = /Android/.test(navigator.userAgent)
  if (isAndroid) {
    // Android 调用方式
    // 而 Android 的 addJavascriptInterface 注入的方法，为了通用和健壮性，通常会定义一个接收 String 类型参数的方法。前端将 JSON 对象序列化为字符串传递过去，Android 端再反序列化为 JSON 对象。这是一种约定俗成的最佳实践。
    window.JSBridge.postMessage(JSON.stringify(message)) // 传递字符串
  } else {
    // iOS 调用方式
    // iOS 的 WKWebView 的 postMessage 方法本身支持传递可被序列化的 JavaScript 对象（如 Object, Array, String, Number, Date 等），系统会自动处理转换。
    window.webkit.messageHandlers.JSBridge.postMessage(message) // 传递对象
  }
}
```
iOS 的 postMessage 是 WKScriptMessageHandler 协议的标准方法，是系统提供的。
而 Android 为了实现统一的 postMessage 调用，我们需要在 Android 的 JavaScriptInterface 类中，同样定义一个名为 postMessage 的公共方法，用于接收前端传递过来的消息字符串。
##### 方式二：URL Scheme 拦截 (JavaScript “写信”给 Native)
这种方式更像一种“暗号通信”。
JavaScript 通过改变 `location.href` 或创建一个 `iframe`，加载一个具有特殊协议（Scheme）的 URL，例如 `myapp://getDeviceId?callback=handleId`。
Native 端会设置一个“拦截器”，专门监听所有 URL 请求。一旦发现是 `myapp://` 开头的，就不会去加载它，而是解析其中的参数，执行对应的 Native 功能。
这种方式的优点是兼容性极好，但缺点也很明显：URL 长度有限制，且通信效率相对较低。

##### Native 如何“呼叫” JavaScript？
反过来就简单多了。Native 拥有 WebView 的最高控制权，可以直接让 WebView 执行一段 JavaScript 字符串。
- **Android** 可以使用 `loadUrl("javascript:...")` 或更高效的 `evaluateJavascript(...)`。
- **iOS** 可以使用 `evaluateJavaScript(...)`。
**关键点**：Native 能调用的，必须是 JavaScript 全局 `window` 对象上的函数。例如，`webview.evaluateJavascript("window.myGlobalFunc()")`。

#### 1.3 亲手搭建一座 JSBridge (前端实现)
因为 JavaScript 和 Native 之间传递的数据会被序列化，函数是无法直接传递的。怎么办呢？
我们可以给每个回调函数分配一个唯一的 ID，把函数本身存起来，只把这个 ID 传给 Native。
当 Native 处理完毕后，带着这个 ID 回调，我们再根据 ID 找到并执行对应的函数。
下面是一个精炼的实现，请注意看注释，它解释了设计的思路：
```js
/**
 * JSBridge 核心实现
 * 设计思路：
 * 1. 封装平台差异，提供统一的调用入口。
 * 2. 维护一个回调函数映射表（responseCallbacks），用 callbackId 作为 key。
 * 3. 当 JS 调用 Native 并需要回调时，生成唯一 callbackId，将回调函数存入映射表，并将 ID 发送给 Native。
 * 4. Native 执行完毕后，通过调用 window._handleNativeCallback，将 callbackId 和结果返回。
 * 5. JS 端根据 callbackId 从映射表中取出并执行回调，完成后删除该回调。
 * 6. 对于事件监听，维护一个事件映射表（eventHandlers），原理类似。
 */
class JSBridge {
  constructor() {
    // 存储 invoke 方法的回调函数 { callbackId: function }
    this.responseCallbacks = new Map()
    // 存储 registerEvent 注册的事件监听函数 { eventName: function }
    this.eventHandlers = new Map()
    // 自增的回调 ID
    this.callbackId = 0

    // 在 window 上挂载两个全局方法，供 Native 调用
    // 这是 Native 向 JS 通信的“约定接口”
    window._handleNativeCallback = this.handleNativeCallback.bind(this)
    window._handleNativeEvent = this.handleNativeEvent.bind(this)
  }

  // 调用 Native 方法，并期望得到回调
  invoke(name, params, callback) {
    this.callbackId++
    // 将回调函数存起来，等待 Native 的回调
    this.responseCallbacks.set(this.callbackId, callback)

    const message = {
      eventType: 'invoke',
      name: name,
      params: params,
      // 关键：传递的是 ID，而不是函数本身
      callbackId: this.callbackId
    }

    this._sendNativeMessage(message)
  }

  // 注册一个事件，供 Native 主动通知
  registerEvent(eventName, callback) {
    this.eventHandlers.set(eventName, callback)
  }

  // 处理 Native 的 invoke 回调
  handleNativeCallback(jsonResponse) {
    const res = JSON.parse(jsonResponse)
    const { callbackId, ...data } = res
    const callback = this.responseCallbacks.get(callbackId)

    if (callback) {
      callback(data)
    }

    // 执行完毕后，删除这个回调，释放内存
    this.responseCallbacks.delete(callbackId)
  }

  // 处理 Native 的主动事件通知
  handleNativeEvent(jsonResponse) {
    const res = JSON.parse(jsonResponse)
    const { eventName, ...data } = res
    const handler = this.eventHandlers.get(eventName)

    if (handler) {
      handler(data)
    }
  }

  // 封装向 Native 发送消息的底层逻辑，处理平台差异
  _sendNativeMessage(message) {
    const isAndroid = /Android/.test(navigator.userAgent)
    const messageStr = JSON.stringify(message)

    if (isAndroid) {
      // Android 端调用方式
      window.JSBridge && window.JSBridge.postMessage(messageStr)
    } else {
      // iOS 端调用方式
      window.webkit && window.webkit.messageHandlers.JSBridge && window.webkit.messageHandlers.JSBridge.postMessage(message)
    }
  }
}

export default new JSBridge()
```

### 2. 小程序的通信艺术：双线程模型下的精巧设计
聊完了 WebView，我们再看看小程序。
小程序的通信挑战更大，因为它采用了“双线程模型”：**逻辑层** 运行 JavaScript，**视图层** 负责渲染。两者被物理隔离，所有通信都必须通过 Native 作为“中转站”。
这意味着，一次简单的 `setData`，数据路径是：**逻辑层 JS -> Native -> 视图层（执行渲染指令）**。一来一回，通信成本相当高。因此，小程序提供了多种通信模式来应对不同场景。
#### 2.1 官方工具箱：父子、祖孙间的通信

1. **`properties` + `triggerEvent`：标准的父子通信**
    - **父传子**：父组件通过 `properties` 将数据传递给子组件。
    - **子传父**：子组件通过 `this.triggerEvent()` 触发自定义事件，父组件通过 `bind:xxx` 监听。
2. **`selectComponent`：父组件直接调用子组件方法**  
    如果父组件只是想“命令”子组件做某件事，而不传递数据，可以通过 `this.selectComponent('.class-name')` 获取子组件实例，然后直接调用其方法。这是一种更直接、更强力的控制。
3. **`relations`：血脉相连的组件通信**  
    对于像 `<swiper>` 和 `<swiper-item>` 这种必须紧密协作的组件，小程序提供了 `relations` 选项。通过定义父子关系，它们可以直接获取到对方的实例，进行高效通信，仿佛家人间的默契。
#### 2.2 打破层级：发布订阅模式的力量

官方的工具箱在处理跨层级或兄弟组件通信时，会显得力不从心。比如，A 组件想通知远房亲戚 C 组件，数据需要 A -> Native -> B -> Native -> C，效率极低。
发布订阅模式的优势在于，它**避免了组件间为了传递消息而进行的多次、繁琐的 properties 和 triggerEvent 通信**（这些通信本身也可能涉及数据在 Native 层的中转）。它将复杂的组件间信令传递简化为逻辑层内部的高效操作，但如果信令最终导致 UI 更新，那么更新本身依然需要遵循双线程的通信模型。
想象一下，所有组件都在一个“微信群”里：
- D 组件（接收者）在群里说：“我对 `messageChange` 事件感兴趣，谁发这个消息都请告诉我。”
- F 组件（发送者）在群里喊：“我发布了 `messageChange` 事件，内容是 'Hello World'！”

D 组件立刻就收到了消息，整个过程高效且解耦。
```js
// eventBus.js
class Bus {
  constructor() {
    this.events = {}
  }
  // 订阅事件
  on(eventName, fn) {
    if (!this.events[eventName]) {
      this.events[eventName] = []
    }
    this.events[eventName].push(fn)
  }
  // 发布事件
  emit(eventName, payload) {
    if (this.events[eventName]) {
      this.events[eventName].forEach(fn => fn(payload))
    }
  }
  // 取消订阅
  off(eventName, fn) {
    if (this.events[eventName]) {
      this.events[eventName] = this.events[eventName].filter(eventFn => eventFn !== fn)
    }
  }
}
export const BusService = new Bus()

// D 组件 (订阅者)
import { BusService } from './eventBus'
Component({
  lifetimes: {
    attached() {
      // 组件创建时，订阅事件
      BusService.on('messageChange', this.handleMessage)
    },
    detached() {
      // 组件销毁时，取消订阅，防止内存泄漏
      BusService.off('messageChange', this.handleMessage)
    }
  },
  methods: {
    handleMessage(data) {
      console.log('D 组件收到了消息:', data)
    }
  }
})

// F 组件 (发布者)
import { BusService } from './eventBus'
Component({
  methods: {
    sendMessageToD() {
      // 发布事件
      BusService.emit('messageChange', '你好，我是 F 组件')
    }
  }
})
```

### **总结与展望**
今天，我们一起深入探索了跨端通信的两个核心领域：
- 在 **WebView** 世界，我们通过 **JSBridge** 这座双向桥梁，利用 **API 注入** 或 **URL Scheme 拦截** 等方式，实现了 JavaScript 与 Native 的高效对话。其核心在于对回调函数的巧妙管理。
- 在 **小程序** 世界，受制于 **双线程模型**，通信成本更高。我们既可以使用官方提供的 `properties`、`triggerEvent` 等工具进行规范的组件通信，也可以借助 **发布订阅模式**，在逻辑层内实现高效、解耦的跨层级通信。

理解了这些通信原理，我们就能更好地设计应用架构，避免因通信不当导致的性能瓶颈或维护难题。那么，在一个拥有成百上千个组件的大型 C 端项目中，我们又该如何设计一套高效、可维护的通信模型呢？