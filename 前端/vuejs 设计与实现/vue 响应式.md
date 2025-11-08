```js
// 全局依赖映射
const targetMap = new WeakMap()
// 当前激活的 effect
let activeEffect = null

// 注册副作用函数
function effect(fn) {
  const effectFn = () => {
    // 重置依赖，避免过期依赖
    cleanup(effectFn)
    activeEffect = effectFn
    try {
      fn()
    } finally {
      activeEffect = null
    }
  }
  // 记录该 effect 依赖的所有 dep
  effectFn.deps = []
  effectFn()
}

// 清理 effect 的依赖
function cleanup(effectFn) {
  // 从所有依赖集合中移除自己
  effectFn.deps.forEach(dep => dep.delete(effectFn))
  effectFn.deps.length = 0
}

// 收集依赖
function track(target, key) {
  if (!activeEffect) return

  let depsMap = targetMap.get(target)
  if (!depsMap) {
    depsMap = new Map()
    targetMap.set(target, depsMap)
  }

  let dep = depsMap.get(key)
  if (!dep) {
    dep = new Set()
    depsMap.set(key, dep)
  }

  // 双向绑定：dep 存 effect，effect 存 dep
  if (!dep.has(activeEffect)) {
    dep.add(activeEffect)
    activeEffect.deps.push(dep)
  }
}

// 触发更新
function trigger(target, key) {
  const depsMap = targetMap.get(target)
  if (!depsMap) return

  const dep = depsMap.get(key)
  if (!dep) return

  // 复制一份避免遍历时修改集合
  const effects = [...dep]
  effects.forEach(effect => effect())
}

// 创建响应式对象
function reactive(target) {
  return new Proxy(target, {
    get(target, key, receiver) {
      // 读取时建立依赖关系
      track(target, key)
      return Reflect.get(target, key, receiver)
    },
    set(target, key, value, receiver) {
      const oldValue = target[key]
      const result = Reflect.set(target, key, value, receiver)
      // 值变化才通知，避免无效更新
      if (result && oldValue !== value) {
        trigger(target, key)
      }
      return result
    }
  })
}
```

核心数据结构：

```js
// 目标对象 -> 属性 -> effect 集合
const targetMap = new WeakMap()
```

因为当目标对象被垃圾回收时，对应的依赖映射也能自动释放，避免内存泄漏。

需要一个全局变量记录当前正在执行的 effect，以便在读取数据时知道该收集哪个依赖：

```js
let activeEffect = null
```

注册副作用函数，并在执行时建立依赖关系：

```js
function effect(fn) {
  const effectFn = () => {
    // 先清理之前的依赖，避免重复收集
    cleanup(effectFn)
    activeEffect = effectFn
    try {
      fn()
    } finally {
      activeEffect = null
    }
  }
  effectFn.deps = [] // 记录该 effect 依赖了哪些 dep
  effectFn()
}
```

当读取响应式数据时，将 activeEffect 添加到对应的依赖集合中：

```js
function track(target, key) {
  if (!activeEffect) return

  // 获取或创建 depsMap
  let depsMap = targetMap.get(target)
  if (!depsMap) {
    depsMap = new Map()
    targetMap.set(target, depsMap)
  }

  // 获取或创建 dep (Set)
  let dep = depsMap.get(key)
  if (!dep) {
    dep = new Set()
    depsMap.set(key, dep)
  }

  // 建立双向引用：dep 存 effect，effect.deps 存 dep
  if (!dep.has(activeEffect)) {
    dep.add(activeEffect)
    activeEffect.deps.push(dep)
  }
}
```

双向引用的设计是为了 cleanup 时能快速找到并移除所有相关依赖。

当修改响应式数据时，执行所有依赖它的 effects：

```js
function trigger(target, key) {
  const depsMap = targetMap.get(target)
  if (!depsMap) return

  const dep = depsMap.get(key)
  if (!dep) return

  // 执行所有依赖该属性的 effects
  // 创建新数组避免在遍历时修改原集合
  const effects = [...dep]
  effects.forEach(effect => effect())
}
```

为什么创建新数组？因为 effect 执行时可能会再次触发 track，修改原 dep 集合，导致遍历异常。

使用 Proxy 拦截读写操作：

```js
function reactive(target) {
  return new Proxy(target, {
    get(target, key, receiver) {
      // 读取时收集依赖
      track(target, key)
      return Reflect.get(target, key, receiver)
    },
    set(target, key, value, receiver) {
      const oldValue = target[key]
      const result = Reflect.set(target, key, value, receiver)
      // 值真正改变时才触发更新
      if (result && oldValue !== value) {
        trigger(target, key)
      }
      return result
    }
  })
}
```

清理 effect 的所有依赖：

```js
function cleanup(effectFn) {
  // 从所有 dep 集合中移除该 effect
  effectFn.deps.forEach(dep => dep.delete(effectFn))
  // 清空 effect 的 deps 数组
  effectFn.deps.length = 0
}
```
