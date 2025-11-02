# React 更新
首先我们看下 React 的渲染更新流程：
![[Pasted image 20251019135650.png]]
当我们 setState 的时候，React 会根据新状态生成虚拟 DOM，然后与旧虚拟 DOM 对比（diff）。根据差异更新需要改变的视图。
而 React 时间切片和 Fiber 技术就是为了解决这个 diff 时间过长，导致主线程长时间被占用，引发的页面卡顿的问题。

### React 16 之前的更新路径

在 React 16 之前，当组件 setState 或 props 改变触发更新时，React 会从根组件开始，递归不可中断地对比每个组件的新旧虚拟 DOM。
```js
function reconcile(parent) {
  for (child of parent.children) {
    reconcile(child); // 递归
  }
}
```
比如下面组件树：
```
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
此时，Fiber 闪亮登场。
![[Pasted image 20251019162130.png]]
为了解决这些问题，React 团队在 React 16 中引入了 **Fiber 架构**。

### Fiber 架构
为了解决上述问题，React 团队重写了整个核心协调算法，引入了 Fiber 架构。
![[Pasted image 20251019162915.png]]
Fiber 本质上就是一个 JS 对象，不过这个对象是**链表**的结构：
```js
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
![[Pasted image 20251026204926.png|300]]
React 会使用这些 Fiber 对象构建一棵可中断、可恢复的“Fiber 树”，用**循环 + 指针移动**来遍历：
```js
let current = root;
while (current) {
  // 处理当前 Fiber 节点
  // ...
  // 决定下一步去哪：子节点 → 兄弟节点 → 父节点回溯
  if (current.child) {
    current = current.child;
  } else {
    while (current && !current.sibling) {
      current = current.return; // 回溯
    }
    current = current?.sibling;
  }
}
```
这种遍历可以在任意节点暂停，记录当前 `current` 指针位置，稍后再从该位置**恢复**。
把庞大的渲染任务拆分成一个个小任务，每个任务只处理一小段 Fiber 节点。
![[Pasted image 20251009025806.png]]
为了实现这些，React 引入了一个新的工作模型：**双阶段、双树**。
- **Render 阶段（可中断）**：这个阶段是“纯计算”。React 会遍历当前的 Fiber 树，在内存中构建一棵“新树”（称为 `workInProgress` 树），进行 diff 算法比较，并收集哪些地方需要更新（即“副作用”）。这个阶段是可中断的。
- **Commit 阶段（不可中断）**：一旦 `workInProgress` 树构建完成，就进入 Commit 阶段。React 会把所有收集到的副作用一次性、同步地应用到真实的 DOM 上，并调用 `useLayoutEffect`、`useEffect` 等生命周期钩子。这个阶段通常很快，所以必须是同步且不可中断的，以保证 UI 状态的一致性。
- **双树**：屏幕上显示的是 `current` 树，内存中正在构建的是 `workInProgress` 树。当 `workInProgress` 树提交后，React 会把指针切换，让 `workInProgress` 树成为新的 `current` 树。这种“双缓冲”技术，确保了更新过程的平滑。

### 时间切片
有了 Fiber 架构，我们就能把任务拆分了。但怎么拆、什么时候暂停、什么时候恢复呢？这就是**时间切片**要解决的问题。
它的目标很明确：**不让任何任务独占主线程太久**。
**原理**：React 有一个自己的调度器（Scheduler）。它会为每个小任务分配一个时间片（通常约 5ms）。
![[Pasted image 20251009025432.png]]
当一个任务开始执行，启动一个计时器，任务在时间片内完成，就立即开始下一个小任务。
如果时间片内任务未完成，调度器就会强制中断当前任务，把主线程的控制权交还给浏览器，去处理更高优先级的工作（比如用户输入）。
等到下一帧，浏览器有空闲了，调度器再回来继续执行刚才被中断的任务。

注：时间切片在 React 16/17 时期属于实验性的并发渲染能力（非默认），在 React 18 并发特性稳定后才广泛启用；理解这一点有助于正确把握不同版本的行为差异。

