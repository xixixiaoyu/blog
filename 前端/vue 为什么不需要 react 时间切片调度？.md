# React 更新
首先我们看下 React 的渲染更新流程：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762065492093-9f683ec2-04d7-4920-bae8-ca7df2c22d20.png)

当组件 setState 或 props 改变触发更新时，React 会根据新状态生成虚拟 DOM，然后与旧虚拟 DOM 对比（Diff）。根据差异更新需要改变的视图。

而 React 时间切片和 Fiber 技术就是为了解决这个 计算差异 时间过长，导致主线程长时间被占用，引发的页面卡顿的问题。



## React 16 之前的更新路径
在 React 16 之前，更新会从根组件开始，递归不可中断地对比每个组件的新旧虚拟 DOM：

```javascript
function reconcile(parent) {
  for (child of parent.children) {
    reconcile(child); // 递归
  }
}
```

比如下面组件树：

```bash
<App>
  <Header />
  <Main>
    <Sidebar />
    <Content />
  </Main>
</App>
```

当 `<Content>`的状态变化时，会从 `<App>` 一路对比 新旧虚拟 DOM 到 `<Content>`。

这其中有差异的话，就会立即更新该组件的真实 DOM，整个过程是同步且连续的。

这样如果组件树很庞大，很明显就会导致页面卡顿：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762065906883-5059edcd-4248-449a-851a-b0cce1790d51.png)

此时，Fiber 闪亮登场。



## Fiber 架构
Fiber 架构是为了解决上述问题而引入的。

Fiber 本质上就是个 JS 对象，不过这个对象是链表结构：

```javascript
{
  type: ...,           // 组件类型（如函数、类、'div' 等）
  key: ...,            // key 属性
  props: ...,          // props
  stateNode: ...,      // 对应的真实 DOM 节点或组件实例
  child: ...,          // 第一个子 Fiber
  sibling: ...,        // 下一个兄弟 Fiber
  return: ...,         // 父 Fiber
  pendingProps: ...,   // 新的 props（待处理）
  memoizedProps: ...,  // 上一次渲染使用的 props
  memoizedState: ...,  // 上一次渲染使用的 state
  flags: ...,      // 副作用标记（如 Placement、Update、Deletion）
  nextEffect: ...,     // 用于副作用链表
  alternate: ...,      // 指向 work-in-progress 或 current 树的对应节点
  // ... 其他调度和优先级相关字段
}
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762066123224-4fbdc673-57ab-4bcf-b17a-08b5e19ad86a.png)

React 会使用这些 Fiber 对象构建一棵可中断、可恢复的“Fiber 树”。

对于这个结构：

 ![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762066573712-492ea9b1-e732-4641-83e3-79545d2aaeb6.png)

Fiber 树长这样：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762066588437-156c764c-2845-4cfa-b285-78b97bf12870.png)

这个树可以用循环 + 指针移动来遍历：

```javascript
// 下一个待处理的 Fiber 节点
let nextUnitOfWork = null

// 调度器主循环：在浏览器空闲时执行
function workLoop(deadline) {
  let shouldYield = false
  
  // 循环条件：有工作且无需让出控制权
  while (nextUnitOfWork && !shouldYield) {
    nextUnitOfWork = performUnitOfWork(nextUnitOfWork)
    shouldYield = deadline.timeRemaining() < 1  // 检查剩余时间
  }
  
  // 工作未完成则继续调度
  if (nextUnitOfWork) requestIdleCallback(workLoop)
}

