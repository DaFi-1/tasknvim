# tasknvim

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
