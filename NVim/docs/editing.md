# Editing

Beyond ordinary Vim operators and motions.

## Surround

Operate on the delimiters around text.

| Key | Does |
|---|---|
| `cs"'` | Change surrounding `"` to `'` |
| `cs'<q>` | Change `'` to `<q>` tags |
| `ds(` | Delete surrounding parentheses |
| `ysiw)` | Surround the word with parentheses |
| `ysiw"` | Surround the word with quotes |
| `yss)` | Surround the whole line |
| `S"` | (visual) Surround the selection |

Using the opening bracket adds spaces, the closing one does not: `ysiw(` gives `( word )`, `ysiw)` gives `(word)`.

`.` repeats these, because vim-repeat is installed.

## Text objects

Beyond `iw`, `i(` and friends.

| Object | Selects |
|---|---|
| `i,` / `a,` | Between commas: one argument in a list |
| `ia` / `aa` | A function argument, comma handling included |
| `i)` `i]` `i}` | Inside the nearest bracket of that kind, from anywhere on the line |
| `in)` / `il)` | The **next** / **last** parentheses, not just the current ones |
| `aj` / `ij` | A JSON value, outer or inner |

The next/last variants are the powerful part: `cin)` changes the contents of the next parentheses without moving there first.

For C# method calls with long argument lists, `ci,` and `cia` are the daily workhorses.

## Comments

Built into Neovim, no plugin.

| Key | Does |
|---|---|
| `gcc` | Toggle this line |
| `gc` + motion | Toggle over a motion: `gcap` for a paragraph, `gcj` for two lines |
| `gc` | (visual) Toggle the selection |

Comment syntax comes from the filetype, so it is correct in C#, XML, SQL and the rest.

## Paired bracket mappings

From vim-unimpaired. `]` forward, `[` back, `yo` toggles.

| Key | Does |
|---|---|
| `]q` `[q` | Quickfix entries: walking build errors |
| `]Q` `[Q` | Last / first quickfix entry |
| `]l` `[l` | Location list |
| `]b` `[b` | Buffers |
| `]a` `[a` | Argument list |
| `]<Space>` `[<Space>` | Insert a blank line below / above without leaving normal mode |
| `]e` `[e` | Exchange this line with the one below / above |
| `yow` | Toggle wrap |
| `yos` | Toggle spell |
| `yon` | Toggle line numbers |
| `yoh` | Toggle search highlight |
| `yoc` | Toggle cursorline |
| `yol` | Toggle list characters |

`]q` after a build is the workflow that makes the quickfix list worth using.

## Yank ring

Every yank is remembered, not just the last.

| Key | Does |
|---|---|
| `p` / `P` | Paste after / before, as usual |
| `<C-p>` | After pasting, cycle back to an older yank |

Press `p`, then `<C-p>` repeatedly to walk backwards through your yank history, replacing the pasted text each time.

## Alignment

| Command | Does |
|---|---|
| `:Tabularize /=` | Line up on `=` |
| `:Tabularize /\|` | Line up a markdown table |
| `:Tabularize /:\zs` | Line up after a colon |

Works on a visual selection or the surrounding block.

## Brackets and pairs

Closing brackets and quotes are inserted automatically as you type, including triple quotes and backtick fences.

`%` jumps between matching pairs and understands language keywords, so it works on `if`/`else`, `try`/`catch`, and open/close XML tags, not just brackets. The matching pair is highlighted while the cursor is on one.

## Undo tree

| Key | Does |
|---|---|
| `<F9>` | Toggle the undo tree |

Undo history is a tree, not a line. When you undo and then type something new, the old future is still there, and plain `u`/`<C-r>` cannot reach it. The tree can. Undo persists across sessions, so yesterday's history is still available.

## Whitespace and display

| Key | Does |
|---|---|
| `,cw` | Toggle display wrapping. While on, `j`/`k` move by screen line |
| `,ts` | Set tab stops, prompts |
| `,t2` `,t3` `,t4` | Set tab stops directly |
| `,m` | Strip stray carriage returns |
| `,S` | Sum the numbers in the buffer, or the selection |

Default indentation is 3 spaces, carried over from `_vimrc`. Some filetypes override it: see [filetypes.md](filetypes.md). Files with their own consistent style are detected and matched automatically.

## Zoom and splits

| Key | Does |
|---|---|
| `<C-w>m` | Maximize this window, again to restore |
| `<C-w>gss` | (visual) Split off exactly the selected lines |

## Unicode

| Command | Does |
|---|---|
| `:UnicodeName` | Identify the character under the cursor |
| `:UnicodeTable` | Browse the Unicode tables |
| `:Digraphs` | Search digraphs |
| `,un` | Complete a character from its Unicode name |
