## 为什么用 Node.js 处理邮件？

在日常工作中，除了即时通讯工具，邮件依然是不可或缺的沟通方式。但传统的邮件客户端，如 QQ 邮箱或 Outlook，在处理特定需求时常常显得力不从心：

- **自动化与定制化**：无法通过编程方式自动发送定制化内容的邮件，例如发送动态生成的报告、数据报表或包含精美 HTML 模板的通知。
- **批量处理**：当需要自动归档、解析大量邮件内容或下载附件时，手动操作变得极其繁琐且低效。

作为 Node.js 开发者，我们可以利用代码的力量，将这些重复性工作自动化，从而极大地提升效率。本文将详细介绍如何使用 Node.js 实现邮件的发送与接收。

## 核心概念：邮件协议

在深入代码之前，我们需要了解邮件系统背后的核心协议：


- **SMTP (Simple Mail Transfer Protocol)**：简单邮件传输协议，是发送邮件的标准协议。当你发送一封邮件时，你的邮件客户端或服务器就是通过 SMTP 将邮件推送到收件人的邮件服务器。

- **POP3 (Post Office Protocol 3)**：邮局协议第 3 版，用于从邮件服务器上**下载**邮件到本地设备。邮件下载后，通常会从服务器上删除（取决于客户端设置）。它适合在单一设备上管理邮件。

- **IMAP (Internet Message Access Protocol)**：互联网消息访问协议，与 POP3 不同，IMAP 允许你**在服务器上直接管理**邮件。所有操作（如阅读、删除、移动）都会与服务器同步，因此你可以在多个设备上看到一致的邮件状态。这是目前更主流的接收协议。

在 Node.js 生态中，我们可以借助强大的第三方库来轻松地与这些协议交互：

- **发送邮件 (SMTP)**：使用 `nodemailer` 库。
- **接收邮件 (IMAP)**：使用 `imap` 库（及其配套的解析工具）。



### 配置邮箱
首先，需要在邮箱中开启 SMTP 和 IMAP 服务，以 QQ 邮箱为例：

1. 登录 QQ 邮箱，进入邮箱帮助中心（service.mail.qq.com）。
2. 搜索并开启 SMTP 和 IMAP 服务。
3. 生成授权码，用于第三方应用登录。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1719076259110-cd1019e7-8455-40ef-9f89-0b36662548ef.png)



### 步骤 1：安装 Nodemailer

首先，安装 `nodemailer` 库：

```bash
npm install nodemailer
```

### 步骤 2：编写发送脚本

以下是一个使用 `nodemailer` 发送邮件的示例。为了使其可运行，请确保你的项目 `package.json` 中已设置 `"type": "module"`，以便使用 ES Module 语法。

