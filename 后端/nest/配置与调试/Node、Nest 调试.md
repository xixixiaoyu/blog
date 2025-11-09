首先我们新建运行一个 Nest 项目：

```bash
nest new -p debug-test -p pnpm --skip-git
cd debug-test
```

## 调试 node 单文件
点击左侧活动栏中的"运行和调试"图标，选择 "创建 launch.json 文件"：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746853277971-36446b68-cbc3-4798-9391-037b9b18dec0.png)

从下拉菜单中选择 "Node.js"：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746853592889-b45e6c78-3145-4b3c-af6e-9b3da917a909.png)

配置 **launch.json**：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746853707863-5a8e4747-6612-47de-a991-f3e08eacca65.png)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "调试当前文件",
      "program": "${file}",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

主要看 **program**: "${file}"，${file} 是一个 VS Code 变量，表示当前在编辑器中打开的活动文件。这意味着调试器会运行当前打开的 JavaScript 文件。

如果 "program": "${workspaceFolder}/index.js"，则指向工作区根目录下的 index.js 文件。

然后我们在当前目录创建 index.js，打上断点：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746861721317-9497c4f7-a90a-4c9c-809a-09010fb9a6f4.png)

```javascript
const sum = (a, b) => {
  return a + b;
};

sum(1, 2);
```

点击"运行和调试"面板中的绿色播放按钮：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746861767266-69ad89f9-fb15-4087-ab46-9c811277c695.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746861812371-5a476233-f43f-47d6-afd4-16ea25b4c95e.png)

可以看到已经走进 debug 界面了。



## 调试 Nest 项目
和上面初始化步骤一样，我们改下 launch.json 文件：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "调试 Nest.js 应用",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "start:debug"],
      "skipFiles": ["<node_internals>/**"],
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "console": "integratedTerminal",
      "sourceMaps": true
    }
  ]
}
```

+ runtimeArgs 是传递给 npm 的参数，相当于执行 npm run start:debug
+ "console":"integratedTerminal" 使用 VS Code 的集成终端显示输出

打个断点后点绿色播放按钮：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746864486329-4854d22a-7f40-44d3-90f5-b266c96dc916.png)

项目以 debug 启动了：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746864671938-df112699-9806-4833-b544-646097678a87.png)

访问下 [localhost:3000](http://localhost:3000)：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746864737236-c7904d60-8dd6-4e09-b362-9cd32a7d0834.png)

卡进断点了。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1747740546078-4c400a96-64d7-403e-859a-16cda35b6be6.png)

解释下这几个图标的意思（从左往右）：

+ **继续 (Continue) / 暂停 (Pause)**：如果程序当前已暂停（例如在断点处），点击此按钮将使程序继续执行，直到遇到下一个断点、程序结束或手动暂停。
+ **单步跳过 (Step Over)**：执行当前高亮行的代码。如果当前行包含一个函数调用，调试器会执行整个函数，然后停在调用该函数之后的下一行代码。它不会进入函数内部进行逐行调试。
+ **单步调试 (Step Into**)：执行当前高亮行的代码。如果当前行包含一个函数调用，调试器会进入该函数内部，并停在函数的第一行代码，允许你逐行调试函数内部的逻辑。
+ **单步跳出 (Step Out)**：如果你已经使用“单步调试 (Step Into)”进入了一个函数内部，点击此按钮将执行该函数余下的所有代码，然后返回到调用该函数的那一行代码之后的位置。
+ **重启 (Restart)**：停止当前的调试会话，并重新启动程序进行新一轮的调试。
+ **停止 (Stop)**：终止当前的调试会话并停止程序的执行。