// 处理单个 Fiber 节点的完整生命周期
function performUnitOfWork(workInProgressFiber) {
  // 递阶段：深度优先遍历向下
  // beginWork 核心职责：
  // - 协调新旧虚拟 DOM，标记变更类型（Placement/Update/Deletion）
  // - 根据 React Element 创建对应的 Fiber 节点
  // - 建立 child/sibling 指针关系，构建 Fiber 树结构
  // - 为当前 Fiber 节点打上副作用标签（effectTag）
  const nextChild = beginWork(workInProgressFiber)
  if (nextChild) return nextChild

  // 归阶段：回溯向上处理
  let currentFiber = workInProgressFiber
  while (currentFiber) {
    // completeWork 核心职责：
    // - 创建或更新 DOM 节点（host component 场景）
    // - 收集副作用到 effectList，构建提交阶段的变更集
    // - 处理 context、ref 等副作用的最终处理
    // - 将子树的 effectList 合并到父节点
    completeWork(currentFiber)
    
    if (currentFiber.sibling) return currentFiber.sibling  // 横向处理兄弟节点
    currentFiber = currentFiber.return  // 纵向回溯到父节点
  }
  
  return null  // 整棵树处理完成
}
```

注：以上代码是示意性的伪代码，使用 requestIdleCallback 只是为了说明“在空闲时继续工作”的思路。React 实际并不依赖 rIC；它通过 Scheduler 包配合 MessageChannel/任务队列等机制实现可中断的协作式调度。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762070381782-9405f09c-5f3f-46a6-ba2e-4cc5c80d1fa4.png)

这样的话把一个大的渲染任务一个个小任务，每个任务只处理一小段 Fiber 节点。

为了实现这些，React 还引入了一个新的工作模型：**双阶段、双树**。

双阶段：

+ **Render 阶段（可中断）**：纯计算阶段，React 会遍历当前的 Fiber 树，在内存中构建一棵“新树”（称为 workInProgress 树），进行 Diff 算法比较，并收集哪些地方需要更新（即“副作用”）。这个阶段是可中断的。
+ **Commit 阶段（不可中断）**：React 会把所有收集到的副作用一次性、同步地应用到真实的 DOM 上，并调用 useLayoutEffect、useEffect 等生命周期钩子。这个阶段是同步且不可中断的，以保证 UI 状态的一致性

双树：

+ 屏幕上显示的是 current 树，更新后，内存中正在构建的是 workInProgress 树。
+ 构建完成，React 会把指针切换，让 workInProgress 树成为新的 current 树。这种“双缓冲”技术，确保了更新过程的平滑。



## 时间切片
有了 Fiber 架构，我们就能把任务拆分了。

但怎么拆、什么时候暂停、什么时候恢复呢？这就是**时间切片**要解决的问题。

它的目标很明确：**不让任何任务独占主线程太久**。

原理：React 有一个自己的调度器（Scheduler）。它会为每个小任务分配一个时间片（通常约 5ms）。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762101237577-2c77b1be-5f00-4688-8971-204962a862ee.png)

当一个任务开始执行，启动一个计时器，任务在时间片内完成，就立即开始下一个小任务。

如果时间片内任务未完成，调度器就会强制中断当前任务，把主线程的控制权交还给浏览器，去处理更高优先级的工作（比如用户输入）。

等到下一帧，浏览器有空闲了，调度器再回来继续执行刚才被中断的任务。



## 并发机制
Fiber 和时间切片是 React 内部的引擎，而并发机制则是暴露给我们开发者的 API。

这里的并发指的是**“React 能够并发地准备多个版本的 UI，并根据优先级智能地选择将哪一个版本呈现给用户”**，核心是可中断、可插队、可回退”。

主要有 startTransition / useTransition：用于标记那些**不紧急**的更新：

```tsx
const [isPending, startTransition] = useTransition()

function onInput(e) {
  const q = e.target.value
  setQuery(q) // 紧急更新：输入框立即响应
  startTransition(() => {
    // 非紧急更新：标记为过渡，React 会智能地调度它
    setList(expensiveFilter(allItems, q))
  })
}
```

`**useDeferredValue**`：用于延迟某个值的“使用”，比如输入框的值要立即显示，但依赖这个值的昂贵计算可以延后：

```tsx
const deferredQuery = useDeferredValue(query)
// 只有当 deferredQuery 变化时，才会重新执行昂贵的过滤操作
const filteredList = useMemo(() => expensiveFilter(items, deferredQuery), [items, deferredQuery])
```

`**Suspense**`：让组件在等待异步操作，不至于让整个页面白屏或卡住：

```tsx
<Suspense fallback={<Spinner />}>
  <Results /> {/* 如果 Results 内部在等待数据，会显示 Spinner */}
