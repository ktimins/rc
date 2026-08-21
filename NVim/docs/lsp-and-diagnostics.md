# Language servers, completion and diagnostics

## Which servers run where

| Server | Attaches to | Gives you |
|---|---|---|
| roslyn | `cs` | Full C# analysis, the same engine Visual Studio uses |
| lemminx | `xml` `xsd` `xsl` `xslt` `xaml` `svg` | Schema validation, completion from the XSD |
| jsonls | `json` `jsonc` | Schema validation from schemastore.org |
| ltex_plus | `markdown` `text` `gitcommit` `tex` `rst` `asciidoc` | Grammar and spelling |

`:LspInfo` shows what is attached to the current buffer. `:LspRestart` restarts it. `:Mason` manages the server binaries.

## Navigation and refactoring

Neovim's built-in LSP mappings. They work in any buffer with a server attached.

| Key | Does |
|---|---|
| `K` | Hover: signature and documentation |
| `<C-]>` | Go to definition |
| `grr` | Find references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `grn` | Rename across the project |
| `gra` | Code action |
| `grx` | Run code lens |
| `gO` | Document symbols |
| `<C-x><C-o>` | Omni-completion, when you want it explicitly |

`gd` is **not** an LSP mapping. It is Vim's lexical "go to local declaration", which is a different and much dumber thing. Use `<C-]>`.

The `gr` prefix is a Neovim 0.11 default and reads as "go, reference-ish". They are worth learning as a group.

## Completion

Completion appears as you type, with documentation alongside.

| Key | Does |
|---|---|
| `<C-y>` | Accept the selected item |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<C-e>` | Dismiss |
| `<C-space>` | Open the menu, or show documentation |
| `<Tab>` / `<S-Tab>` | Move through snippet placeholders |

`<C-y>` for accept rather than Enter is deliberate: Enter stays a newline, so completion never hijacks it.

Sources, in priority order: the language server, file paths, snippets, then words from open buffers. SQL buffers swap in live database completion instead; see [database.md](database.md).

Snippets come from the friendly-snippets collection, which finally makes the snippet definitions that sat unusable in gVim for years actually work, since no snippet engine was ever installed there.

## Diagnostics

| Key | Does |
|---|---|
| `]d` / `[d` | Next / previous diagnostic |
| `]D` / `[D` | Last / first in the buffer |
| `<C-w>d` | Show the full message under the cursor in a float |
| `gra` | Code action, often the fix |

Diagnostics appear as gutter signs and inline virtual text. Grammar findings from ltex are set to `hint` severity so prose suggestions do not sit in the list looking like compile errors.

## The Trouble panel

The structured list view. The nearest equivalent to Visual Studio's Error List.

| Key | Shows |
|---|---|
| `,ld` | Every diagnostic in the project |
| `,lb` | Diagnostics in this buffer only |
| `,ls` | Symbols, as a navigable tree |
| `,lr` | References and definitions, in a side panel |
| `,lq` | The quickfix list |
| `,ll` | The location list |

Inside the panel: `<CR>` to jump, `o` to jump and close, `q` to close, `?` for its own help.

`,ld` after a solution finishes loading is the "what is broken right now" view.

## Progress

Server activity shows in the corner. This matters most with Roslyn, which takes real time to load a large solution and would otherwise leave the editor looking dead and unresponsive while it works.

## Formatting

| Key | Does |
|---|---|
| `,cf` | Format the buffer, or the selection in visual mode |

| Filetype | Formatter |
|---|---|
| `cs` | csharpier |
| `json` | jq |
| `xml` | xmllint |

Falls back to the language server's own formatter when no external one is configured. `:ConformInfo` shows what applies to the current buffer and whether the binary was found.

Formatting is **on demand, never on save**, which is deliberate: a formatter that reflows a file you only meant to touch one line of makes for noisy diffs.

## Adding a server

```
:Mason                          " browse and install, press i on a package
:MasonInstall lua-language-server
```

Then add a `vim.lsp.config(...)` and `vim.lsp.enable(...)` block in `lua/plugins/lsp.lua`, following the ones already there. Neovim 0.11+ has this natively, so nvim-lspconfig is not needed.
