在移动端，尤其是高清屏（比如 iPhone 的 Retina 屏）上，当你在 CSS 中设置 `border: 1px solid #ccc;` 时，这条边框看起来会比预期的更粗，有点“糊”，不够精致。而在 PC 端或者一些低分辨率的手机上，它看起来则刚刚好。

要理解这个问题，我们需要先弄清楚两个核心概念：**CSS 像素**和**设备像素**。

1. **CSS 像素 (Logical Pixel)**：这是我们开发者在写 CSS 时使用的单位，比如 `width: 100px;`、`font-size: 16px;`。它是一个抽象的、逻辑上的单位。
2. **设备像素 (Physical Pixel)**：这是屏幕上真实的、物理的发光点。一个屏幕的分辨率，比如 `1920x1080`，指的就是设备像素的数量。

在过去的普通屏幕上，`1 个 CSS 像素` 就等于 `1 个设备像素`。所以 `border: 1px;` 就会精确地占用 1 个物理发光点，看起来很细。

但现在，手机屏幕技术飞速发展，出现了各种**高清屏**或**视网膜屏**。为了在更小的屏幕上显示更细腻的图像，厂商在同样大小的物理空间里塞进了更多的设备像素。

这就引出了一个关键的比例：**设备像素比**。

```
DPR = 设备像素数量 / CSS 像素数量
```

- **DPR = 1**：普通屏幕，1 CSS 像素 = 1 设备像素。
- **DPR = 2**：高清屏（如 iPhone 6/7/8），1 CSS 像素 = 2 设备像素。
- **DPR = 3**：超高清屏（如 iPhone X 及以后），1 CSS 像素 = 3 设备像素。

**现在，问题就清晰了：**

当你在 DPR 为 2 的屏幕上设置 `border: 1px;` 时，浏览器需要用 **2 个设备像素**来渲染这 **1 个 CSS 像素**的边框。结果就是，这条边框在物理上占据了 2 个发光点的宽度，所以看起来就比 1 个发光点要粗。

既然问题的根源是 DPR，那么解决方案的核心就是**想办法让边框的物理宽度等于 1 个设备像素**。



### 方案一：`transform: scale()` 缩放法（最常用）

这是目前最主流、兼容性最好的方案。

**思路：** 我们先“假装”画一条粗一点的边框（比如 2px），然后通过 CSS `transform` 将它缩小到目标大小（比如 0.5 倍），这样它在物理上就接近 1px 了。

1. 利用伪元素（`::before` 或 `::after`）来绘制边框，避免影响布局。
2. 先给伪元素设置 `height: 1px;`（或 `width: 1px;`）。
3. 通过 `transform: scaleY(0.5);`（或 `scaleX(0.5)`）将其在 Y 轴（或 X 轴）方向上缩小一半。

```css
/* 给需要添加边框的元素设置相对定位 */
.hairline-bottom {
  position: relative;
}

/* 使用伪元素绘制边框 */
.hairline-bottom::after {
  content: '';
  position: absolute;
  left: 0;
  bottom: 0;
  width: 100%;
  /* 先画一条 1px 的线 */
  height: 1px;
  background-color: #000;
  /* 关键：在 DPR 为 2 的屏幕上，将其高度缩放为 0.5 */
  transform: scaleY(0.5);
}

/* 针对更高 DPR 的屏幕做适配 */
@media (-webkit-min-device-pixel-ratio: 3) {
  .hairline-bottom::after {
    transform: scaleY(0.333);
  }
}
```

需要借助伪元素，对于圆角边框实现起来比较麻烦。





### 方案二：`box-shadow` 阴影法

利用 `box-shadow` 的第四个参数（扩张半径）来模拟一条边框。

```css
.hairline-shadow {
  /* 参数：x偏移 y偏移 模糊半径 扩张半径 颜色 */
  /* 画一条在元素下方，不模糊，垂直方向扩张 0.5px 的阴影 */
  box-shadow: 0 0.5px 0 0 #000;
}
```

颜色可能会比 `border` 稍淡；无法实现 `dashed` 或 `dotted` 等虚线样式；性能上可能略逊于 `border`。



### 方案三：`viewport` + `rem` 适配法（一劳永逸）

既然 DPR 导致了 1 CSS 像素等于多个设备像素，那我们干脆在页面加载时，动态地调整 `viewport` 的缩放比例，让 1 CSS 像素永远等于 1 设备像素。

通过 JavaScript 获取设备的 DPR，然后设置 `viewport` 的 `initial-scale`。

```js
// 获取 DPR
const dpr = window.devicePixelRatio || 1;

// 动态设置 viewport 的缩放值
const scale = 1 / dpr;
const meta = document.createElement('meta');
meta.name = 'viewport';
meta.content = `width=device-width, initial-scale=${scale}, maximum-scale=${scale}, minimum-scale=${scale}, user-scalable=no`;
document.head.appendChild(meta);
```

这是“核武器”级别的方案，它会缩放整个页面。如果你的项目依赖 `rem` 单位做响应式布局，这个方案可能会与你的布局系统产生冲突，导致所有尺寸都变得不正确。因此，只建议在新项目且充分评估风险后使用。



| 方案                     | 优点                       | 缺点                            | 推荐场景                                         |
| :----------------------- | :------------------------- | :------------------------------ | :----------------------------------------------- |
| **`transform: scale()`** | 效果好，兼容性强，控制精确 | 代码稍多，圆角实现复杂          | **绝大多数项目**，特别是对细节要求高的 UI 组件库 |
| **`box-shadow`**         | 代码简洁                   | 颜色/样式有局限，性能略低       | 快速实现简单的、非虚线的细边框                   |
| **`viewport` 缩放**      | 一劳永逸，全局生效         | 可能破坏现有 `rem` 布局，风险高 | 新项目，且不依赖 `rem` 做响应式设计              |

对于日常开发，**首选 `transform: scale()` 方案**。虽然代码多一点，但它最稳定、最可靠。通常，我们会把它封装成一个公共的 CSS 类（如 `.hairline-top`, `.hairline-bottom`）或者一个 Sass/Less mixin，这样在需要的地方直接调用即可，非常方便。