</Suspense>
```

你可以把 React 的优先级系统想象成一个**多车道的高速公路**：

+ **紧急车道**：用户输入、点击、拖拽等直接交互。
+ **过渡车道**：UI 的非紧急更新，如搜索过滤、页面切换。
+ **后台车道**：数据获取、预渲染等不直接影响当前交互的任务。

每次更新都会被分配到一条“车道”上。调度器会永远优先处理“紧急车道”上的任务。如果“紧急车道”来车了，正在“过渡车道”上行驶的任务就会被暂停或“插队”。

具体源码来说，调度任务的优先级有这 6 种（其中 NoPriority 为占位，不代表实际的任务优先级）：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762101753782-2f6c1a18-e90e-43a5-b880-70cadad0ecd1.png)

+ **NoPriority**：系统默认值，无实际意义。
+ **Immediate**：响应用户的**离散**操作（如点击、输入），要求**立即反馈**，优先级最高。
+ **UserBlocking**：响应用户的**连续**操作（如滚动、拖拽），要求**及时响应**，但不能阻塞渲染。
+ **Normal**：处理常规的**数据更新**（如接口返回、状态变更）。
+ **Low**：处理**后台任务**（如数据预加载、日志上报）。
+ **Idle**：在**浏览器空闲时**执行的任务，优先级最低。

其实 React 还有个 Lanes 优先级，它是二进制表示不同的优先级，更新任务进来，先会分配 Lanes 优先级，然后最后映射为上面的调度器（Scheduler）优先级。



所以 fiber、时间切片和并发的关系是：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762102498287-8179135a-d61a-4869-973b-7c42c2e24cca.png)



## 从 `setState` 到屏幕
我们串联下整体流程：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762145566738-14cbf313-ff2f-456a-af12-c14b4a4b5738.png)

1. 点击一个按钮触发 `setState`
2. React 为这次更新创建一个“更新对象”，并根据触发源（如点击、输入）给它分配一个优先级
3. 调度器将这个更新任务放入队列。
4. 调度器开始执行 Render 阶段，遍历 Fiber 树，构建 `workInProgress` 树
5. **（并发场景）** 如果此时用户又在输入框里打字，一个更高优先级的更新到来。调度器会暂停当前的渲染任务，转而去处理输入这个高优先级任务
6. 在整个“递”和“归”的过程中，React 会给需要进行 DOM 操作（增、删、改）的 Fiber 节点打上标记
7. 在最终的“提交阶段”，React 需要拿到一个**包含所有待办事项的清单 (Effect List)**，然后一口气执行完



当 React 组件更新时，会重新执行渲染流程。此过程采用深度优先遍历，对 Fiber 树中的每个节点依次执行 `**beginWork**` 和 `**completeWork**`

1. **“递”阶段 (**`**beginWork**`**)**：从根节点向下，处理每个节点
    - 计算最新的 state 与 props
    - **对比新旧状态**：
        * 若发现变化，则执行组件渲染、进行 Diff 算法，并为该 Fiber 节点**标记副作用**（如 `**Update**`, `**Placement**`）
        * 若无变化，则**跳过该节点及其子树的渲染**
2. **“归”阶段 (**`**completeWork**`**)**：在节点处理完所有子节点后，向上返回执行
    - 为**原生 DOM 节点**执行收尾工作，如创建 DOM 实例、收集属性更新
    - 将子树的**副作用标记向上归并**，以便后续阶段能快速定位所有更新



# Vue 的不同路径：精准更新
Vue 的响应式系统实现了**细粒度**的依赖追踪，其精度远超“组件级别”，可以直达模板中的**具体绑定**（如一个文本插值或一个属性）。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762105485498-3e2cc39b-8e0f-4b4c-b21b-43880df108b1.png)

通过依赖收集，记录下模板中哪个“视图片段”使用了哪个“响应式数据”。这个过程通过 Proxy (Vue3) 或 Object.defineProperty (Vue2) 实现。

当一个响应式数据变化时，Vue 不会重新渲染整个组件。它会直接通知并重新执行那些“订阅”了该数据的**更新函数 (effect)**。这些函数只负责更新模板中那一小块依赖该数据的 DOM。

正因为更新如此细，还能通过微任务（nextTick）合并多个更新并批处理，这让大多数应用场景下的更新几乎不会长时间阻塞主线程。

响应式更新流程：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762105665114-3e922b0e-5ee3-4a28-a74f-6cced3284b60.png)

核心就是通过 Proxy 对象进行数据拦截，当数据修改的时候，触发 set 钩子。

根据修改数据的 key 找到所有依赖它的 effect，然后执行 effect  生成新的 VNode。

此时会进行 Diff，但这个 Diff 是很高效的，因为模板编译有大量的优化。

当 Diff 完成就使用渲染器应用真实 DOM 的更新。



而 React 的模型不同，当一个组件的状态发生变化时，React 会**从这个组件开始，向下遍历其子组件树**，进行 Vdom 的 Diff，虽然开发者可以手动通过 `React.memo`、`PureComponent` 或 `shouldComponentUpdate`、`useMemo`、`useCallback` 等 API 手动进行优化，跳过那些没有必要更新的子树，但其核心思想是“通过比对找出差异”。

这就是 React 的核心哲学，函数式的 UI 输出模型：每次渲染都会基于当前 state/props 计算出一版新的 UI 描述（VNode/JSX），再与上一版进行对比以生成最小的 DOM 变更。

但 React 团队也早已意识到了手动优化的心智负担问题，所以开发了 **React Compiler**（以前叫 Forget），它会尝试去分析你的 JavaScript 代码，**推断**出哪些部分是稳定的，自动为你加上 `React.memo`, `useCallback`, `useMemo`。

所以这两个框架最根本的更新粒度是不一样的：React 是组件级别（Fiber 调度），Vue 则是细粒度的响应式数据依赖。



Vue3 响应式系统精简实现：

```javascript
// --- 全局变量和数据结构 ---
let activeEffect
const effectStack = []
const bucket = new WeakMap()

