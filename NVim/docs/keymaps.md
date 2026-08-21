# Keymap reference

Every mapping this config defines, by prefix. Leader is `,`.

Press `,` and pause to get the same information from which-key, live. `<leader>?` lists buffer-local mappings only.

## Leader prefixes at a glance

| Prefix | Group |
|---|---|
| `,b` | buffers |
| `,c` | cwd, wrap, format |
| `,D` | debug |
| `,f` | find |
| `,h` | git hunks (only in a tracked file) |
| `,k` | HTTP requests |
| `,l` | lists (Trouble) |
| `,o` | tasks (Overseer) |
| `,q` | scratch buffer, sessions |
| `,r` | replace |
| `,s` | spelling |
| `,t` | tab stops, TODOs |
| `,v` | diff view |
| `,w` | wiki |

## Files, buffers, windows

| Key | Does |
|---|---|
| `<F7>` | Buffer picker (replaces bufexplorer) |
| `<F8>` or `<C-n>` | File tree toggle |
| `<F9>` | Undo tree toggle |
| `<F10>` | Symbol outline toggle |
| `,ff` | Find files |
| `,fg` | Live grep across the project |
| `,fr` | Recent files |
| `,fh` | Help tags |
| `,fa` | Quickfix every match of a pattern in this file |
| `,bd` | Delete buffer |
| `,bc` | Close buffer, **keep the window layout** |
| `,ba` | Delete all buffers |
| `,bn` / `,bp` | Next / previous buffer |
| `,cd` | Change directory to the current file's folder |
| `<C-h/j/k/l>` | Move to the window left/down/up/right |
| `<C-w>m` | Maximize this window, again restores |

## Editing

| Key | Does |
|---|---|
| `gcc` | Toggle comment on this line |
| `gc` + motion | Toggle comment over a motion (`gcap` for a paragraph) |
| `,cw` | Toggle display wrapping (and make `j`/`k` follow screen lines) |
| `,ts` | Set tab stops, prompts for a value |
| `,t2` `,t3` `,t4` | Set tab stops to 2, 3 or 4 |
| `,cf` | Format buffer, or the selection in visual mode |
| `,S` | Sum the numbers, whole buffer in normal mode, selection in visual |
| `,m` | Strip stray carriage returns from the file |
| `,<CR>` or `,n` | Clear search highlight |
| `,q` | Open the `~/buffer` scratch file |
| `,x` | Open the `~/buffer.md` scratch file |

## Language server

Neovim's built-in LSP mappings, available in any buffer with a server attached.

| Key | Does |
|---|---|
| `K` | Hover documentation |
| `gd` | Go to definition |
| `grn` | Rename symbol across the project |
| `gra` | Code action |
| `grr` | Find references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `grx` | Run code lens |
| `gO` | Document symbols |
| `<C-]>` | Go to definition (via tagfunc) |
| `<C-w>d` | Show the diagnostic under the cursor in a float |
| `]d` / `[d` | Next / previous diagnostic |
| `]D` / `[D` | Last / first diagnostic in the buffer |
| `<C-x><C-o>` | Omni-completion (completion is otherwise automatic) |

`gd` is mapped to LSP definition on attach, overriding Vim's lexical "go to local declaration". It only exists in buffers with a server attached; elsewhere the Vim default applies.

## Diagnostics and lists

| Key | Does |
|---|---|
| `,ld` | Trouble: all project diagnostics |
| `,lb` | Trouble: this buffer's diagnostics |
| `,ls` | Trouble: symbols |
| `,lr` | Trouble: references and definitions |
| `,lq` | Trouble: quickfix list |
| `,ll` | Trouble: location list |
| `,td` | Every TODO/FIXME/HACK in the project |

## Debugging

Provisional bindings. The F-key question (VS-style F5/F9/F10/F11 versus undotree and aerial) is unresolved.

| Key | Does |
|---|---|
| `,Dc` | Continue, or start a session |
| `,Db` | Toggle breakpoint |
| `,Do` | Step over |
| `,Di` | Step into |
| `,DO` | Step out |
| `,Dr` | Toggle the REPL |
| `,Du` | Toggle the debugger UI |
| `,Dt` | Terminate the session |

