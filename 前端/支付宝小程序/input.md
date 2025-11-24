## 一、Input 实现原理总览

支付宝小程序的 input 组件有三种实现方式，理解这些原理是避免踩坑的关键：

### 1.1 三种实现方式对比

| 实现方式 | iOS 支持 | Android 支持 | 特点 |
|---------|----------|--------------|------|
| 原生 W3C 标准 | ✅ | ✅ | 使用系统原生 input，符合 W3C 标准 |
| 半同层组件 | ✅ | ✅ | 通过插件劫持事件，容器合成键盘 |
| 全同层组件 | ✅ | ❌ | iOS 专用，WebView 上生成 native 图层 |

### 1.2 同层渲染概念

**同层渲染**：将原生组件直接渲染到 WebView 层级，解决传统原生组件层级过高、无法覆盖的问题。

- **iOS**：基于 WKChildScrollView 实现
- **Android**：基于 WebPlugin + 像素擦除实现

## 二、Input 类型配置详解

### 2.1 iOS 平台配置

#### 原生输入框（W3C 标准）
```html
<input
  class="input"
  always-system="{{true}}"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

#### 半同层输入框（默认）
```html
<input
  class="input"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

#### 全同层输入框
```html
<input
  class="input"
  enableNative="{{true}}"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

**app.json 必须配置：**
```json
{
  "window": {
    "enableInPageRender": "YES",
    "enableInPageRenderInput": "YES"
  }
}
```

### 2.2 Android 平台配置

#### 原生输入框
```html
<input
  class="input"
  always-system="{{true}}"
  enableNative="{{false}}"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

#### 半同层输入框（推荐）
```html
<input
  class="input"
  enableNative="{{true}}"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

## 三、场景化配置推荐

### 3.1 基础表单场景
**需求**：普通文本输入，无特殊要求
**推荐配置**：
- iOS：半同层（默认）
- Android：半同层（enableNative="{{true}}"）

```html
<input
  placeholder="请输入内容"
  value="{{formData.name}}"
  onInput="handleNameInput"
/>
```

### 3.2 数字输入场景
**需求**：金额、验证码等数字输入
**推荐配置**：
- iOS：原生（always-system="{{true}}"）
- Android：原生（always-system="{{true}}"）

```html
<input
  type="number"
  placeholder="请输入金额"
  always-system="{{true}}"
  value="{{formData.amount}}"
  onInput="handleAmountInput"
/>
```

### 3.3 自定义键盘场景
**需求**：身份证、随机数字键盘
**推荐配置**：
- iOS：全同层（需配置 app.json）
- Android：半同层（enableNative="{{true}}"）

```html
<input
  type="idcard"
  placeholder="请输入身份证号"
  enableNative="{{true}}"
  value="{{formData.idCard}}"
  onInput="handleIdCardInput"
/>
```

### 3.4 弹窗输入场景
**需求**：弹窗内输入框，需要自动聚焦
**推荐配置**：
- iOS：全同层（解决 focus 无效问题）
- Android：半同层（enableNative="{{true}}"）

```html
<!-- 弹窗组件内 -->
<view class="popup" a:if="{{showPopup}}">
  <input
    focus="{{autoFocus}}"
    enableNative="{{true}}"
    placeholder="请输入"
    value="{{popupValue}}"
    onInput="handlePopupInput"
  />
</view>
```

## 四、常见踩坑及解决方案

### 4.1 样式问题

#### Case 1：disabled 状态颜色异常
**问题**：iOS 同层渲染下，disabled 时文字颜色不对

**解决方案**：
```javascript
// 方案1：使用 view 替代
<view 
  class="{{disabled ? 'input-disabled' : 'input-normal'}}" 
  a:if="{{disabled}}"
>
  {{value}}
</view>
<input a:else value="{{value}}" disabled="{{disabled}}" />

// 方案2：条件渲染
<input 
  style="color: {{disabled ? '#999' : '#333'}}"
  disabled="{{disabled}}"
  enableNative="{{false}}"
