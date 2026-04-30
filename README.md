# 📝 tasknvim
![plugin logo](./res/logo.png)

A simple and visual Neovim plugin that transforms files into smart task lists, with **automatic counting**, **dynamic highlighting**, and **full color customization**.

## 🚀 Introduction

**TASKNVIM** is a versatile task management plugin for Neovim, designed to organize tasks, todo-lists, project checklists, and any system requiring structured task tracking.<br>
Whether you're managing personal todos, team projects, bug tracking, or any organizational workflow, create a file called **TASKNVIM** and start organizing.

With it you can:

### Task Types

| Tag | Name | Description |
|-----|------|-------------|
| `[x]` | Done | Completed task |
| `[ ]` | Pending | Task not started |
| `[+]` | In Progress | Task currently being worked on |
| `[!]` | Priority | Important task |
| `[>]` | Max Priority | Critical/high priority task |
| `[@]` | Delegated | Task assigned to someone else |
| `[?]` | Doubt | Uncertain or blocked task |
| `[#]` | Bug | Bug fix task |
| `[/]` | Refactor | Code refactoring task |
| `[*]` | Broken | Broken/needs fix task |

![image0](./res/image.png)
![image1](./res/image1.png)

---

### ✨ Example

```txt
- Lua Project
  [x] Create structure
  [+] Implement logic
  [ ] Write README
```

⬇️ Automatically becomes:

```txt
- Lua Project [1/1/1/0/0/0/0/0/0/0/3]
```

---

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{"DaFi-1/tasknvim"}
```

---

## ⚙️ Configuration & Usage

The plugin uses a custom file type.  
Use files named `TASKNVIM` to automatically enable it.

---

### 🎨 Default Colors

| Tag      | Name      | Badge Color         | Counter Color     |
|----------|-----------|---------------------|-------------------|
| `[x]`    | Done      | Green `#00FF00`     | Green `#00FF00`   |
| `[ ]`    | Pending   | Red `#FF0000`       | Red `#FF0000`     |
| `[+]`    | In prog.  | Blue `#0000FF`      | Blue `#0000FF`    |
| `[!]`    | Priority  | Magenta `#FF00FF`   | Magenta `#FF00FF` |
| `[>]`    | Max Prior.| Orange `#FFA500`    | Orange `#FFA500`  |
| `[@]`    | Delegated | Cyan `#00FFFF`      | Cyan `#00FFFF`    |
| `[?]`    | Doubt     | Yellow `#FFFF00`    | Yellow `#FFFF00`  |
| `[#]`    | Bug       | Red `#FF4444`       | Red `#FF4444`     |
| `[/]`    | Refactor  | Purple `#E040FB`    | Purple `#E040FB`  |
| `[*]`    | Broken    | DarkRed `#8B0000`   | DarkRed `#8B0000` |

---

## 📄 License

This project is licensed under the MIT License.
