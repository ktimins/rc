# Searching, replacing and the quickfix list

## Searching

| Key | Does |
|---|---|
| `/` `?` | Search, translated to Colemak as you type |
| `*` / `#` | (visual) Search for the selected text |
| `,<CR>` or `,n` | Clear the highlight |
| `,fg` | Live grep across the project |
| `,fa` | Quickfix every match of a pattern in this file |

Search is case-insensitive until you type a capital, at which point it becomes case-sensitive. `:%s/old/new/g` previews live as you type the pattern, so you see what will change before committing.

Visual `*` searches for exactly the selected text, escaped correctly. In gVim this was broken for years: it called a function that was never defined anywhere.

## Project-wide replace

| Key | Does |
|---|---|
| `,rr` | Open find and replace |
| `,rw` | Prefilled with the word under the cursor |
| `,rf` | Restricted to the current file |
| `,rs` | (visual) Prefilled with the selection |

This is the Ctrl+Shift+H equivalent. A buffer opens with fields for search, replace and file scope. Every match is listed live with its context as you type, and nothing is written until you apply. Edit the replacement, see the effect, then commit.

Inside the buffer: `<C-Enter>` applies, `?` shows its help.

The plugin-free alternative, if you prefer it:

```
:grep pattern                       " ripgrep, results into quickfix
:cfdo s/pattern/replacement/g | update
```

That works but shows you nothing before it happens, which is why the preview version exists.

## The quickfix list

A list of file positions. Build errors, grep results and reference searches all land here.

| Key | Does |
|---|---|
| `]q` / `[q` | Next / previous entry |
| `]Q` / `[Q` | Last / first entry |
| `,lq` | Open it in the Trouble panel |

| Command | Does |
|---|---|
| `:copen` / `:cclose` | Open / close the window |
| `:cfirst` / `:clast` | Jump to first / last |
| `:cdo {cmd}` | Run a command on every entry |
| `:cfdo {cmd}` | Run a command once per file in the list |

The window has a floating preview of each entry and fuzzy filtering, so you can narrow a long list without leaving it. Press `?` inside for its mappings.

### Filtering a build

```
:Cfilter /error/      " keep only errors, drop warnings
:Cfilter! /obj/       " drop everything matching obj
```

`:Cfilter` ships with Neovim but needs loading, which this config does at startup. It is the nearest thing to the per-source filtering the MetaOutput extension gave you in Visual Studio.

### The location list

The same idea, but scoped to one window rather than global. `]l` / `[l` to move, `:lopen` to view, `,ll` for the Trouble panel. Some plugins put results here specifically to avoid clobbering your quickfix list.

## The build-error loop

The workflow worth building muscle memory for:

```
:make          " build; errors land in quickfix
]q             " jump to the first error
               " fix it
]q             " next
:Cfilter /error/   " if warnings are drowning out the errors
```

`]q` and `[q` are why vim-unimpaired earns its place.

## Searching by symbol rather than text

Once a language server is attached, prefer these to grep. They understand the code rather than matching characters, so they will not find your symbol's name inside a comment or a different type's member.

| Key | Does |
|---|---|
| `grr` | Every reference to this symbol |
| `gri` | Implementations |
| `grn` | Rename everywhere, safely |
| `,lr` | References in the Trouble panel |

```
:Telescope lsp_workspace_symbols     " find a type anywhere in the solution
:Telescope diagnostics               " every problem, solution-wide
```
