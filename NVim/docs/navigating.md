# Navigating

## Telescope

The fuzzy picker. Replaces bufexplorer and finally answers the ctrlp/fzf entries that sat commented out in `_vimrc.plug` for years.

| Key | Picker |
|---|---|
| `<F7>` | Buffers |
| `,ff` | Find files |
| `,fg` | Live grep (needs ripgrep, which is installed) |
| `,fr` | Recent files |
| `,fh` | Help tags |
| `,td` | TODO comments across the project |

Useful ones without a mapping, run as commands:

```
:Telescope diagnostics       " every diagnostic, solution-wide
:Telescope lsp_document_symbols
:Telescope lsp_workspace_symbols
:Telescope git_branches
:Telescope git_commits
:Telescope git_status
:Telescope resume            " reopen the last picker with its results
:Telescope keymaps
:Telescope commands
```

### Inside a picker

| Key | Does |
|---|---|
| `<C-n>` / `<C-p>` | Next / previous result |
| `<CR>` | Open |
| `<C-x>` | Open in a horizontal split |
| `<C-v>` | Open in a vertical split |
| `<C-t>` | Open in a new tab |
| `<C-u>` / `<C-d>` | Scroll the preview |
| `<C-q>` | Send all results to the quickfix list |
| `<Esc>` | Back to normal mode inside the picker |
| `<C-c>` | Close |
| `<C-/>` | Show every mapping for the current picker |

`<C-/>` is the one to remember; it is the picker's own live cheat sheet.

Typing in a picker is Insert mode, so Colemak translation applies.

### A note on search scope

This config follows the current file's directory (`lcd` on every buffer). That means `,ff` and `,fg` search from **the current file's folder**, not the project root, once you have opened something deep in the tree.

To search from a specific root:

```
:Telescope find_files cwd=C:/path/to/solution
:cd C:/path/to/solution      " or just move the whole session there
```

`,cd` sets the working directory to the current file's folder deliberately.

## File tree

| Key | Does |
|---|---|
| `<F8>` or `<C-n>` | Toggle |

Inside the tree, press `?` for its full mapping list. The common ones:

| Key | Does |
|---|---|
| `<CR>` | Open file, or expand folder |
| `a` | Add a file (end with `/` to make a directory) |
| `d` | Delete |
| `r` | Rename |
| `c` / `x` / `p` | Copy / cut / paste |
| `H` | Toggle hidden files |
| `s` / `S` | Open in vertical / horizontal split |
| `q` | Close the tree |

Git status shows against each entry. The tree follows the current file as you move between buffers.

## Symbol outline

| Key | Does |
|---|---|
| `<F10>` | Toggle the outline sidebar |

Backed by the language server, falling back to treesitter and a markdown parser. No ctags binary needed, which is why the old `<F10>` failed for most filetypes in gVim.

| Command | Does |
|---|---|
| `:AerialNext` / `:AerialPrev` | Move between symbols |
| `:AerialGo 3` | Jump to the third symbol |
| `:AerialNavToggle` | A floating navigation view |

The statusline breadcrumb comes from the same data.

## Buffers and tabs

Open buffers appear along the top.

| Key | Does |
|---|---|
| `<F7>` | Buffer picker |
| `,bn` / `,bp` | Next / previous |
| `]b` / `[b` | Next / previous (unimpaired) |
| `,bd` | Delete this buffer |
| `,bc` | Close the buffer but **keep the window layout** |
| `,ba` | Delete every buffer |

`,bc` is the one you want when a split layout matters. Plain `bdelete` closes the window along with the buffer.

## Windows

| Key | Does |
|---|---|
| `<C-h/j/k/l>` | Move left/down/up/right |
| `<C-w>m` | Maximize this window, press again to restore |
| `<C-w>gss` | (visual) Split off exactly the selected lines |
| `<C-w>gsa` / `<C-w>gsb` | (visual) Split above / below |
| `<C-w>gr` | (visual) Resize to the selection |

## Jumping within a file

| Key | Does |
|---|---|
| `%` | Matching bracket, or keyword pair such as `if`/`else` |
| `[%` / `]%` | Previous / next unmatched open or close |
| `z%` | Into the nearest pair |
| `]d` / `[d` | Next / previous diagnostic |
| `]c` / `[c` | Next / previous git hunk |
| `gx` | Open the URL or file path under the cursor externally |

`%` understands language keywords, not just brackets, so it works on `if`/`endif`, opening and closing XML tags, and similar.

## Sessions

| Key | Does |
|---|---|
| `,qs` | Restore the session for this directory |
| `,ql` | Restore the last session |

Sessions are per working directory and saved automatically. There are no lock files, unlike the old vim-session setup.
