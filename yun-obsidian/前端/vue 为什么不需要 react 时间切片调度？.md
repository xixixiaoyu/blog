## 1. React 时间切片、fiber、并发机制关系？
![[Pasted image 20251009104248.png]]
简单而言：Fiber 是“可打断的链表组件”，时间切片是“让出主线程的调度策略”，并发机制是“把这两者组合起来，让 React 在渲染中途还能响应高优任务”。

### 1.1 Fiber：可中断的基础设施
在 React 16 之前，React 的更新是“一口气做完”的。当状态变化时，React 会递归遍历整个组件树，进行 diff 算法，然后一次性更新 DOM。
这个过程是同步且不可中断的。如果组件树很庞大，这个递归过程就会耗时很长，浏览器主线程被完全占用，用户的所有交互（点击、输入）都会被卡住，直到渲染完成。
```jsx
// 这是一个典型的“卡顿”制造者
class ComplexComponent extends React.Component {
  state = {
    // 假设这是一个包含上千个项目的列表
    items: generateLargeList(),
    filterText: '',
  };

  // 用户的每一次输入，都会触发一次可能非常耗时的全列表重新渲染
  handleFilter = (e) => {
    this.setState({ filterText: e.target.value });
  };

  render() {
    const filteredItems = this.state.items.filter(
      item => item.text.includes(this.state.filterText)
    );

    return (
      <div>
        <input onChange={this.handleFilter} />
        {/* 渲染一个非常长的列表，这会导致 render 本身非常耗时 */}
        <ul>
          {filteredItems.map(item => <li key={item.id}>{item.text}</li>)}
        </ul>
      </div>
    );
  }
}
```
```
时间轴 ------------------------------------------------>
帧 1: |---- JS (React 更新，耗时 100ms) ----|
帧 2: |---------------------------------------|
帧 3: |---------------------------------------|
...
帧 6: |---------------------------------------|
帧 7: |---- (React 更新结束) ----| 处理用户点击 | 绘制 |
```
为了让画面流畅，浏览器需要以每秒 60 帧的速度刷新，意味着每一帧的预算时间只有大约 16.67 毫秒。
但上面这个 React 更新可能直接就霸占了 5-6 帧的时间，用户能感觉到的就是明显的掉帧和阻塞。
![[Pasted image 20251009020845.png]]
React 更新视图的原理：通过 setState 改变数据从而触发虚拟 DOM 去进行对比，对比结束后将再进行 DOM 更新。那么更新就会分成两部分：
- 数据更新，触发虚拟 DOM 比较
- 比较完成后更新真实 DOM 节点

当对比少的节点时使用这种方法时比较合理的，但是当我们一次更新有几百个甚至更多组件需要进行对比时，由于 Diff 是一个**同步**的方法，在进行对比时，由于 JS 单线程的原因，导致其他的事件都**无法响应**。

**Fiber 的诞生，就是为了打破这种“一口气做完”的模式。**
Fiber 本质上是一个 JavaScript 对象，**是一个为可中断渲染而设计的链表化数据结构，它将 React 元素树上的每一个节点都封装成一个独立的工作单元。**
更重要的是，它通过 child、sibling、return 指针，将传统的树形结构“链表化”。
这使得 React 可以**不再使用无法中断的递归方式来遍历组件树，而是改成一个可以随时暂停和恢复的循环迭代**。
你可以在处理完任何一个 Fiber 节点后，记录下当前的位置，然后随时把主线程交还给浏览器。
```js
// 一个极度简化的 Fiber 节点结构
const fiberNode = {
  // 组件类型，比如 'div' 或一个函数组件
  type: 'div',
  // 组件实例，如类组件实例或 DOM 节点
  stateNode: null,
  // 指向第一个子 Fiber 节点
  child: null,
  // 指向下一个兄弟 Fiber 节点
  sibling: null,
  // 指向父 Fiber 节点
  return: null,
  // ... 其他包含 props、state、副作用（即需要做的更新）等信息
};
```
![[Pasted image 20251009021142.png]]
链表结构是可以随时暂停和恢复的。
React 不再需要用无法中断的递归去遍历树，而是可以采用一个循环。每处理完一个 Fiber 节点，它都可以检查一下时间，如果时间紧张，就立刻记录下当前的工作进度，把主线程还给浏览器。等浏览器忙完了，再从上次中断的地方继续。
![[Pasted image 20251009022607.png]]
前面 setState -> diff -> render 的这样的线性流程，引入 **Fiber Reconciler** 之后：**setState -> Render Phase (可中断的 diff/reconciliation) -> Commit Phase (同步的 DOM 更新/render)**
所以，Fiber 的核心贡献是：**将渲染工作从“不可中断的递归调用”变成了“可中断的链表遍历”**。它为后续的优化提供了物理基础。
![[Pasted image 20251009025806.png]]
每处理一个 fiber 节点，都判断下是否中断，shouldYield 返回 true 的时候就终止这次循环。
循环处理每个 fiber 节点的时候，有个指针记录着当前的 fiber 节点，叫做 `workInProgress`。
这个循环叫做 workLoop。