/>
```

#### Case 2：字体不一致
**问题**：focus 和 blur 状态字体不同

**解决方案**：
```css
/* 强制统一字体 */
.input {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
}
```

### 4.2 事件问题

#### Case 3：value 与 onInput 顺序问题
**问题**：受控组件过滤输入失效

**解决方案**：
```javascript
// 错误写法：直接过滤
handleInput(e) {
  const value = e.detail.value.replace(/[^0-9]/g, '');
  this.setData({ value }); // 可能不触发更新
}

// 正确写法：使用 controlled + 微任务
handleInput(e) {
  const rawValue = e.detail.value;
  const filteredValue = rawValue.replace(/[^0-9]/g, '');
  
  // 先设置原始值，再过滤
  this.setData({ value: rawValue });
  
  Promise.resolve().then(() => {
    if (filteredValue !== rawValue) {
      this.setData({ value: filteredValue });
    }
  });
}
```

#### Case 4：onInput 多次触发
**问题**：中文输入或英文词汇输入时触发多次

**解决方案**：
```javascript
handleInput: debounce(function(e) {
  const value = e.detail.value;
  if (value === this.data.lastValue) return;
  
  this.setData({ 
    value,
    lastValue: value 
  });
}, 100),
```

### 4.3 光标问题

#### Case 5：光标漂移
**问题**：输入时 input 位置变化导致光标偏移

**解决方案**：
```javascript
// 方案1：固定位置
.input-container {
  position: relative;
  height: 88rpx;
}

.input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
}

// 方案2：平台判断
const isIOS = my.getSystemInfoSync().platform === 'iOS';

<input 
  enableNative="{{isIOS ? true : false}}"
  always-system="{{isIOS ? false : true}}"
/>
```

#### Case 6：focus 无效
**问题**：iOS 下 focus 属性不生效

**解决方案**：
```javascript
// 方案1：使用全同层
<input 
  focus="{{autoFocus}}"
  enableNative="{{true}}"
/>

// 方案2：延迟聚焦
showPopup() {
  this.setData({ showPopup: true });
  
  // 等待弹窗渲染完成
  setTimeout(() => {
    this.setData({ autoFocus: true });
  }, 300);
}
```

### 4.4 键盘问题

#### Case 7：键盘推起页面异常
**问题**：键盘推起后页面无法恢复

**解决方案**：
```javascript
// 监听键盘高度变化
Page({
  onKeyboardHeightChange(e) {
    const { height } = e.detail;
    this.setData({ keyboardHeight: height });
    
    if (height === 0) {
      // 键盘收起，滚动到顶部
      my.pageScrollTo({ scrollTop: 0 });
    }
  },
  
  onLoad() {
    my.onKeyboardHeightChange(this.onKeyboardHeightChange);
  },
  
  onUnload() {
    my.offKeyboardHeightChange(this.onKeyboardHeightChange);
  }
});
```

#### Case 8：弹窗被键盘遮盖
**问题**：底部弹窗输入时内容被顶上去

**解决方案**：
```javascript
// 方案1：添加 padding-bottom
.popup-container {
  padding-bottom: var(--keyboard-height);
}

// 方案2：使用 scroll-view
<scroll-view 
  scroll-y 
  style="height: calc(100vh - {{keyboardHeight}}px)"
>
  <input />