### 并发机制
Fiber 和时间切片是 React 内部的引擎，而**并发机制**则是暴露给我们开发者的 API。
注意 React 的“并发”不是指 CPU 的并行计算，而是指 **“React 能够并发地准备多个版本的 UI，并根据优先级智能地选择将哪一个版本呈现给用户”**。它的核心是“可中断、可插队、可回退”。
**主要的 API 和能力：**
**`startTransition` / `useTransition`**：用于标记那些**不紧急**的更新。
- **场景**：想象一个搜索框。用户输入时，输入框本身的值需要**立即**更新（紧急），但根据输入内容过滤一个上万条的列表，这个操作可以**稍后**进行（非紧急）。
- **用法**：
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
**`useDeferredValue`**：用于延迟某个值的“使用”。
- **场景**：输入框的值要立即显示，但依赖这个值的昂贵计算可以延后。
- **用法**：
```tsx
const deferredQuery = useDeferredValue(query)
// 只有当 deferredQuery 变化时，才会重新执行昂贵的过滤操作
const filteredList = useMemo(() => expensiveFilter(items, deferredQuery), [items, deferredQuery])
```
**`Suspense`**：让组件在等待异步操作（如数据请求、代码分割）时，不至于让整个页面白屏或卡住。
- **场景**：切换路由时，新页面的组件和数据需要加载。
- **用法**：
```tsx
<Suspense fallback={<Spinner />}>
  <Results /> {/* 如果 Results 内部在等待数据，会显示 Spinner */}
</Suspense>
```
你可以把 React 的优先级系统想象成一个**多车道的高速公路**：
- **紧急车道**：用户输入、点击、拖拽等直接交互。
- **过渡车道**：UI 的非紧急更新，如搜索过滤、页面切换。
- **后台车道**：数据获取、预渲染等不直接影响当前交互的任务。
每次更新都会被分配到一条“车道”上。调度器会永远优先处理“紧急车道”上的任务。如果“紧急车道”来车了，正在“过渡车道”上行驶的任务就会被暂停或“插队”。
具体源码来说，调度任务的优先级有这 6 种（其中 NoPriority 为占位，不代表实际的任务优先级）：
![[Pasted image 20251009023523.png|400]]
- **NoPriority**：代表“无优先级”，它**不属于任何实际的任务优先级**。它主要作为系统的初始值或一个特殊的占位符。
- **Immediate**: 对应离散的用户行为，如 click, keydown, input。这些操作用户期望立即得到反馈，因此优先级最高。
- **UserBlocking**: 对应连续的用户行为，如 scroll, drag, mouseover。这些操作会频繁触发，如果每次都以最高优先级执行，可能会阻塞渲染，但它们也需要及时响应，否则用户会感到卡顿。所以它的优先级仅次于 Immediate。
- **NormalPriority**：网络请求返回后的数据更新、非关键的 setState。比如，页面加载后，通过 useEffect 获取文章列表并更新到界面上。
- **LowPriority**：数据预取（比如预加载下一页的数据）、分析和日志上报等。
- **Idle**: 最低优先级，用于执行那些完全可以在浏览器空闲时才做的任务。

React 18+ 内部使用 lanes 表示更新优先级（如 Sync、InputDiscrete、InputContinuous、Default、Transition、Idle 等），Scheduler 的 Immediate/UserBlocking/Normal/Low/Idle 仍存在，但主要用于宿主调度层面。

所以 fiber、时间切片和并发的关系是：
![[Pasted image 20251009104248.png]]

### 从 `setState` 到屏幕
我们串联下整体流程：
![[Pasted image 20251010193006.png]]
1. 你点击一个按钮，触发 `setState`。
2. React 为这次更新创建一个“更新对象”，并根据触发源（如点击、输入）给它分配一个优先级
3. 调度器将这个更新任务放入队列。
4. 调度器开始执行 Render 阶段，遍历 Fiber 树，构建 `workInProgress` 树。
5. **（并发场景）** 如果此时用户又在输入框里打字，一个更高优先级的更新到来。调度器会暂停当前的渲染任务，转而去处理输入这个高优先级任务。
6. 当某个渲染任务完成后，进入 Commit 阶段，将变更同步应用到 DOM。
7. **（Suspense 场景）** 如果在渲染中发现某个组件需要的数据还没准备好，React 会抛出一个 Promise。`Suspense` 组件会捕获它，并显示 `fallback` UI，同时 React 会记住这个位置。等数据到了，React 会重新从这里开始渲染。