```typescript
import nodemailer from 'nodemailer'

// 1. 创建一个 SMTP 传输器对象
const transporter = nodemailer.createTransport({
  host: 'smtp.qq.com', // 邮箱服务的主机，例如 'smtp.qq.com'
  port: 587, // SMTP 端口，常用的有 465 和 587
  secure: false, // 如果端口为 465，则设为 true；其他端口通常为 false
  auth: {
    user: process.env.EMAIL_USER, // 发件人邮箱账号，建议使用环境变量
    pass: process.env.EMAIL_PASS, // 邮箱授权码，而非原始密码，建议使用环境变量
  },
})

// 2. 定义邮件内容
const mailOptions = {
  from: '"Your Name" <your-email@qq.com>', // 发件人信息
  to: 'recipient@example.com', // 收件人列表，多个用逗号隔开
  subject: 'Hello from Node.js', // 邮件主题
  text: '这是一封纯文本邮件。', // 纯文本正文
  html: '<b>这是一封 HTML 邮件。</b>', // HTML 正文
}

// 3. 发送邮件
async function sendMail() {
  try {
    const info = await transporter.sendMail(mailOptions)
    console.log('邮件发送成功:', info.messageId)
  } catch (error) {
    console.error('邮件发送失败:', error)
  }
}

sendMail()

1.  **创建传输器 (Transporter)**：`nodemailer.createTransport` 用于创建一个传输器实例，它负责建立到邮件服务器的连接。你需要提供服务器的主机（`host`）、端口（`port`）以及认证信息（`auth`）。
2.  **安全建议**：强烈建议不要将邮箱账号和授权码硬编码在代码中。最佳实践是使用环境变量（如 `process.env.EMAIL_USER`）来管理这些敏感信息，以避免泄露。
3.  **定义邮件内容 (Mail Options)**：你可以定义邮件的各个部分，包括发件人、收件人、主题、纯文本正文（`text`）和 HTML 正文（`html`）。如果同时提供了 `text` 和 `html`，邮件客户端会优先显示 `html` 版本。
4.  **发送邮件**：调用 `transporter.sendMail()` 方法并传入邮件内容，即可完成发送。

运行代码后，你会在控制台看到发送成功的消息，并且目标邮箱会收到一封格式精美的 HTML 邮件。

### 扩展：发送 Markdown 内容

邮件本身不支持 Markdown，但我们可以先将 Markdown 转换为 HTML，再进行发送。这需要一个额外的库，例如 `markdown-it`。

1.  **安装 `markdown-it`**:

    ```bash
    npm install markdown-it
    ```

2.  **转换并发送**:

    ```typescript
    import MarkdownIt from 'markdown-it'
    const md = new MarkdownIt()

    const markdownContent = `
    # 这是一级标题
    - 列表项 1
    - 列表项 2
    `
    const htmlContent = md.render(markdownContent)

    const mailOptionsWithMarkdown = {
      // ...其他选项
      html: htmlContent, // 将转换后的 HTML 作为邮件内容
    }

    // 使用之前的 transporter 发送邮件
    // transporter.sendMail(mailOptionsWithMarkdown)
    ```

这样，你就可以轻松地使用 Markdown 编写邮件内容了。

## 接收邮件

接收邮件比发送更复杂，因为它涉及到与 IMAP 服务器的持续交互、邮件的搜索、抓取和解析。我们将使用 `imap` 和 `mailparser` 这两个库。

### 步骤 1：安装依赖

```bash
npm install imap mailparser
```

### 步骤 2：编写接收脚本

以下是一个完整的邮件接收与解析脚本。同样，请确保你的项目已配置为使用 ES Module。

```typescript
import Imap from 'imap'
import { simpleParser } from 'mailparser'
import fs from 'fs'
import path from 'path'

// 确保 mails 和 files 目录存在
const mailsDir = path.join(process.cwd(), 'mails')
const filesDir = path.join(process.cwd(), 'files')
const ensureDir = (p) => {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true })
}
ensureDir(mailsDir)
ensureDir(filesDir)

// 1. 配置 IMAP 连接信息
const imapConfig = {
  user: process.env.EMAIL_USER, // 邮箱账号
  password: process.env.EMAIL_PASS, // 授权码
  host: 'imap.qq.com', // IMAP 服务器地址
  port: 993, // IMAP 端口
  tls: true, // 明确启用 TLS 加密
}

const imap = new Imap(imapConfig)

// 2. 监听连接事件

imap.once('ready', () => {
  console.log('IMAP 连接成功')
  openInbox()
})

imap.once('error', (err) => {
  console.error('IMAP 连接错误:', err)
})

imap.once('end', () => {
  console.log('IMAP 连接已断开')
})

// 3. 打开收件箱并搜索邮件
function openInbox() {
  imap.openBox('INBOX', false, (err, box) => {
    if (err) throw err
    console.log('收件箱已打开，总邮件数:', box.messages.total)

    // 搜索所有未读邮件
    imap.search(['UNSEEN'], (err, results) => {
      if (err || !results || results.length === 0) {
        console.log('没有找到未读邮件')
        imap.end()
        return
      }

      console.log(`找到 ${results.length} 封未读邮件`)
      fetchEmails(results)
    })
  })
}

