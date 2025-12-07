# 核心基础

学习目标
- 了解 Node.js 架构、单线程事件驱动模型与 libuv
- 掌握模块系统（CommonJS 与 ESM）、异步编程（callback/promise/async/await）
- 熟悉 Buffer、Stream、EventEmitter、错误处理、进程与线程

知识点清单
- Node.js 运行时与 V8、libuv、C++ bindings
- 事件循环阶段与任务队列（microtask 与 macrotask）
- 模块系统（require 与 import、ts-node/tsx）
- Buffer、Stream（可读/可写/转换）、背压与高水位线
- EventEmitter 模式与自定义事件
- 错误处理（同步/异步、Domain 已废弃、集中错误处理）
- child_process、worker_threads 与多进程/多线程模型

实践建议
- 编写一个展示 event loop 阶段差异的示例
- 实现一个基于 stream 的大文件拷贝与限速
- 使用 worker_threads 执行 CPU 密集任务（如哈希计算）