更新的话，重新执行 render 函数：
- 遍历 Fiber 树，对每个节点执行 `beginWork`。
    - 处理节点的 `updateQueue`，计算出最新 `state`。
    - 对比新旧 `state`/`props`：
        - **有变化**：执行组件渲染，进行 Diff，标记副作用（`effectTag`）。
        - **无变化**：跳过该组件及其子树的渲染。

# 2. Vue 的不同路径：精准更新
### 2.1 细粒度的响应式系统和高效的异步更新队列
Vue 的响应式系统实现了**细粒度**的依赖追踪，其精度远超“组件级别”，可以直达模板中的**具体绑定**（如一个文本插值或一个属性）。
![[Pasted image 20251008211240.png]]
- **依赖收集：** 在组件首次渲染时，Vue 会像一个侦探，记录下模板中哪个“视图片段”使用了哪个“响应式数据”。这个过程通过 Proxy (Vue 3) 或 Object.defineProperty (Vue 2) 实现。
- **精准更新：** 当一个响应式数据变化时，Vue 不会重新渲染整个组件。它会直接通知并重新执行那些“订阅”了该数据的**更新函数 (effect)**。这些函数只负责更新模板中那一小块依赖该数据的 DOM。

正因为更新任务从一开始就被拆分得足够细、且精确指向实际受影响的绑定，单次更新的执行成本通常很低。Vue 在同一事件循环中通过微任务（nextTick）合并多个更新并批处理，这让大多数应用场景下的更新几乎不会长时间阻塞主线程，从而对“时间切片”这类复杂调度的需求显著降低。
但这并不意味着 Vue 永远不会阻塞。如果副作用函数里包含大量同步计算、或一次性触发了巨量 DOM 变更，仍可能造成卡顿。此类场景应该考虑将重计算移到 Web Worker、按需拆分任务、或分块渲染以降低一次性工作量。
vue2 响应式更新流程：
![[Pasted image 20251010193028.png]]
vue3 响应式更新流程：
![[Pasted image 20251010193034.png]]
而 React 的模型不同，当一个组件的状态发生变化时，React 会**从这个组件开始，向下遍历其子组件树**，进行新旧 Virtual DOM 的对比（这个过程称为 Reconciliation）。虽然开发者可以手动通过 `React.memo`、`PureComponent` 或 `shouldComponentUpdate`、`useMemo`、`useCallback` 等 API 手动进行优化，跳过那些没有必要更新的子树，但其核心思想是“通过比对找出差异”。
这就像你只知道城里某个街区（触发更新的组件）有情况，但需要把这个街区挨家挨户盘问一遍才能确定具体问题。如果这个街区很大（组件树很深或很宽），盘问过程依然会很耗时。更准确地说，React 进行虚拟 DOM 的 diff，并不是因为“不可变状态导致不知道哪个属性变了”。React 的核心是函数式的 UI 输出模型：每次渲染都会基于当前 state/props 计算出一版新的 UI 描述（VNode/JSX），再与上一版进行对比以生成最小的 DOM 变更。不可变数据在工程实践中有助于优化（例如便于 memo、避免意外共享和突变），但并不是 React 需要 diff 的根本原因。即便使用可变对象，只要触发 setState，React 仍会重新计算输出并进行 diff。
最根本的更新粒度是不一样的，React 是组件级别（Fiber 调度），Vue 则是细粒度的响应式数据依赖。
```js
// --- 全局变量和数据结构 ---
let activeEffect;
const effectStack = [];
const bucket = new WeakMap();

// 任务队列，用 Set 自动去重
const jobQueue = new Set();
// 一个标志位，防止重复刷新
let isFlushing = false;

// --- 核心函数 ---
function reactive(obj) {
  return new Proxy(obj, {
    get(target, key) {
      track(target, key);
      return target[key];
    },
    set(target, key, value) {
      target[key] = value;
      trigger(target, key); // set 时触发 trigger
      return true;
    }
  });
}

function track(target, key) {
  if (!activeEffect) return;
  let depsMap = bucket.get(target);
  if (!depsMap) {
    bucket.set(target, (depsMap = new Map()));
  }
  let deps = depsMap.get(key);
  if (!deps) {
    depsMap.set(key, (deps = new Set()));
  }
  deps.add(activeEffect);
  activeEffect.deps.push(deps);
}

function trigger(target, key) {
  const depsMap = bucket.get(target);
  if (!depsMap) return;
  const effects = depsMap.get(key);
  if (!effects) return;

  const effectsToRun = new Set();
  effects.forEach(effectFn => {
    // 避免无限递归
    if (effectFn !== activeEffect) {
      effectsToRun.add(effectFn);
    }
  });

  effectsToRun.forEach(effectFn => {
    // 如果用户提供了自定义调度器，则优先使用
    if (effectFn.options.scheduler) {
      effectFn.options.scheduler(effectFn);
    } else {
      // 否则，使用我们默认的基于微任务的调度逻辑
      // 将副作用函数添加到任务队列
      jobQueue.add(effectFn);
      // 安排刷新任务
      flushJob();
    }
  });
}

/**
 * 新增：刷新任务队列的函数
 */
function flushJob() {
  // 如果正在刷新，则什么也不做
  if (isFlushing) return;
  isFlushing = true;

  // 使用 Promise.resolve() 创建一个微任务，在微任务中刷新队列
  Promise.resolve()
    .then(() => {
      // 遍历并执行队列中的所有任务
      jobQueue.forEach(job => job());
    })
    .finally(() => {
      // 刷新完毕后，重置标志位并清空队列
      isFlushing = false;
      jobQueue.clear();
    });
}

function effect(fn, options = {}) {
  const effectFn = () => {
    cleanup(effectFn);
    activeEffect = effectFn;
    effectStack.push(effectFn);
    fn();
    effectStack.pop();
    activeEffect = effectStack[effectStack.length - 1];
  };
  effectFn.options = options;
  effectFn.deps = [];
  effectFn();
}

function cleanup(effectFn) {
  for (let i = 0; i < effectFn.deps.length; i++) {
    const deps = effectFn.deps[i];
    deps.delete(effectFn);
  }
  effectFn.deps.length = 0;
}
```
Vue 3 的依赖收集后的数据结构如下：
![[Pasted image 20251008085841.png]]
WeakMap 的键是原始对象 target，值是一个 Map 实例，而 Map 的键是原始对象 target 的 key，Map 的值是一个 由副作用函数组成的 Set。
这里面 effect 很有意思：
- 当一个 effect 函数首次执行时，它会“订阅”它在执行过程中访问过的所有响应式数据。这个过程就是**依赖收集。**
- 当被它订阅的响应式数据发生变化时，这个 effect 会被调度并**自动重新执行**。这确保了所有依赖该数据的逻辑（如视图渲染、计算属性等）都能得到及时的更新。
effect 的根本作用是在“数据”（因）和“副作用”（果）之间建立一座**自动化的桥梁**。“副作用”在这里是广义的，可以指更新 DOM（组件渲染）、执行一段逻辑（watchEffect）、或重新计算一个值（computed）。
```js
console.log("--- 1. 基本用法 ---");
// a. 创建一个原始对象
const data = { text: 'Hello', count: 0 };
// b. 将其变为响应式对象
const obj = reactive(data);

// c. 使用 effect 注册一个副作用函数，它会依赖 obj.text
effect(() => {
  console.log('Effect 1 (text) is running:', obj.text);
});

// d. 修改响应式对象的属性，这会触发上面的 effect 重新执行
console.log('修改 obj.text...');
obj.text = 'Hello, World!';


console.log("\n--- 2. 异步批量更新 ---");
// a. 注册一个依赖于 obj.count 的 effect
effect(() => {
  console.log('Effect 2 (count) is running:', obj.count);
});

// b. 在同一个事件循环中多次修改 obj.count
console.log('连续两次增加 count...');
obj.count++;
obj.count++;
console.log('同步代码执行完毕，更新将在微任务中执行。');


setTimeout(() => {
  console.log("\n--- 3. 自定义调度器 (scheduler) ---");
  // a. 创建一个响应式对象
  const data3 = { value: 1 };
  const obj3 = reactive(data3);

  // b. 注册一个带有 scheduler 的 effect
  effect(() => {
    console.log('Effect 3 (scheduler) is running:', obj3.value);
  }, {
    // 当依赖变化时，不会直接执行副作用函数，而是执行这个 scheduler
    scheduler(fn) {
      console.log('Scheduler is called!');
      // 我们可以决定何时以及如何执行原始的副作用函数 (fn)
      // 例如，我们可以在 1 秒后执行它
      setTimeout(fn, 1000);
    }
  });

  // c. 修改数据
  console.log('修改 obj3.value...');
  obj3.value++;
  console.log('同步代码执行完毕，等待 scheduler...');
  // 预期：会先打印 'Scheduler is called!'，然后大约 1 秒后打印 'Effect 3 (scheduler) is running: 2'
}, 200);
```