// 任务队列，用 Set 自动去重
const jobQueue = new Set()
// 一个标志位，防止重复刷新
let isFlushing = false

// --- 核心函数 ---
function reactive(obj) {
  return new Proxy(obj, {
    get(target, key) {
      track(target, key)
      return target[key]
    },
    set(target, key, value) {
      target[key] = value
      trigger(target, key) // set 时触发 trigger
      return true
    },
  })
}

function track(target, key) {
  if (!activeEffect) return
  let depsMap = bucket.get(target)
  if (!depsMap) {
    bucket.set(target, (depsMap = new Map()))
  }
  let deps = depsMap.get(key)
  if (!deps) {
    depsMap.set(key, (deps = new Set()))
  }
  deps.add(activeEffect)
  activeEffect.deps.push(deps)
}

function trigger(target, key) {
  const depsMap = bucket.get(target)
  if (!depsMap) return
  const effects = depsMap.get(key)
  if (!effects) return

  const effectsToRun = new Set()
  effects.forEach((effectFn) => {
    // 避免无限递归
    if (effectFn !== activeEffect) {
      effectsToRun.add(effectFn)
    }
  })

  effectsToRun.forEach((effectFn) => {
    // 如果用户提供了自定义调度器，则优先使用
    if (effectFn.options.scheduler) {
      effectFn.options.scheduler(effectFn)
    } else {
      // 否则，使用我们默认的基于微任务的调度逻辑
      // 将副作用函数添加到任务队列
      jobQueue.add(effectFn)
      // 安排刷新任务
      flushJob()
    }
  })
}

/**
 * 新增：刷新任务队列的函数
 */
function flushJob() {
  // 如果正在刷新，则什么也不做
  if (isFlushing) return
  isFlushing = true

  // 使用 Promise.resolve() 创建一个微任务，在微任务中刷新队列
  Promise.resolve()
    .then(() => {
      // 遍历并执行队列中的所有任务
      jobQueue.forEach((job) => job())
    })
    .finally(() => {
      // 刷新完毕后，重置标志位并清空队列
      isFlushing = false
      jobQueue.clear()
    })
}