// 4. 抓取并解析邮件
function fetchEmails(results) {
  const fetch = imap.fetch(results, { bodies: '' })

  fetch.on('message', (msg, seqno) => {
    console.log(`正在处理邮件 #${seqno}`)

    msg.on('body', (stream) => {
      // 使用 simpleParser 解析邮件流
      simpleParser(stream, async (err, parsed) => {
        if (err) {
          console.error('邮件解析失败:', err)
          return
        }

        // 保存邮件内容
        const safe = (s) => (s || '').replace(/[\\/:*?"<>|]/g, '').slice(0, 100).trim() || `mail_${seqno}`
        const mailPath = path.join(mailsDir, `${safe(parsed.subject)}.html`)
        fs.writeFileSync(mailPath, parsed.html || parsed.textAsHtml || parsed.text || '')
        console.log(`邮件内容已保存到: ${mailPath}`)

        // 处理附件
        if (parsed.attachments && parsed.attachments.length > 0) {
          handleAttachments(parsed.attachments, seqno)
        }
      })
    })

    msg.once('end', () => {
      console.log(`邮件 #${seqno} 处理完毕`)
    })
  })

  fetch.once('error', (err) => {
    console.error('抓取邮件时出错:', err)
  })

  fetch.once('end', () => {
    console.log('所有邮件处理完毕')
    imap.end() // 关闭连接
  })
}

// 5. 处理附件
function handleAttachments(attachments, seqno) {
  const safe = (s) => (s || '').replace(/[\\/:*?"<>|]/g, '').slice(0, 100).trim()
  attachments.forEach((attachment) => {
    const name = safe(attachment.filename || `attachment_${seqno}`)
    const filePath = path.join(filesDir, name)
    fs.writeFileSync(filePath, attachment.content)
    console.log(`附件已保存到: ${filePath}`)
  })
}

// 启动连接
imap.connect()

## 总结与最佳实践

通过本文，我们学习了如何使用 Node.js 和 `nodemailer`、`imap` 等库来实现邮件的自动发送与接收。为了在实际项目中更专业、更安全地应用这些技术，请遵循以下最佳实践：

1.  **凭证管理是第一要务**
    *   **严禁硬编码**：绝不要将邮箱密码或授权码直接写入代码。
    *   **使用环境变量**：至少应使用环境变量（`process.env`）来存储敏感信息。
    *   **生产环境方案**：在生产环境中，推荐使用更安全的凭证管理服务，如 HashiCorp Vault、AWS Secrets Manager 或云服务商提供的配置中心。

2.  **健壮的错误处理**
    *   对于所有异步操作（如 `sendMail`、`imap.connect`），都应使用 `try...catch` 或 `.catch()` 来捕获潜在的异常。
    *   为 `imap` 等事件驱动的库绑定 `error` 事件监听器，以处理连接或操作过程中可能出现的任何问题。

3.  **优雅地管理连接**
    *   在使用 `imap` 接收邮件后，务必调用 `imap.end()` 来正常关闭连接，释放服务器和本地资源。
    *   对于需要长时间运行的邮件接收服务，可以设计心跳机制或定时重连逻辑，以应对网络波动或服务器断开连接的情况。

4.  **代码的模块化**
    *   将邮件发送、接收和配置逻辑拆分到不同的模块中。例如，可以创建一个 `emailService.js` 文件，统一封装所有与邮件相关的功能，使主业务逻辑更清晰。

5.  **生产环境的考量**
    *   **发送频率限制**：个人邮箱（如 QQ、Gmail）的 SMTP 服务通常有严格的发送频率限制，不适合大规模发送。
    *   **专业邮件服务**：对于需要大量发送邮件（如营销邮件、系统通知）的应用，强烈建议使用专业的第三方邮件发送服务（ESP），例如 SendGrid、Mailgun 或 Amazon SES。这些服务提供了更高的发送成功率、详细的统计分析和更好的反垃圾邮件策略。
    *   **异步处理**：对于邮件发送请求，应将其放入消息队列（如 RabbitMQ、Redis）中异步处理，避免阻塞主应用流程，提高系统的响应速度和可靠性。


**代码解释：**

1.  **IMAP 配置**：与 `nodemailer` 类似，我们创建一个配置对象，包含用户、授权码、服务器地址等信息，并同样建议使用环境变量。
2.  **事件监听**：`imap` 库是事件驱动的。我们主要监听 `ready`（连接成功）、`error`（发生错误）和 `end`（连接关闭）事件。
3.  **打开收件箱**：连接成功后，使用 `imap.openBox()` 打开指定的邮箱（`'INBOX'` 通常是收件箱）。
4.  **搜索邮件**：`imap.search()` 允许你根据特定条件搜索邮件。示例中，我们搜索所有未读邮件（`'UNSEEN'`）。你也可以使用更复杂的条件，例如按发件人、日期等进行搜索。
5.  **抓取与解析**：
    *   `imap.fetch()` 用于抓取搜索结果对应的邮件内容。
    *   我们监听 `message` 事件，对每一封邮件进行处理。
    *   邮件的原始数据是一个流（`stream`），我们将其传递给 `mailparser` 的 `simpleParser` 函数进行解析。
    *   `simpleParser` 会返回一个结构化的 `parsed` 对象，其中包含了邮件的主题、正文（HTML 和纯文本）、附件等所有信息。
6.  **保存内容与附件**：解析成功后，我们可以轻松地将邮件的 HTML 内容和附件保存到本地文件系统中。
7.  **关闭连接**：完成所有操作后，务必调用 `imap.end()` 来正常关闭与服务器的连接。