### 2.2 编译时优化
Vue 是少数将编译时优化作为核心性能策略的主流框架之一。
Vue的编译器在将模板（template）编译成渲染函数（render function）的过程中，会进行大量的静态分析，为运行时的更新过程提供关键的优化信息。
主要有：
- **静态内容提升**：编译器识别出模板中永远不会改变的部分（静态节点），并将其提升到渲染函数之外，后续更新时完全跳过这些节点。
- **更新类型标记**：编译器为动态节点打上“标记”（Patch Flag），例如：`1` 代表只有文本会变（TEXT）、`2` 代表只有 `class` 会变（CLASS）、`8` 代表仅存在非 `class`/`style` 的动态属性（PROPS），从而让运行时只比对必要的部分，避免全量树比对。
- **事件处理缓存**：编译器自动缓存内联事件处理器，避免每次渲染时都创建新的函数实例，优化内存占用和更新性能。
Vue SFC Playground 地址：[https://play.vuejs.org/](https://play.vuejs.org/)
![[Pasted image 20251008103730.png]]
```javascript
const _hoisted_1 = { class: "container" }
```
**静态内容提升 (`_hoisted_1`)**：编译器发现 `<div>` 的 `class` 是一个静态对象，所以把它提升到了 `render` 函数外面。在 `render` 函数里，直接复用 `_hoisted_1`，避免了每次都创建一个新对象 `{ class: "container" }`，很细节。
```js
_createElementVNode("span", null, _toDisplayString($setup.message), 1 /* TEXT */)
```
**更新类型标记 (`Patch Flag`)**：`1 /* TEXT */` 标记告诉 Vue：“这个节点只有文本会变，diff 的时候别费劲比对了，直接更新文本就行。
```js
_createElementVNode("button", {
  onClick: _cache[0] || (_cache[0] = () => $setup.message.value++)
}, "Click me (Inline)")
```
**事件处理缓存**：利用了 JavaScript 的“短路求值”。
- **第一次渲染**：`_cache[0]` 为空，创建新函数并存入。
- **后续渲染**：直接复用 `_cache[0]` 里的函数，不再重复创建。

这些由编译器提供的优化，使得 Vue 的虚拟 DOM 更新过程比传统的手动优化或纯运行时的虚拟 DOM diff 要快得多。这进一步巩固了 Vue 的性能优势，使得单次更新任务的执行时间被压缩到极短，从而降低了对时间切片这种复杂调度策略的需求。
我们继续来看看 React JSX “真面目”：
**访问地址**：[https://babeljs.io/repl](https://babeljs.io/repl)
![[Pasted image 20251008093928.png]]
- `className: "container"`  每次渲染，都会创建一个新的 `{ className: "container" }` 对象字面量。
- `_jsx("span", { children: message })`  没有标记，React diff 时需要比对。
- `onClick: () => setMessage('Clicked!')`  每次渲染，都会创建一个全新的箭头函数！

这就是为什么你需要 `React.memo`、`useCallback` 和 `useMemo` 这些“手动工具箱”的原因。
Vue 的 `template` 是一套受限的、声明式的 DSL（领域特定语言）。
而 JSX 本质上是 `JavaScript`。这意味着在 JSX 的花括号 `{}` 里，你可以放**任何合法的 JavaScript 表达式**。
其实 React 团队也早已意识到了手动优化的心智负担问题，所以开发了 **React Compiler**（以前叫 Forget），它会尝试去分析你的 JavaScript 代码，**推断**出哪些部分是稳定的，自动为你加上 `React.memo`, `useCallback`, `useMemo`。但目前生产默认仍以运行时 diff 为主。
**Svelte** 采取了更激进的编译策略：它既用类似模板的语法（但比 Vue 更接近 JS），又在编译时生成极致优化的命令式代码。它证明了“编译时框架”可以做到比 Vue 更彻底的优化，但代价是**运行时更薄、编译器更重、生态更封闭**。
React 选择了一条更通用、更兼容现有 JS 生态的路，所以它的编译优化注定是“渐进式”的。

## 3. 历史佐证：Vue 对时间切片的探索
Vue 的开发团队确实曾经尝试并实现过时间切片功能。
https://github.com/vuejs/rfcs/issues/89#issuecomment-546988615
然而，在经过内部测试和权衡后，这个实验性的功能最终被移除了。
![[Pasted image 20251005110949.png]]
![[Pasted image 20251005111012.png]]
尤雨溪核心意思是：**React 推崇的“时间切片”技术，主要是为了解决其自身架构设计所导致的“CPU 密集型卡顿”问题，而 Vue 则通过更底层的架构优化，从根源上避免了这类问题，使得时间切片在 Vue 中显得既不必要，反而会增加复杂度和包体积。**
有几个有意思的点：
1. “卡顿”的本质是**高负载的 CPU 计算**（处理大量数据、执行复杂的 JavaScript 逻辑。）和**同步的 DOM 更新**（浏览器需要根据计算结果，一次性、同步地更新页面元素）。这两者加在一起，如果总耗时超过了浏览器一帧的渲染时间（大约 16.67 ms），用户就会感觉到卡顿。
2. “时间切片”、只优化了 **CPU 计算部分**，对于 DOM 更新那部分，它无能为力。因为 DOM 必须同步更新才能保证页面的最终状态是正确一致的，不能被切片。
3. React 更新**更容易花费超过 100 毫秒的纯 CPU 时间**。
4. Vue 通过**更简单的 VDOM**、**编译时优化（AOT）**、**智能的响应式更新**从源头避免了过度消耗。
5. 时间切片本身还会导致**框架复杂度飙升**，**包体积增大**。


## 结论
- **React 的并发机制**：其核心是“**调度**”。它接受了“更新可能是慢的”这一事实，因此构建了以 Fiber 为基础的复杂调度系统，为“慢”任务提供一种不阻塞主线程的执行方式，保障用户交互的优先响应。
- **Vue 的响应式系统**：其核心是“**精准**”。它通过细粒度的依赖追踪和编译时优化，从源头上极大地减少了不必要的更新和计算量，努力让每一次任务都“足够快”，以至于在绝大多数场景下都不需要中断与恢复的复杂调度。

|           |                                           |                                        |
| --------- | ----------------------------------------- | -------------------------------------- |
| 特性        | React (并发模式)                              | Vue 3                                  |
| **核心哲学**  | **调度 (Scheduling)**：接受更新可能很慢，通过智能调度保障流畅性。 | **精准 (Precision)**：从源头减少计算量，让每次更新都足够快。 |
| **工作单元**  | Fiber 节点（组件级）                             | 组件 / Effect                            |
| **更新机制**  | 自上而下的 Diff (Reconciliation)               | 细粒度的依赖追踪                               |
| **中断能力**  | **可中断/可恢复**                               | **非中断式（任务粒度小，无需中断）**                   |
| **优化手段**  | 运行时调度（时间切片、优先级）                           | 编译时优化（静态提升、Patch Flags）+ 响应式系统         |
| **解决的问题** | 极端复杂或低性能设备下的 UI 响应性问题。                    | 大多数场景下的高效更新，避免不必要的计算。                  |
| **开发者心智** | 需要理解 startTransition 等并发 API 来处理低优任务。     | 响应式系统自动优化，心智负担较低。                      |