function effect(fn, options = {}) {
  const effectFn = () => {
    cleanup(effectFn)
    activeEffect = effectFn
    effectStack.push(effectFn)
    fn()
    effectStack.pop()
    activeEffect = effectStack[effectStack.length - 1]
  }
  effectFn.options = options
  effectFn.deps = []
  effectFn()
}

function cleanup(effectFn) {
  for (let i = 0; i < effectFn.deps.length; i++) {
    const deps = effectFn.deps[i]
    deps.delete(effectFn)
  }
  effectFn.deps.length = 0
}
```

依赖收集后的数据结构：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762106773933-a886073a-4d94-4543-906b-c96e5374e49d.png)

WeakMap 的键是原始对象 target，值是一个 Map 实例。

而 Map 的键是原始对象 target 的 key，Map 的值是一个 由副作用函数组成的 Set。

这里的 effect 是绝对的核心：

1. **首次执行**：effect 函数运行时，自动“记住”它用到的所有响应式数据（依赖收集）。
2. **数据变化**：当这些数据变化时，effect 会自动重新运行。

实现了 **“数据驱动”** 的自动化—— 数据变，相关逻辑自动更新。



响应式具体使用示例：

```javascript
console.log('--- 1. 基本用法 ---')
// a. 创建一个原始对象
const data = { text: 'Hello', count: 0 }
// b. 将其变为响应式对象
const obj = reactive(data)

// c. 使用 effect 注册一个副作用函数，它会依赖 obj.text
effect(() => {
  console.log('Effect 1 (text) is running:', obj.text)
})

// d. 修改响应式对象的属性，这会触发上面的 effect 重新执行
console.log('修改 obj.text...')
obj.text = 'Hello, World!'

console.log('\n--- 2. 异步批量更新 ---')
// a. 注册一个依赖于 obj.count 的 effect
effect(() => {
  console.log('Effect 2 (count) is running:', obj.count)
})

// b. 在同一个事件循环中多次修改 obj.count
console.log('连续两次增加 count...')
obj.count++
obj.count++
console.log('同步代码执行完毕，更新将在微任务中执行。')

