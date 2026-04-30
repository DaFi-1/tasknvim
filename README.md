![plugin logo](./res/logo.png)

A simple and visual Neovim plugin that transforms files into smart task lists, with **automatic counting**, **dynamic highlighting**, and **full color customization**.

## 🚀 Introduction

**TASKNVIM** is a versatile task management plugin for Neovim, designed to organize tasks, todo-lists, project checklists, and any system requiring structured task tracking.<br>
Whether you're managing personal todos, team projects, bug tracking, or any organizational workflow, create a file called **TASKNVIM** and start organizing.

With it you can:

### Task Types

| Tag | Name | Description | Color |
|-----|------|-------------|-------|
| `[x]` | Done | completed task | <div style="width:20px;height:20px;background:#00FF00"></div> |
| `[ ]` | Pending | priority level 1 task | <div style="width:20px;height:20px;background:#FF0000"></div> |
| `[+]` | In Progress | task in progress | <div style="width:20px;height:20px;background:#0000FF"></div> |
| `[!]` | Priority | priority level 2 task | <div style="width:20px;height:20px;background:#FF00FF"></div> |
| `[>]` | Max Priority | priority level 3 task | <div style="width:20px;height:20px;background:#FFA500"></div> |
| `[@]` | Delegated | task assigned to someone (NAME) | <div style="width:20px;height:20px;background:#00FFFF"></div> |
| `[?]` | Doubt | question task (question) | <div style="width:20px;height:20px;background:#FFFF00"></div> |
| `[#]` | Bug | bug task | <div style="width:20px;height:20px;background:#FF4444"></div> |
| `[/]` | Refactor | refactoring task | <div style="width:20px;height:20px;background:#E040FB"></div> |
| `[*]` | Broken | broken code task | <div style="width:20px;height:20px;background:#8B0000"></div> |

![image0](./res/image.png)
![image1](./res/image1.png)
---

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{"DaFi-1/tasknvim"}
```
---

## 📄 License

This project is licensed under the MIT License.
