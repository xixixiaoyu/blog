## 一、Input 组件概述

### 1.1 什么是同层渲染

小程序的内容大多是渲染在 WebView 上的，如果把 WebView 看成单独的一层，那么由系统自带的这些原生组件则位于另一个更高的层级。两个层级是完全独立的，因此无法简单地通过使用 z-index 控制原生组件和非原生组件之间的相对层级。

**同层渲染**是指通过一定的技术手段把原生组件直接渲染到 WebView 层级上，此时「原生组件层」已经不存在，原生组件此时已被直接挂载到 WebView 节点上。

### 1.2 三种实现方式

| 实现方式 | 描述 | 适用场景 |
|---------|------|----------|
| **原生 W3C 标准** | 使用浏览器自带的 input 组件 | 简单场景，兼容性要求高 |
| **半同层组件** | 通过插件劫持事件，容器进行事件合成 | 需要自定义键盘的场景 |
| **全同层组件** | iOS 在 webview 上生成 native 图层渲染 | 复杂交互，需要精确控制 |

---

## 二、三种渲染模式详解

### 2.1 原生 W3C 标准模式

#### 配置方式
```json
// app.json 无需特殊配置
```

#### 使用示例
```html
<!-- iOS 和 Android 通用 -->
<input
  class="input"
  always-system="{{true}}"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

#### 特点
- ✅ 符合 W3C 标准，使用简单
- ✅ 支持所有 CSS 样式
- ❌ 不支持身份证、随机数字等自定义键盘
- ❌ 不支持自动唤起键盘

### 2.2 半同层组件模式

#### 配置方式
```json
// app.json 无需特殊配置
```

#### 使用示例
```html
<!-- iOS 默认就是半同层 -->
<input
  class="input"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>

<!-- Android 需要设置 enableNative -->
<input
  class="input"
  enableNative="{{true}}"
  value="{{value}}"
  controlled
  onInput="onInput"
  onBlur="onBlur"
/>
```

#### 特点
- ✅ 支持各种自定义键盘
- ✅ 不依赖 Webkit 的同层节点逻辑
- ❌ 位置容易计算异常
- ❌ 可能出现重影问题

### 2.3 全同层组件模式（仅 iOS）

#### 配置方式
```json
// app.json
{
  "pages": ["pages/index/index"],
  "window": {
    "enableInPageRender": "YES",
    "enableInPageRenderInput": "YES"
  }
}
```

#### 使用示例
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

#### 特点
- ✅ 支持各种自定义键盘
- ✅ 位置计算准确，无重影
- ✅ 支持自动唤起键盘
- ❌ 不符合 W3C 标准
- ❌ 仅 iOS 支持

---

## 三、平台差异对比

### 3.1 iOS vs Android 实现差异

| 特性 | iOS | Android |
|------|-----|---------|
| **原生输入框** | always-system="{{true}}" | always-system="{{true}}" + enableNative="{{false}}" |
| **半同层输入框** | 默认 | enableNative="{{true}}" |
| **全同层输入框** | enableNative="{{true}}" + 配置 | ❌ 不支持 |
| **自定义键盘** | 支持 | 支持 |
| **自动唤起** | 全同层支持 | 有限支持 |

### 3.2 键盘类型支持

| 键盘类型 | iOS 原生 | iOS 半同层 | iOS 全同层 | Android 原生 | Android 半同层 |
|----------|----------|------------|------------|--------------|----------------|
| text | ✅ | ✅ | ✅ | ✅ | ✅ |
| number | ✅ | ✅ | ✅ | ✅ | ✅ |
| idcard | ❌ | ✅ | ✅ | ❌ | ✅ |
| digit | ❌ | ✅ | ✅ | ❌ | ✅ |
| numberpad | ❌ | ✅ | ✅ | ❌ | ✅ |

---

## 四、属性配置指南

### 4.1 核心属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| **always-system** | Boolean | false | 是否使用系统原生输入框 |
| **enableNative** | Boolean | true | 是否启用同层渲染 |
| **controlled** | Boolean | false | 是否受控组件 |
| **type** | String | text | 输入框类型 |

### 4.2 推荐配置组合

#### 场景1：简单文本输入
```html
<!-- 双端一致，最稳定 -->
<input
  always-system="{{true}}"
  type="text"
  placeholder="请输入内容"
/>
```

#### 场景2：需要数字键盘
```html
<!-- iOS -->
<input
  type="number"
  enableNative="{{true}}"
/>