setTimeout(() => {
  console.log('\n--- 3. 自定义调度器 (scheduler) ---')
  // a. 创建一个响应式对象
  const data3 = { value: 1 }
  const obj3 = reactive(data3)

  // b. 注册一个带有 scheduler 的 effect
  effect(
    () => {
      console.log('Effect 3 (scheduler) is running:', obj3.value)
    },
    {
      // 当依赖变化时，不会直接执行副作用函数，而是执行这个 scheduler
      scheduler(fn) {
        console.log('Scheduler is called!')
        // 我们可以决定何时以及如何执行原始的副作用函数 (fn)
        // 例如，我们可以在 1 秒后执行它
        setTimeout(fn, 1000)
      },
    }
  )

  // c. 修改数据
  console.log('修改 obj3.value...')
  obj3.value++
  console.log('同步代码执行完毕，等待 scheduler...')
  // 预期：会先打印 'Scheduler is called!'，然后大约 1 秒后打印 'Effect 3 (scheduler) is running: 2'
}, 200)
```



### 编译时优化
Vue 的编译器在将模板（template）编译成渲染函数（render function）的过程中，会进行大量的静态分析，为运行时的更新过程提供关键的优化信息。

主要有：

+ **静态内容提升**：编译器识别出模板中永远不会改变的部分（静态节点），并将其提升到渲染函数之外，后续更新时完全跳过这些节点。
+ **更新类型标记**：编译器为动态节点打上“标记”（Patch Flag），例如：`1` 代表只有文本会变（TEXT）、`2` 代表只有 `class` 会变（CLASS）、`8` 代表仅存在非 `class`/`style` 的动态属性（PROPS），从而让运行时只比对必要的部分，避免全量树比对。
+ **事件处理缓存**：编译器自动缓存内联事件处理器，避免每次渲染时都创建新的函数实例，优化内存占用和更新性能。



Vue SFC Playground 地址：[https://play.vuejs.org/](https://play.vuejs.org/)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762107646725-afae19db-2109-4e73-91da-96a3de8c1878.png)

```javascript
const _hoisted_1 = { class: "container" }
```

**静态内容提升 (**`**_hoisted_1**`**)**：编译器发现 `<div>` 的 `class` 是一个静态对象，所以把它提升到了 `render` 函数外面。在 `render` 函数里就能复用。

```javascript
_createElementVNode("span", null, _toDisplayString($setup.message), 1 /* TEXT */)
```

**更新类型标记 (**`**Patch Flag**`**)**：`1 /* TEXT */` 标记告诉 Vue：“这个节点只有文本会变，Diff 的时候就不用那么费劲对比了，直接更新文本就行。

```javascript
_createElementVNode("button", {
  onClick: _cache[0] || (_cache[0] = () => $setup.message.value++)
}, "Click me (Inline)")
```

**事件处理缓存**：**第一次渲染** `_cache[0]` 为空，创建新函数并存入。**后续渲染**直接复用 `_cache[0]` 里的函数，不再重复创建。

这些优化由 Vue 的编译器提供，使得 Vue 的 VDom Diff 过程快很多。



我们继续来看看 React JSX “真面目”，**访问地址**：[https://babeljs.io/repl](https://babeljs.io/repl)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762107874038-46d47ffb-d651-4395-8ac6-d8010b2ba0ab.png)

+ `className: "container"` 每次渲染，都会创建一个新的 `{ className: "container" }` 对象字面量。
+ `_jsx("span", { children: message })` 没有标记，React diff 时需要比对。
+ `onClick: () => setMessage('Clicked!')` 每次渲染，都会创建一个全新的箭头函数。

本质还是因为 JSX，它本质上是 `JavaScript`。这意味着在 JSX 的花括号 `{}` 里，你可以放**任何合法的 JavaScript 表达式**。太灵活了，所以优化起来很困难。

而 Vue 的 `template` 只是一套受限的、声明式的 DSL（领域特定语言）。



## 历史佐证：Vue 对时间切片的探索
Vue 的开发团队确实曾经尝试并实现过时间切片功能。

[https://github.com/vuejs/rfcs/issues/89#issuecomment-546988615](https://github.com/vuejs/rfcs/issues/89#issuecomment-546988615)  
然而，在经过内部测试和权衡后，这个实验性的功能最终被移除了。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762108121027-bfcafec4-3d51-4a3c-a2ba-b43818e419d7.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1762108136920-69a844af-82f2-4fcd-b89a-c139f16ec119.png)

尤雨溪的核心意思是 **React 为解决其固有的性能瓶颈（由运行时和 VDOM 机制导致的过度更新）引入了复杂的时间分片方案，但这带来了新的开销；而 Vue 通过更精细的编译时优化和响应式追踪，从根本上避免了这类瓶颈，因此无需引入类似的复杂机制。**

**说白了移除的原因也就是收益跟成本完全不匹配。**

****

**最后总结个表格：**

| 特性 | React (并发模式) | Vue 3 |
| --- | --- | --- |
| **核心哲学** | **调度 (Scheduling)**：接受更新可能很慢，通过智能调度保障流畅性。 | **精准 (Precision)**：从源头减少计算量，让每次更新都足够快。 |
| **工作单元** | Fiber 节点（组件级） | 组件 / Effect |
| **更新机制** | 自上而下的 Diff (Reconciliation) | 细粒度的依赖追踪 |
| **中断能力** | **可中断/可恢复** | **非中断式（任务粒度小，无需中断）** |
| **优化手段** | 运行时调度（时间切片、优先级） | 编译时优化（静态提升、Patch Flags）+ 响应式系统 |
| **解决的问题** | 极端复杂或低性能设备下的 UI 响应性问题。 | 大多数场景下的高效更新，避免不必要的计算。 |
| **开发者心智** | 需要理解 startTransition 等并发 API 来处理低优任务。 | 响应式系统自动优化，心智负担较低。 |
