# tasknvim

A simple and visual Neovim plugin that transforms files into smart task lists, with automatic counting, dynamic highlighting, and full color customization.

## Introduction

TASKNVIM simplifies task management directly inside Neovim. Create a file named TASKNVIM and organize your tasks with sections.

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

### Features

* Create task lists organized by sections (use `- title`)
* Automatic task counting with `[done/progress/pending/priority/max/delegated/doubt/bug/refactor/broken/total]`
* Color-coded highlighting for badges and counters
* Auto-updates on file read and save

## Example

```txt
- Lua Project
  [x] Create structure
  [+] Implement logic
  [ ] Write README
```

Automatically becomes:

```txt
- Lua Project [1/1/1/0/0/0/0/0/0/0/3]
```

Format: `[done/progress/pending/priority/max/delegated/doubt/bug/refactor/broken/total]`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{"DaFi-1/tasknvim"}
```

## License

MIT License
