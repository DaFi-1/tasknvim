# tasknvim

<style>
.lang-pt, .lang-en, .lang-zh { display: none; }
#lang-pt:checked ~ .lang-pt { display: block; }
#lang-en:checked ~ .lang-en { display: block; }
#lang-zh:checked ~ .lang-zh { display: block; }
input[type="radio"] { display: none; }
label { cursor: pointer; padding: 5px 10px; margin: 0 5px; border: 1px solid #ccc; display: inline-block; }
#lang-pt:checked ~ label[for="lang-pt"],
#lang-en:checked ~ label[for="lang-en"],
#lang-zh:checked ~ label[for="lang-zh"] { background: #007bff; color: white; }
</style>

<input type="radio" name="lang" id="lang-pt" checked>
<input type="radio" name="lang" id="lang-en">
<input type="radio" name="lang" id="lang-zh">

<label for="lang-pt">Português</label>
<label for="lang-en">English</label>
<label for="lang-zh">中文</label>

---

<div class="lang-pt">

Um plugin simples e visual para o Neovim que transforma arquivos em listas de tarefas inteligentes, com contagem automática, destaque dinâmico e personalização completa de cores.

## Introdução

TASKNVIM simplifica o gerenciamento de tarefas diretamente no Neovim. Crie um arquivo chamado TASKNVIM e organize suas tarefas em seções.

### Tipos de Tarefas

| Tag | Nome | Descrição |
|-----|------|-----------|
| `[x]` | Concluída | Tarefa completada |
| `[ ]` | Pendente | Tarefa não iniciada |
| `[+]` | Em Progresso | Tarefa sendo trabalhada |
| `[!]` | Prioridade | Tarefa importante |
| `[>]` | Máx. Prioridade | Tarefa crítica |
| `[@]` | Delegada | Tarefa atribuída a outra pessoa |
| `[?]` | Dúvida | Tarefa incerta ou bloqueada |
| `[#]` | Bug | Correção de bug |
| `[/]` | Refatoração | Refatoração de código |
| `[*]` | Quebrada | Quebrada/precisa de correção |

### Funcionalidades

* Criar listas de tarefas organizadas por seções (use `- título`)
* Contagem automática com `[feitas/progresso/pendentes/prioridade/max/delegadas/dúvida/bug/refatoração/quebradas/total]`
* Destaque colorido para badges e contadores
* Atualização automática ao ler e salvar o arquivo

## Exemplo

```txt
- Lua Project
  [x] Create structure
  [+] Implement logic
  [ ] Write README
```

Torna-se automaticamente:

```txt
- Lua Project [1/1/1/0/0/0/0/0/0/0/3]
```

Formato: `[feitas/progresso/pendentes/prioridade/max/delegadas/dúvida/bug/refatoração/quebradas/total]`

## Instalação

### Usando [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{"DaFi-1/tasknvim"}
```

## Licença

MIT License

</div>

<div class="lang-en">

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

</div>

<div class="lang-zh">

一个简单的可视化 Neovim 插件，将文件转换为智能任务列表，具有自动计数、动态高亮和完整颜色自定义功能。

## 介绍

TASKNVIM 简化 Neovim 内的任务管理。创建一个名为 TASKNVIM 的文件，并按章节组织您的任务。

### 任务类型

| Tag | 名称 | 描述 |
|-----|------|------|
| `[x]` | 已完成 | 已完成的任务 |
| `[ ]` | 待办 | 未开始的任务 |
| `[+]` | 进行中 | 正在进行的任务 |
| `[!]` | 优先 | 重要任务 |
| `[>]` | 最高优先级 | 关键/高优先级任务 |
| `[@]` | 已委派 | 分配给他人的任务 |
| `[?]` | 疑问 | 不确定或受阻的任务 |
| `[#]` | 缺陷 | 修复缺陷任务 |
| `[/]` | 重构 | 代码重构任务 |
| `[*]` | 损坏 | 损坏/需要修复的任务 |

### 功能特性

* 按章节创建任务列表（使用 `- 标题`）
* 自动任务计数，格式为 `[已完成/进行中/待办/优先/最高/委派/疑问/缺陷/重构/损坏/总计]`
* 标签和计数器的彩色高亮显示
* 读取和保存文件时自动更新

## 示例

```txt
- Lua Project
  [x] Create structure
  [+] Implement logic
  [ ] Write README
```

自动变为:

```txt
- Lua Project [1/1/1/0/0/0/0/0/0/0/3]
```

格式: `[已完成/进行中/待办/优先/最高/委派/疑问/缺陷/重构/损坏/总计]`

## 安装

### 使用 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{"DaFi-1/tasknvim"}
```

## 许可证

MIT 许可证

</div>
