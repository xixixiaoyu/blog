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
    window.JSBridge.postMessage(JSON.stringify(message))
  } else {
    // iOS 调用方式
    window.webkit.messageHandlers.JSBridge.postMessage(message)
  }
}
```
##### 方式二：URL Scheme 拦截 (JavaScript “写信”给 Native)
这种方式更像一种“暗号通信”。
JavaScript 通过改变 `location.href` 或创建一个 `iframe`，加载一个具有特殊协议（Scheme）的 URL，例如 `myapp://getDeviceId?callback=handleId`。
Native 端会设置一个“拦截器”，专门监听所有 URL 请求。一旦发现是 `myapp://` 开头的，就不会去加载它，而是解析其中的参数，执行对应的 Native 功能。
这种方式的优点是兼容性极好，但缺点也很明显：URL 长度有限制，且通信效率相对较低。

##### Native 如何“呼叫” JavaScript？
反过来就简单多了。Native 拥有 WebView 的最高控制权，可以直接让 WebView 执行一段 JavaScript 字符串。


