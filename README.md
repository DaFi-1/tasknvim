# tasknvim

Um plugin simples e visual para o Neovim que transforma arquivos em listas de tarefas inteligentes, com contagem automática, destaque dinâmico e personalização completa de cores.

A simple and visual Neovim plugin that transforms files into smart task lists, with automatic counting, dynamic highlighting, and full color customization.

一个简单的可视化 Neovim 插件，将文件转换为智能任务列表，具有自动计数、动态高亮和完整颜色自定义功能。

## Introdução | Introduction | 介绍

TASKNVIM simplifica o gerenciamento de tarefas diretamente no Neovim. Crie um arquivo chamado TASKNVIM e organize suas tarefas em seções.

TASKNVIM simplifies task management directly inside Neovim. Create a file named TASKNVIM and organize your tasks with sections.

TASKNVIM 简化 Neovim 内的任务管理。创建一个名为 TASKNVIM 的文件，并按章节组织您的任务。

### Tipos de Tarefas | Task Types | 任务类型

| Tag | Nome (PT) | Name (EN) | 名称 (ZH) | Descrição (PT) | Description (EN) | 描述 (ZH) |
|-----|-----------|-----------|----------|----------------|------------------|----------|
| `[x]` | Concluída | Done | 已完成 | Tarefa completada | Completed task | 已完成的任务 |
| `[ ]` | Pendente | Pending | 待办 | Tarefa não iniciada | Task not started | 未开始的任务 |
| `[+]` | Em Progresso | In Progress | 进行中 | Tarefa sendo trabalhada | Task currently being worked on | 正在进行的任务 |
| `[!]` | Prioridade | Priority | 优先 | Tarefa importante | Important task | 重要任务 |
| `[>]` | Máx. Prioridade | Max Priority | 最高优先级 | Tarefa crítica | Critical/high priority task | 关键/高优先级任务 |
| `[@]` | Delegada | Delegated | 已委派 | Tarefa atribuída a outra pessoa | Task assigned to someone else | 分配给他人的任务 |
| `[?]` | Dúvida | Doubt | 疑问 | Tarefa incerta ou bloqueada | Uncertain or blocked task | 不确定或受阻的任务 |
| `[#]` | Bug | Bug | 缺陷 | Correção de bug | Bug fix task | 修复缺陷任务 |
| `[/]` | Refatoração | Refactor | 重构 | Refatoração de código | Code refactoring task | 代码重构任务 |
| `[*]` | Quebrada | Broken | 损坏 | Quebrada/precisa de correção | Broken/needs fix task | 损坏/需要修复的任务 |

### Funcionalidades | Features | 功能特性

* Criar listas de tarefas organizadas por seções (use `- título`)
* Contagem automática com `[feitas/progresso/pendentes/prioridade/max/delegadas/dúvida/bug/refatoração/quebradas/total]`
* Destaque colorido para badges e contadores
* Atualização automática ao ler e salvar o arquivo

* Create task lists organized by sections (use `- title`)
* Automatic task counting with `[done/progress/pending/priority/max/delegated/doubt/bug/refactor/broken/total]`
* Color-coded highlighting for badges and counters
* Auto-updates on file read and save

* 按章节创建任务列表（使用 `- 标题`）
* 自动任务计数，格式为 `[已完成/进行中/待办/优先/最高/委派/疑问/缺陷/重构/损坏/总计]`
* 标签和计数器的彩色高亮显示
* 读取和保存文件时自动更新

## Exemplo | Example | 示例

```txt
- Lua Project
  [x] Create structure
  [+] Implement logic
  [ ] Write README
```

Torna-se automaticamente | Automatically becomes | 自动变为:

```txt
- Lua Project [1/1/1/0/0/0/0/0/0/0/3]
```

Formato | Format | 格式: `[done/progress/pending/priority/max_priority/delegated/doubt/bug/refactor/broken/total]`

## Instalação | Installation | 安装

### Usando [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{"DaFi-1/tasknvim"}
```

## Licença | License | 许可证

MIT License | MIT License | MIT 许可证
