核心原因是 **DPR (Device Pixel Ratio，设备像素比)** 的存在。

- **CSS 像素 (Logical Pixel)**：我们在代码里写的 1px。
- **物理像素 (Physical Pixel)**：屏幕实际发光的点。

在普通屏幕上（DPR=1），1px CSS 对应 1px 物理像素，显示正常。

但在高清屏上（例如 iPhone 的 DPR 通常为 2 或 3）：

- **DPR = 2**：代码写的 1px，屏幕会用 **2个物理像素** 来渲染，所以看起来像 2px 那么粗。
- **DPR = 3**：屏幕会用 **3个物理像素** 来渲染，看起来更粗。



伪类 + transform: scale 这是目前最成熟、兼容性最好的方案。原理是把伪元素宽高设为 200%，边框设为 1px，然后缩放 0.5 倍。

```css
.border-1px {
  position: relative;
}

.border-1px::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 200%;
  height: 200%;
  border: 1px solid #e5e5e5; /* 边框颜色 */
  transform-origin: 0 0;
  transform: scale(0.5);
  box-sizing: border-box;
  pointer-events: none; /* 防止遮挡点击事件 */
  border-radius: 0; /* 如果原元素有圆角，这里需要设置原圆角的2倍 */
}
```

*如果是单边边框（如只有下边框），只需要设置 border-bottom 即可。*