</scroll-view>
```

## 五、最佳实践代码模板

### 5.1 通用输入组件封装

```javascript
// components/uni-input/index.ts
Component({
  props: {
    value: String,
    placeholder: String,
    type: {
      type: String,
      value: 'text'
    },
    disabled: Boolean,
    focus: Boolean,
    maxLength: Number,
    confirmType: String
  },
  
  data: {
    platform: 'android',
    inputType: 'text'
  },
  
  didMount() {
    const systemInfo = my.getSystemInfoSync();
    this.setData({
      platform: systemInfo.platform.toLowerCase()
    });
  },
  
  methods: {
    handleInput(e) {
      this.triggerEvent('input', e.detail);
    },
    
    handleFocus(e) {
      this.triggerEvent('focus', e.detail);
    },
    
    handleBlur(e) {
      this.triggerEvent('blur', e.detail);
    }
  }
});
<!-- components/uni-input/index.axml -->
<view class="uni-input-container">
  <input
    class="uni-input"
    value="{{value}}"
    placeholder="{{placeholder}}"
    type="{{inputType}}"
    disabled="{{disabled}}"
    focus="{{focus}}"
    maxlength="{{maxLength}}"
    confirm-type="{{confirmType}}"
    enableNative="{{platform === 'ios' ? true : undefined}}"
    always-system="{{platform === 'android' ? true : undefined}}"
    onInput="handleInput"
    onFocus="handleFocus"
    onBlur="handleBlur"
  />
</view>
```

### 5.2 金额输入组件

```javascript
// components/amount-input/index.ts
Component({
  props: {
    value: String,
    placeholder: String,
    maxAmount: Number
  },
  
  methods: {
    handleInput(e) {
      const value = e.detail.value;
      // 只允许输入数字和小数点
      const filtered = value.replace(/[^\d.]/g, '');
      
      // 限制小数位数
      const parts = filtered.split('.');
      if (parts[1] && parts[1].length > 2) {
        parts[1] = parts[1].slice(0, 2);
      }
      
      const result = parts.join('.');
      
      // 检查最大值
      if (this.props.maxAmount && parseFloat(result) > this.props.maxAmount) {
        return;
      }
      
      this.triggerEvent('input', { value: result });
    }
  }
});
<!-- components/amount-input/index.axml -->
<view class="amount-input-container">
  <text class="currency-symbol">¥</text>
  <input
    class="amount-input"
    type="digit"
    placeholder="{{placeholder || '0.00'}}"
    value="{{value}}"
    always-system="{{true}}"
    controlled
    onInput="handleInput"
  />
</view>
```

## 六、调试工具与技巧

### 6.1 平台判断工具

```javascript
// utils/platform.js
export const Platform = {
  isIOS() {
    return my.getSystemInfoSync().platform === 'iOS';
  },
  
  isAndroid() {
    return my.getSystemInfoSync().platform === 'Android';
  },
  
  getInputConfig(type = 'text') {
    const isIOS = this.isIOS();
    
    if (type === 'number' || type === 'digit' || type === 'idcard') {
      return {
        alwaysSystem: true,
        enableNative: false
      };
    }
    
    return {
      alwaysSystem: false,
      enableNative: isIOS ? true : undefined
    };
  }
};
```

### 6.2 调试检查清单

1. **样式检查**
   - [ ] 字体是否统一
   - [ ] disabled 状态颜色是否正确
   - [ ] 光标位置是否正常

2. **功能检查**
   - [ ] 输入过滤是否生效
   - [ ] 自动聚焦是否正常
   - [ ] 键盘类型是否正确

3. **兼容性检查**
   - [ ] iOS 全同层配置
   - [ ] Android 原生配置
   - [ ] 弹窗场景测试

## 七、版本兼容说明

### 7.1 新同层方案（2024年1月开始灰度）

**新特性**：
- 支持 system-keyboard 属性
- 更好的光标位置计算
- 改进的键盘动画处理

**使用方式**：
```html
<input
  system-keyboard="{{true}}"
  enableNative="{{true}}"
/>
```

### 7.2 兼容性检测

```javascript
// 检测新同层方案支持
const canUseNewInput = my.canIUse('input.system-keyboard');

if (canUseNewInput) {
  // 使用新方案
} else {
  // 使用传统方案
}
```

## 八、总结建议

1. **简单场景**：使用默认配置（半同层）
2. **数字输入**：使用原生输入（always-system）
3. **复杂交互**：使用全同层（iOS）或半同层（Android）
4. **弹窗场景**：注意聚焦时机和键盘动画
5. **样式统一**：做好平台差异化处理

记住：没有完美的方案，只有最适合当前场景的方案。根据具体需求选择合适的配置，并做好充分的测试。