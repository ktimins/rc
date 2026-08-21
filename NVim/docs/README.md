# Cheat sheets

Reference for this Neovim configuration. These cover what THIS config adds: its mappings, its plugins, and the workflows it was built for. Ordinary Vim (motions, operators, registers, marks) is assumed and not repeated.

Everything here was derived from the loaded config rather than written from memory, so if a key is listed it exists. Where a plugin has its own extensive keymap set, these sheets point at that plugin's own help rather than duplicating a list that will drift.

## Start here

| Sheet | When you want |
|---|---|
| [keymaps.md](keymaps.md) | The complete mapping reference, by prefix. The master sheet |
| [colemak.md](colemak.md) | How the keyboard contract works, and what to do when typing comes out wrong |
| [csharp.md](csharp.md) | Opening a solution, navigating code, building, testing, formatting |

## By task

| Sheet | Covers |
|---|---|
| [navigating.md](navigating.md) | Telescope, file tree, symbol outline, buffers, windows, jumps |
| [editing.md](editing.md) | Surround, text objects, paired brackets, yank ring, comments, alignment |
| [lsp-and-diagnostics.md](lsp-and-diagnostics.md) | Language server keys, completion, diagnostics, the Trouble panel |
| [debugging.md](debugging.md) | Breakpoints, stepping, variable inspection |
| [git.md](git.md) | Hunks, blame, diff view, history, GitHub links |
| [search-replace-quickfix.md](search-replace-quickfix.md) | Searching, project-wide replace, quickfix workflow |
| [tasks-and-build.md](tasks-and-build.md) | Running builds and tests, getting errors into the quickfix list |
| [filetypes.md](filetypes.md) | Per-language behavior: JSON, XML/XSD, PowerShell, SQL, VB, CSV |
| [database.md](database.md) | Running SQL against a live connection |
| [http.md](http.md) | `.http` request files, the format Visual Studio 2022 uses |
| [writing.md](writing.md) | Markdown, grammar checking, the wiki |
| [ui-sessions-gui.md](ui-sessions-gui.md) | Dashboard, sessions, zen mode, Neovide, colorscheme |
| [troubleshooting.md](troubleshooting.md) | When something silently does not work, and the known gaps |

## The fastest way to learn the mappings

Press `,` and wait. **which-key** shows every continuation, grouped and labelled. That is the single most useful habit to build; these sheets exist for the times you want to read ahead rather than discover in the moment.

`<leader>?` shows only the mappings local to the current buffer, which is how you find the filetype-specific ones.

## Conventions in these sheets

- Leader is `,` throughout. `<leader>ff` means press `,` then `f` then `f`
- `<C-x>` means Ctrl and x together
- Keys are written as your **QWERTY** keyboard sends them, because that is what Normal mode sees. See [colemak.md](colemak.md) if that sentence needs explaining