<!-- Android -->
<input
  type="number"
  enableNative="{{true}}"
/>
```

#### 场景3：需要自动聚焦
```html
<!-- iOS 全同层 -->
<input
  enableNative="{{true}}"
  focus="{{true}}"
/>

<!-- Android 半同层 -->
<input
  enableNative="{{true}}"
  focus="{{true}}"
/>
```

---

## 五、常见问题与解决方案

### 5.1 样式问题

#### Case 1: disabled 状态下文字颜色异常
**问题描述**：iOS 同层渲染下，disabled 时文字颜色与正常状态一致

**解决方案**：
```javascript
// 方案1：使用 view 替代
<view class="{{disabled ? 'input-disabled' : 'input-normal'}}">
  {{value || placeholder}}
</view>

// 方案2：使用半同层渲染
<input
  enableNative="{{false}}"
  disabled="{{disabled}}"
/>
```

#### Case 2: 光标漂移问题
**问题描述**：输入时 input 位置发生变化导致光标偏移

**解决方案**：
```javascript
// 方案1：避免输入时改变 input 位置
// 方案2：根据平台设置不同属性
const inputProps = my.env.platform === 'iOS' 
  ? { enableNative: true } 
  : { enableNative: false };
```

### 5.2 事件问题

#### Case 3: value 与 onInput 顺序问题
**问题描述**：受控组件下，value 更新不及时

**解决方案**：
```javascript
// 方案1：使用深拷贝触发更新
onInput(e) {
  const value = e.detail.value;
  const filteredValue = value.replace(/[^0-9]/g, '');
  this.setData({
    value: JSON.parse(JSON.stringify(filteredValue))
  });
}

// 方案2：使用 selection-start 触发重绘
this.setData({
  value: filteredValue,
  selectionStart: filteredValue.length
});
```

#### Case 4: onInput 多次触发
**问题描述**：iOS 原生英文键盘词汇可能触发多次 onInput

**解决方案**：
```javascript
// 防抖处理
let lastValue = '';
onInput: debounce(function(e) {
  const value = e.detail.value;
  if (value === lastValue) return;
  lastValue = value;
  // 处理逻辑
}, 300)
```

### 5.3 键盘问题

#### Case 5: 键盘遮挡内容
**问题描述**：键盘弹起后遮挡输入框

**解决方案**：
```javascript
// 监听键盘高度变化
Page({
  onKeyboardHeight(e) {
    const { height } = e.detail;
    this.setData({ keyboardHeight: height });
  }
});
```

#### Case 6: 自动聚焦失效
**问题描述**：iOS 下 focus 属性无效

**解决方案**：
```javascript
// iOS 需要使用全同层渲染
<input
  enableNative="{{true}}"
  focus="{{autoFocus}}"
/>
```

---

## 六、最佳实践

### 6.1 通用配置模板

```javascript
// utils/input-config.js
export const getInputConfig = (platform, type = 'text') => {
  const baseConfig = {
    controlled: true,
    'selection-start': -1,
    'selection-end': -1
  };
  
  if (platform === 'iOS') {
    return {
      ...baseConfig,
      enableNative: type !== 'text', // 非文本类型使用同层
    };
  } else {
    return {
      ...baseConfig,
      enableNative: true, // Android 默认半同层
    };
  }
};
```

### 6.2 输入框组件封装

```javascript
// components/smart-input/index.js
Component({
  props: {
    value: '',
    type: 'text',
    placeholder: '',
    disabled: false,
    autoFocus: false
  },
  
  data: {
    inputProps: {}
  },
  
  didMount() {
    this.setInputProps();
  },
  
  methods: {
    setInputProps() {
      const platform = my.env.platform;
      const { type, autoFocus } = this.props;
      
      let config = {
        type,
        value: this.props.value,
        placeholder: this.props.placeholder,
        disabled: this.props.disabled,
        controlled: true
      };
      
      // 平台特定配置
      if (platform === 'iOS') {
        if (type === 'text') {
          config.alwaysSystem = true;
        } else {
          config.enableNative = true;
        }
        if (autoFocus) {
          config.focus = true;
        }
      } else {
        config.enableNative = true;
        if (autoFocus) {
          config.focus = true;
        }
      }
      
      this.setData({ inputProps: config });
    },
    
    onInput(e) {
      this.props.onChange(e.detail.value);
    }
  }
});
```

### 6.3 输入验证最佳实践

```javascript
// utils/input-validator.js
export const createInputValidator = (rules) => {
  return (value) => {
    for (const rule of rules) {
      const result = rule(value);
      if (result !== true) {
        return result;
      }
    }
    return true;
  };
};