### 1.2 时间切片：利用 Fiber 实现的调度策略
有了 Fiber 这个可中断的基础设施，我们就可以实现“时间切片”了。
因为 React 更新从根组件开始的“重新渲染 + Diff”过程依然可能是一个耗时较长的**纯计算任务**。
如果这个任务长时间占用主线程，页面就会卡顿。“时间切片”正是为了解决这个问题而设计的：**它允许 React 将这个宏大的计算任务切分成小块，在执行间隙可以响应用户输入等更高优先级的事件，从而保证应用的流畅性**。这个过程在 React 中被称为“调度”。
![[Pasted image 20251009025432.png]]
React 会在一个很短的时间片内执行工作，通常这个时间片的默认目标是 **5毫秒左右**，以确保主线程能快速响应更高优先级的任务。每次处理完一个 Fiber 节点，React 都会检查剩余时间是否足够。如果时间用尽，它就会暂停工作，将控制权交还给浏览器，等待下一轮空闲时间再继续。

### 1.3 并发机制：基于前两者的高级能力
当 React 既能将工作拆分（Fiber），又能控制工作的执行时机（时间切片）时，一个更强大的能力就诞生了：**并发**。
![[Pasted image 20251009030610.png]]
上面是两个 setState 引起的两个渲染流程，先处理前面渲染的 fiber 节点，然后处理下面渲染的 fiber 节点，之后继续处理上面渲染的 fiber 节点。
这就是并发。
**并发机制是 Fiber 和时间切片的“上层建筑”，它带来了革命性的新特性：**
- **`startTransition`**：你可以明确告诉 React：“这个更新（比如筛选一个很大的列表）是不紧急的，可以慢慢来。” React 会把它标记为低优先级任务，在后台处理。如果期间有高优先级任务（如用户输入）进来，React 会暂停低优先级任务，优先处理高优先级任务，处理完再恢复。
- **`useDeferredValue`**：与 `startTransition` 类似，它允许你延迟更新 UI 的某个部分。比如，一个输入框同时控制一个列表的筛选和一个图表的显示。你可以让图表的更新“延迟”，这样列表的筛选会感觉更即时。
- **`Suspense`**：当一个组件需要等待异步数据时，它可以在渲染过程中“抛出”一个 Promise。React 捕获后会暂停该组件树的渲染，并显示一个 fallback UI（如 loading），等到数据加载完成再恢复渲染。这个过程完全依赖于 Fiber 的可中断特性。

**所以，并发机制是建立在 Fiber 和时间切片之上的应用层能力。它让 React 能够智能地管理多个渲染任务，根据优先级进行调度、暂停、恢复甚至丢弃，从而打造出极致流畅的用户体验。**
并发特性可以给不同的 setState 标上不同的优先级的，我们看看 `startTransition`：
```jsx
import React, { useTransition, useState } from "react";

export default function App() {
  const [text, setText] = useState('ye');
  const [text2, setText2] = useState('che');

  const [isPending, startTransition] = useTransition()

  const handleClick = () => {
    startTransition(() => {
      setText('ye2');
    });

    setText2('che2');
  }

  return (
    <button onClick={handleClick}>{text}{text2}</button>
  );
}
```
在这个例子中，我们有两个状态更新。通过将 setText('ye2') 包裹在 startTransition 的回调中，我们明确地告诉 React：这个更新是**非紧急的**，可以推迟渲染，它是一个“过渡”任务。
而 setText2('che2') 没有被包裹，因此它被视为一个**紧急更新**，会立即触发高优先级的渲染。React 会优先完成紧急更新（che2 会立刻显示），然后再在后台处理过渡任务（ye2 的更新可能会稍后显示）。
上面谈到的优先级是调度任务的优先级，有这 5 种：
![[Pasted image 20251009023523.png]]
- **NoPriority**：代表“无优先级”，它**不属于任何实际的任务优先级**。它主要作为系统的初始值或一个特殊的占位符，用来表示某个工作单元（如 Fiber 节点）上当前没有待处理的更新任务。任何真正需要被调度的任务，都会被赋予一个具体的、可执行的优先级（如 Immediate, UserBlocking 等）。
- **Immediate**: 对应离散的用户行为，如 click, keydown, input。这些操作用户期望立即得到反馈，因此优先级最高。
- **UserBlocking**: 对应连续的用户行为，如 scroll, drag, mouseover。这些操作会频繁触发，如果每次都以最高优先级执行，可能会阻塞渲染，但它们也需要及时响应，否则用户会感到卡顿。所以它的优先级仅次于 Immediate。
- **NormalPriority**：网络请求返回后的数据更新、非关键的 setState。比如，页面加载后，通过 useEffect 获取文章列表并更新到界面上。
- **LowPriority**：数据预取（比如预加载下一页的数据）、分析和日志上报等。
- **Idle**: 最低优先级，用于执行那些完全可以在浏览器空闲时才做的任务。

