# AI Prompt: Go HTTP 服务器示例解析

请你为这个使用 Go 标准库 `net/http` 构建的基础 HTTP 服务器示例，撰写一篇清晰易懂的 README 文档。

本文档的目标是帮助初学者理解 Go 如何处理 HTTP 请求，并构建一个最简单的 Web 应用。

**文档核心内容应包括：**

1.  **示例概述**
    *   说明此示例将创建一个监听在 `8080` 端口的 HTTP 服务器。
    *   当用户访问根路径 (`/`) 时，服务器会响应 "Hello, Web!"。
    *   当用户访问任何其他路径时，服务器会返回一个 404 Not Found 错误。
    *   强调这是使用 Go 进行 Web 开发的入门基础。

2.  **代码剖析 (`main.go`)**
    *   逐行或按代码块解释其功能：
        *   `import ("fmt", "log", "net/http")`: 导入所需的标准库，`net/http` 是核心。
        *   `handler(w http.ResponseWriter, r *http.Request)`: 定义一个处理器函数 (Handler)。
            *   解释 `http.ResponseWriter` 和 `*http.Request` 这两个参数的作用。
            *   `fmt.Fprintf(w, "Hello, Web!")`: 如何向客户端写入响应。
        *   `func main()`: 程序主函数。
            *   `http.HandleFunc("/", handler)`: 注册处理器。解释这行代码如何将根路径 `/` 的所有请求都交给 `handler` 函数来处理。这被称为“路由”。
            *   `log.Fatal(http.ListenAndServe(":8080", nil))`: 启动服务器。解释 `:8080` 的含义，以及 `http.ListenAndServe` 如何阻塞并开始监听传入的 HTTP 请求。`log.Fatal` 用于在服务器启动失败时记录错误并退出程序。

3.  **如何运行与测试**
    *   **启动服务器**：
        ```bash
        # 在 http-server/ 目录下运行
        go run main.go
        ```
        *   提示用户此时终端会“卡住”，因为它正在等待请求。这表明服务器正在运行。
    *   **测试服务器**：
        *   **方法一：使用浏览器**
            *   打开你的 Web 浏览器，访问 `http://localhost:8080`。
            *   你应该会在页面上看到 "Hello, Web!"。
        *   **方法二：使用 cURL**
            *   打开一个新的终端，运行以下命令：
              ```bash
              curl http://localhost:8080
              ```
            *   你会在终端看到 "Hello, Web!" 的输出。
            *   尝试访问一个不存在的路径，观察 404 错误：
              ```bash
              curl http://localhost:8080/some/other/path
              ```

4.  **核心概念总结**
    *   **Handler (处理器)**: 一个函数或一个实现了 `http.Handler` 接口的类型，负责处理 HTTP 请求并生成响应。
    *   **ServeMux (多路复用器)**: 负责将收到的请求根据其 URL 路径匹配到对应的 Handler。`http.HandleFunc` 就是在默认的 ServeMux 上注册路由。
    *   **ListenAndServe**: 启动 HTTP 服务器的核心函数。

**总结要求：**

请确保文章内容准确，步骤清晰。重点解释 Go 标准库 `net/http` 的强大和简洁，激发读者使用 Go 进行 Web 开发的兴趣。