// 使用示例
const phoneValidator = createInputValidator([
  (value) => !value || /^1[3-9]\d{9}$/.test(value) || '请输入正确的手机号'
]);
```

---

## 七、性能优化

### 7.1 减少重渲染

```javascript
// 避免频繁 setData
Page({
  data: {
    inputValue: '',
    lastValue: ''
  },
  
  onInput(e) {
    const value = e.detail.value;
    if (value === this.data.lastValue) return;
    
    this.setData({
      inputValue: value,
      lastValue: value
    });
  }
});
```

### 7.2 防抖处理

```javascript
// utils/debounce.js
export function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// 使用
onInput: debounce(function(e) {
  this.handleSearch(e.detail.value);
}, 500)
```

---

## 八、实战案例

### 8.1 手机号输入框

```javascript
// pages/phone-input/index.js
Page({
  data: {
    phone: '',
    isValid: false
  },
  
  onPhoneInput(e) {
    const phone = e.detail.value.replace(/\D/g, '');
    const isValid = /^1[3-9]\d{9}$/.test(phone);
    
    this.setData({
      phone,
      isValid
    });
  },
  
  onSubmit() {
    if (!this.data.isValid) {
      my.showToast({
        content: '请输入正确的手机号',
        type: 'fail'
      });
      return;
    }
    
    // 提交逻辑
  }
});
```

```html
<!-- pages/phone-input/index.axml -->
<view class="phone-input-container">
  <input
    class="phone-input"
    type="number"
    placeholder="请输入手机号"
    value="{{phone}}"
    controlled
    onInput="onPhoneInput"
    enableNative="{{true}}"
  />
  <button 
    class="submit-btn {{isValid ? 'active' : ''}}" 
    disabled="{{!isValid}}"
    onTap="onSubmit"
  >
    获取验证码
  </button>
</view>
```

### 8.2 金额输入框

```javascript
// components/amount-input/index.js
Component({
  props: {
    value: '',
    placeholder: '0.00',
    maxAmount: 999999.99
  },
  
  methods: {
    onAmountInput(e) {
      let value = e.detail.value;
      
      // 只允许输入数字和小数点
      value = value.replace(/[^\d.]/g, '');
      
      // 限制小数位数
      const parts = value.split('.');
      if (parts[1] && parts[1].length > 2) {
        value = parts[0] + '.' + parts[1].slice(0, 2);
      }
      
      // 限制最大值
      const numValue = parseFloat(value) || 0;
      if (numValue > this.props.maxAmount) {
        value = this.props.maxAmount.toString();
      }
      
      this.props.onChange(value);
    }
  }
});
```

---

## 九、调试技巧

### 9.1 查看当前渲染模式

```javascript
// 调试工具
const getRenderMode = () => {
  const platform = my.env.platform;
  const query = my.createSelectorQuery();
  
  query.select('.input').fields({
    dataset: true,
    rect: true
  }).exec(res => {
    console.log('当前渲染模式:', {
      platform,
      dataset: res[0]?.dataset,
      rect: res[0]?.rect
    });
  });
};
```

### 9.2 键盘事件监听

```javascript
Page({
  onKeyboardHeight(e) {
    console.log('键盘高度变化:', e.detail);
    // e.detail.height 键盘高度（px）
  }
});
```

---

## 十、版本兼容性

| 功能 | 最低版本 | 说明 |
|------|----------|------|
| enableNative | 10.1.50 | 同层渲染开关 |
| always-system | 10.1.58 | 系统原生输入框 |
| focus 属性 | 10.1.70 | 自动聚焦 |
| 新同层方案 | 10.5.26 | 优化后的全同层 |

---

## 十一、总结建议

### 11.1 选择指南

| 场景 | 推荐配置 |
|------|----------|
| **简单文本输入** | always-system="{{true}}" |
| **需要数字键盘** | enableNative="{{true}}" |
| **需要自动聚焦** | enableNative="{{true}}" + focus |
| **复杂样式需求** | always-system="{{true}}" |
| **性能要求高** | enableNative="{{true}}" |

### 11.2 开发建议

1. **优先使用半同层渲染**（enableNative="{{true}}"）
2. **遇到兼容性问题再降级**到 always-system
3. **iOS 自动聚焦必须使用全同层**
4. **做好双端测试**，特别是键盘相关功能
5. **使用防抖优化输入性能**