## Git

| Key | Does |
|---|---|
| `]c` / `[c` | Next / previous change hunk |
| `,hp` | Preview this hunk inline |
| `,hs` | Stage this hunk |
| `,hr` | Reset this hunk |
| `,hb` | Blame this line |
| `,vo` | Open the diff view |
| `,vc` | Close the diff view |
| `,vh` | Repository file history |
| `,vf` | This file's history |

Hunk mappings only exist in a file git is tracking.

## Search and replace

| Key | Does |
|---|---|
| `,fg` | Live grep the project |
| `,rr` | Project find and replace, with preview |
| `,rw` | Replace the word under the cursor |
| `,rf` | Replace within the current file |
| `,rs` | Replace the visual selection (visual mode) |
| `*` / `#` | In visual mode, search for the selected text |
| `]q` / `[q` | Next / previous quickfix entry |
| `]Q` / `[Q` | Last / first quickfix entry |
| `]l` / `[l` | Next / previous location list entry |

## Tasks and build

| Key | Does |
|---|---|
| `,oo` | Toggle the task list |
| `,or` | Run a task |
| `,ob` | Build a task (choose and configure) |
| `,oq` | Quick action on a task |

## Tools

| Key | Does |
|---|---|
| `,u` | Database UI toggle |
| `,ks` | Send the HTTP request under the cursor |
| `,ka` | Send every request in the file |
| `,kt` | Toggle between response body and headers |
| `,kn` / `,kp` | Next / previous request |
| `,kc` | Copy the request as a curl command |
| `,ke` | Select the HTTP environment |
| `,z` | Zen mode |
| `,?` | Show buffer-local mappings |

## Markdown rendering

| Command | Does |
|---|---|
| `:RenderMarkdown toggle` | Toggle in-buffer rendering |
| `:RenderMarkdown expand` | Show more of the raw syntax around the cursor |
| `:RenderMarkdown contract` | Show less |

## Spelling and prose

| Key | Does |
|---|---|
| `,ss` | Toggle spell checking |
| `,sn` / `,sp` | Next / previous misspelling |
| `,sa` | Add the word under the cursor to the dictionary |
| `,s?` | Suggest corrections |

## Wiki

| Key | Does |
|---|---|
| `,ww` | Open the wiki index |
| `,wt` | Open the wiki index in a new tab |
| `,ws` | Select which wiki |
| `,wi` | Diary index |
| `,w,w` | Today's diary entry |
| `,w,t` | Tomorrow's diary entry |
| `,w,y` | Yesterday's diary entry |

## Sessions and display

| Key | Does |
|---|---|
| `,qs` | Restore the session for this directory |
| `,ql` | Restore the last session |
| `,jf` | Toggle relative line numbers in this window |
| `,fj` | Toggle the automatic relative/absolute number switching |

## Paired bracket mappings

From vim-unimpaired. `]` moves forward, `[` moves back.

| Key | Does |
|---|---|
| `]q` `[q` | Quickfix |
| `]l` `[l` | Location list |
| `]b` `[b` | Buffers |
| `]a` `[a` | Argument list |
| `]t` `[t` | Tag list |
| `]<Space>` `[<Space>` | Add a blank line below / above |
| `]e` `[e` | Move this line down / up |
| `yos` | Toggle spell |
| `yow` | Toggle wrap |
| `yon` | Toggle line numbers |
| `yoc` | Toggle cursorline |
| `yoh` | Toggle search highlight |

## Matching pairs

From vim-matchup, which extends the built-in `%`.

| Key | Does |
|---|---|
| `%` | Jump to the matching keyword or bracket |
| `[%` / `]%` | Previous / next outer open or close word |
| `z%` | Jump inside the nearest pair |
| `g%` | Jump backwards to the matching word |

## GUI only

Only active in Neovide.

| Key | Does |
|---|---|
| `<C-=>` | Increase font size |
| `<C-->` | Decrease font size |
| `<C-0>` | Reset font size |
