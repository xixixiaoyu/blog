## 邮件收发简介
除了微信外，邮件也是我们日常通讯的重要方式之一。那么，你平时是如何收发邮件的呢？

大多数人会使用邮箱客户端，如 QQ 邮箱，但这种方式的体验可能并不理想。例如：

1.  **编写邮件**： 
    - 想直接使用漂亮的 HTML 页面作为邮件内容。
    - 希望使用 Markdown 编写邮件。
    - 但 QQ 邮箱客户端仅支持富文本编辑器，功能有限。
2.  **接收邮件**： 
    - 想保存一些重要邮件的内容和附件。
    - 手动操作太麻烦，尤其当邮件数量较多时。



## 使用 Node.js 编程方式收发邮件
作为一名专业的 Node.js 程序员，我们可以使用代码更高效地处理邮件。邮件发送和接收分别使用不同的协议：

+ **发送邮件**：SMTP 协议。
+ **接收邮件**：POP3 或 IMAP 协议。

在 Node.js 中，可以使用 `nodemailer` 和 `imap` 两个包来分别处理邮件的发送和接收。



### 配置邮箱
首先，需要在邮箱中开启 SMTP 和 IMAP 服务，以 QQ 邮箱为例：

1. 登录 QQ 邮箱，进入邮箱帮助中心（service.mail.qq.com）。
2. 搜索并开启 SMTP 和 IMAP 服务。
3. 生成授权码，用于第三方应用登录。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1719076259110-cd1019e7-8455-40ef-9f89-0b36662548ef.png)



### 发送邮件
安装 `nodemailer`：

```bash
npm i nodemailer
```

使用 `nodemailer` 包发送邮件：

```typescript
const nodemailer = require('nodemailer')

// 创建一个 SMTP 传输对象，配置邮件服务信息
const transporter = nodemailer.createTransport({
    host: 'smtp.qq.com', // 邮件服务器地址，这里使用的是 QQ 邮箱的 SMTP 服务器
    port: 587, // SMTP 端口号
    secure: false, // 是否使用 TLS，false 表示不使用
    auth: {
        user: 'xxxxx@qq.com', // 发件人邮箱地址
        pass: '你的授权码', // 发件人邮箱的授权码（不是邮箱密码）
    },
})

// 定义一个异步函数 main，用于发送邮件
async function main() {
    // 使用 transporter 发送邮件，并等待发送结果
    const info = await transporter.sendMail({
        from: '"yun" <xxxx@qq.com>', // 发件人信息
        to: 'xxxx@xx.com', // 收件人邮箱地址
        subject: 'Hello 111', // 邮件主题
        text: 'xxxxx', // 邮件正文
    })

    // 打印邮件发送成功的信息，包括邮件 ID
    console.log('邮件发送成功：', info.messageId)
}

// 调用 main 函数，并捕获任何可能的错误
main().catch(console.error)
```

<font style="color:rgb(37, 41, 51);">运行代码：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1690007526053-711e099d-5073-4cb1-afa7-6dd6417bbe8f.png)

<font style="color:rgb(37, 41, 51);">可以看到邮件发送成功了，邮箱确实也能收到。</font>

<font style="color:rgb(37, 41, 51);">这样我们就用 node 发送了第一个邮件！</font>

<font style="color:rgb(37, 41, 51);">而且邮件是支持 html + css 的：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1690007896455-35811280-44eb-4d3e-9de0-94f5e8b9e34c.png)

<font style="color:rgb(37, 41, 51);">注意：邮件里可以包含任何 html+ css，但是不支持 js。</font>

如果要发<font style="color:rgb(37, 41, 51);"> markdown 格式，我们需要先将其转换为 html 格式发送即可。</font>

<font style="color:rgb(37, 41, 51);"></font>

### <font style="color:rgb(37, 41, 51);">接收邮件</font>
接收邮件时，使用 [imap](https://link.juejin.cn/?target=https%3A%2F%2Fwww.npmjs.com%2Fpackage%2Fimap) 包：

```typescript
const Imap = require('imap'); // 引入 imap 模块，用于连接和操作 IMAP 服务器
const { MailParser } = require('mailparser'); // 引入 mailparser 模块，用于解析邮件内容
const fs = require('fs');
const path = require('path');

// 配置 IMAP 连接信息
const imap = new Imap({
    user: 'xxx@qq.com', // 邮箱账号
    password: '你的授权码', // 授权码
    host: 'imap.qq.com', // IMAP 服务器地址
    port: 993, // IMAP 服务器端口
    tls: true // 使用 TLS 加密
});

// 当 IMAP 连接准备就绪时执行
imap.once('ready', () => {
    // 打开收件箱
    imap.openBox('INBOX', true, (err) => {
        if (err) throw err; // 如果发生错误，抛出异常
        // 搜索已读邮件，且邮件日期在 2023-07-10 19:00:00 之后
        imap.search([['SEEN'], ['SINCE', new Date('2023-07-10 19:00:00').toLocaleString()]], (err, results) => {
            if (err) throw err; // 如果发生错误，抛出异常
            handleResults(results); // 处理搜索结果 results 是数组，里面是邮箱id
        });
    });
});

// 处理搜索结果
function handleResults(results) {
    // 获取邮件内容
    imap.fetch(results, { bodies: '' }).on('message', (msg) => {
        const mailparser = new MailParser(); // 创建 MailParser 实例
        const info = {}; // 用于存储邮件信息

        // 当邮件主体部分被读取时执行
        msg.on('body', (stream) => {
            stream.pipe(mailparser); // 将邮件流传递给 mailparser 解析

            // 当解析到邮件头部信息时执行
            mailparser.on("headers", (headers) => {
                info.subject = headers.get('subject'); // 获取邮件主题
                info.from = headers.get('from').value[0].address; // 获取发件人邮箱地址
                info.fromName = headers.get('from').value[0].name; // 获取发件人名称
                info.to = headers.get('to').value[0].address; // 获取收件人邮箱地址
                info.date = headers.get('date').toLocaleString(); // 获取邮件发送日期
            });

            // 当解析到邮件内容时执行
            mailparser.on("data", (data) => {
                if (data.type === 'text') {
                    info.html = data.html; // 获取邮件 HTML 内容
                    info.text = data.text; // 获取邮件文本内容
                    const filePath = path.join(__dirname, 'mails', `${info.subject}.html`); // 构建保存路径
                    fs.writeFileSync(filePath, info.html || info.text); // 将邮件内容保存为 HTML 文件
                    console.log(info); // 打印邮件信息
                }
                if (data.type === 'attachment') {
                    const filePath = path.join(__dirname, 'files', data.filename); // 构建附件保存路径
                    const ws = fs.createWriteStream(filePath); // 创建写入流
                    data.content.pipe(ws); // 将附件内容写入文件
                }
            });
        });
    });
}

// 连接 IMAP 服务器
imap.connect();
```

<font style="color:rgb(37, 41, 51);">我们在本地创建个 files 和 mails 目录，然后运行上面代码。</font>

<font style="color:rgb(37, 41, 51);">可以看到，我们前面发的那两个邮件都取到了：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1690009247246-87edd8dc-9e6b-4e48-855a-3b6bac81f011.png)

<font style="color:rgb(37, 41, 51);">邮件内容和附件内容都会保存下来：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1690009748323-45d7e39a-4354-4ae3-8b6d-08fb2de56a25.png)