## 2. Vue 的不同路径：精准更新
### 2.1 细粒度的响应式系统和高效的异步更新队列
Vue 的响应式系统实现了**细粒度**的依赖追踪，其精度远超“组件级别”，可以直达模板中的**具体绑定**（如一个文本插值或一个属性）。
![[Pasted image 20251008211240.png]]
- **依赖收集：** 在组件首次渲染时，Vue 会像一个侦探，记录下模板中哪个“视图片段”使用了哪个“响应式数据”。这个过程通过 Proxy (Vue 3) 或 Object.defineProperty (Vue 2) 实现。
- **精准更新：** 当一个响应式数据变化时，Vue 不会重新渲染整个组件。它会直接通知并重新执行那些“订阅”了该数据的**更新函数 (effect)**。这些函数只负责更新模板中那一小块依赖该数据的 DOM。

所以因为更新任务从一开始就是最小化的、分散的，所以每个任务的执行成本极低。Vue 只需要通过 nextTick 将同一事件循环中的多个小任务合并，进行一次批处理即可。这个过程本身就非常高效，几乎不会长时间阻塞主线程，因此也就不需要引入“时间切片”这种复杂的调度机制来打断它。

而 React 的模型不同，当一个组件的状态发生变化时，React 会**从这个组件开始，向下遍历其子组件树**，进行新旧 Virtual DOM 的对比（这个过程称为 Reconciliation）。虽然开发者可以手动通过 `React.memo`、`PureComponent` 或 `shouldComponentUpdate`、`useMemo`、`useCallback` 等 API 手动进行优化，跳过那些没有必要更新的子树，但其核心思想是“通过比对找出差异”。
这就像你只知道城里某个街区（触发更新的组件）有情况，但需要把这个街区挨家挨户盘问一遍才能确定具体问题。如果这个街区很大（组件树很深或很宽），盘问过程依然会很耗时。**而这种“地毯式排查”的模式，其根本原因在于 React 的状态是不可变的（Immutable）**：当状态变化时，React 只知道状态对象变了，但无法精确知道是哪个属性变了，因此需要通过 Diff 来寻找差异。
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
![[Pasted image 20251008085841.png]]
WeakMap 的键是原始对象 target，值是一个 Map 实例，而 Map 的键是原始对象 target 的 key，Map 的值是一个 由副作用函数组成的 Set。

### 2.2 编译时优化
Vue 是少数将编译时优化作为核心性能策略的主流框架之一。
Vue的编译器在将模板（template）编译成渲染函数（render function）的过程中，会进行大量的静态分析，为运行时的更新过程提供关键的优化信息。
主要有：
- **静态内容提升**：编译器识别出模板中永远不会改变的部分（静态节点），并将其提升到渲染函数之外，后续更新时完全跳过这些节点。
- **更新类型标记**：编译器为动态节点打上"标记"（Patch Flag），**（例如，标记 1 代表这个节点只有文本内容会变，标记 8 代表只有 class 会变）**，告诉运行时 diff 算法只需比对特定属性，避免全量树比对。
- **事件处理缓存**：编译器自动缓存内联事件处理器，避免每次渲染时都创建新的函数实例，优化内存占用和更新性能。
Vue SFC Plauground 地址：[https://play.vuejs.org/](https://play.vuejs.org/)
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
其实 React 团队也早已意识到了手动优化的心智负担问题，所以开发了 **React Compiler**（以前叫 Forget），它会尝试去分析你的 JavaScript 代码，**推断**出哪些部分是稳定的，自动为你加上 `React.memo`, `useCallback`, `useMemo`。
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
React 和 Vue 在性能优化上走向了两条截然不同的道路，这根植于它们核心架构的差异：
- **React 的并发机制**：其核心是“**调度**”。它接受了“更新可能是慢的”这一事实，因此构建了以 Fiber 为基础的复杂调度系统，为“慢”任务提供一种不阻塞主线程的执行方式，保障用户交互的优先响应。
- **Vue 的响应式系统**：其核心是“**精准**”。它通过细粒度的依赖追踪和编译时优化，从源头上极大地减少了不必要的更新和计算量，努力让每一次任务都“足够快”，以至于在绝大多数场景下都不需要中断与恢复的复杂调度。

两者没有绝对的优劣，只是在不同设计哲学下的不同取舍。React 提供了处理极端复杂场景的强大能力，而 Vue 则提供了更易于理解和“开箱即用”的高性能体验。

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
