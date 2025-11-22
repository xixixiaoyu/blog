URL（网址）就像一个标准的信封地址，有固定的格式：`国家-省份-城市-街道-门牌号`。这个格式里的 `-` 是有特殊意义的，它是一个分隔符。

你想在“城市”这个字段里写一个名字，比如 `A-B-C`。如果你直接写上去，收信人（服务器）可能会困惑，它不知道这个 `-` 是城市名字的一部分，还是分隔符。

`encodeURIComponent` 是 JavaScript 的一个全局函数，它的作用是**对 URI（统一资源标识符）的某个“组件”进行编码**。它通过将特定字符替换为百分号（`%`）开头的十六进制转义序列，来确保这些字符在 URL 中能够安全传输，而不会破坏 URL 的原有结构。

这个“打包”过程的专业术语叫做 **百分号编码**。



假设我们有一个搜索功能，用户想搜索关键词 `C++ & Java`。

如果我们直接把这个关键词拼接到 URL 上，可能会是这样：
`https://example.com/search?q=C++ & Java`

这个 URL 是有问题的：

1. `+` 号在某些情况下会被服务器解释为空格。
2. `&` 是 URL 查询参数的分隔符！服务器会认为这里有两个参数：`q=C++` 和一个空的 `Java=`。这完全曲解了用户的意图。

现在，我们用 `encodeURIComponent` 来“打包”这个关键词：

```javascript
const keyword = 'C++ & Java'
const safeKeyword = encodeURIComponent(keyword)
console.log(safeKeyword)
// 输出: C%2B%2B%20%26%20Java
```

我们来拆解一下这个“打包”结果：

- `+` 被编码成了 `%2B`
- 空格被编码成了 `%20`
- `&` 被编码成了 `%26`

现在，我们再把打包后的安全字符串拼接到 URL 上：
`https://example.com/search?q=C%2B%2B%20%26%20Java`

这个 URL 是清晰、无歧义的。服务器收到后，会准确地知道参数 `q` 的值是 `C++ & Java`，然后正确地进行搜索。在服务器端，通常有对应的解码函数来还原原始数据。



`encodeURIComponent` 并不是把所有字符都编码了。它遵循 RFC 3986 标准，认为以下字符是 URL 组件中的“安全字符”，因此**不会**对它们进行编码：

- 字母 `a-z`, `A-Z`
- 数字 `0-9`
- 符号 `- _ . ! ~ * ' ( )`

除了这些，其他所有字符（包括 `/`, `?`, `:`, `@`, `&`, `=`, `+`, `,`, `#` 等）都会被编码。



注意：

- `encodeURI`：用于编码**整个 URL**。它假设你给的是一个完整的、合法的 URL 地址。因此，它会保留那些对 URL 结构有特殊意义的字符，比如 `?`, `&`, `/`, `:`, `#` 等。它只编码那些在 URL 中“不合法”的字符（比如空格）。
- `encodeURIComponent`：用于编码 URL 的**一个组成部分**（比如查询参数的值、路径中的一段）。它假设这个组件是要被“塞”进 URL 结构里的，所以它会“毫不留情”地编码几乎所有特殊字符，以确保它不会“越界”破坏结构。

| 函数                 | 职责                    | 不编码的字符示例                | 使用场景                                               |
| :------------------- | :---------------------- | :------------------------------ | :----------------------------------------------------- |
| `encodeURI`          | 编码**完整**的 URI      | `?`, `&`, `/`, `:`, `#`         | 当你有一个完整的 URL，但里面可能包含空格等非法字符时。 |
| `encodeURIComponent` | 编码 URI 的**一个组件** | `A-Z a-z 0-9 - _ . ! ~ * ' ( )` | 当你要把用户输入或动态数据作为**值**拼接到 URL 中时。  |

看下代码：

```javascript
const url = 'https://example.com/search?q=C++ Tutorial & Guide'

// 使用 encodeURI：它保留了 ? 和 &
console.log(encodeURI(url))
// 输出: https://example.com/search?q=C++%20Tutorial%20&%20Guide
// 注意：这里的 & 仍然是分隔符，可能会引起问题！

// 使用 encodeURIComponent：它把所有特殊字符都编码了
console.log(encodeURIComponent(url))
// 输出: https%3A%2F%2Fexample.com%2Fsearch%3Fq%3DC%2B%2B%20Tutorial%20%26%20Guide
// 这个结果本身已经不是一个有效的 URL 了，但它可以作为另一个 URL 的参数值。
```

**结论：** 在 99% 的前端开发场景中，当你需要将动态数据拼接到 URL 的查询字符串或路径中时，**你应该使用 `encodeURIComponent`**。



### 实际应用与解码

**1. 构建查询字符串**：最常见用法

```javascript
const params = {
  keyword: 'A & B',
  page: 1,
  filter: 'price>100'
}

const queryString = Object.keys(params)
  .map(key => `${key}=${encodeURIComponent(params[key])}`)
  .join('&')

console.log(queryString)
// 输出: keyword=A%20%26%20B&page=1&filter=price%3E100

const fullUrl = `https://api.example.com/data?${queryString}`
console.log(fullUrl)
// 输出: https://api.example.com/data?keyword=A%20%26%20B&page=1&filter=price%3E100
```

**2. 解码：`decodeURIComponent`**：有编码就有解码。在浏览器端，通常你不需要手动解码，浏览器会自动处理。但在 Node.js 等服务端环境，你可能需要手动解码。

```javascript
const encodedStr = 'A%20%26%20B'
const originalStr = decodeURIComponent(encodedStr)
console.log(originalStr)
// 输出: A & B
```



### 总结

让我们用几句话来概括这个函数的精髓：

- **本质**：一个“数据打包员”，确保你的数据能安全地在 URL 中旅行。
- **目的**：防止数据中的特殊字符（如 `&`, `?`, `=`）破坏 URL 的结构。
- **核心区别**：`encodeURIComponent` 打包“零件”（组件），`encodeURI` 检查“整机”（完整 URL）。
- **黄金法则**：只要是把**动态内容**作为 URL 的**一部分**（尤其是参数值），就果断使用 `encodeURIComponent`。





