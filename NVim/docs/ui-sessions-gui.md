# Interface, sessions and the GUI

## The dashboard

Starting `nvim` with no file gives a start screen. The bookmark keys are carried over from the gVim setup:

| Key | Opens |
|---|---|
| `v` | The gVim `_vimrc` |
| `b` | This config's `init.lua` |
| `p` | The PowerShell profile |
| `m` | The machine-specific PowerShell profile |
| `r` | Recent files picker |
| `q` | Quit |

## Sessions

| Key | Does |
|---|---|
| `,qs` | Restore the session for this directory |
| `,ql` | Restore the last session |

Saved automatically per working directory, so opening the editor in a project and pressing `,qs` puts back the buffers and layout you left. No lock files, unlike the old vim-session setup, so a crash never leaves a stale session you have to clear by hand.

## Display toggles

| Key | Does |
|---|---|
| `,z` | Zen mode: centred, chrome hidden |
| `,cw` | Display wrapping, with `j`/`k` by screen line |
| `,jf` | Relative line numbers in this window |
| `,fj` | The automatic relative/absolute switching |
| `yow` | Wrap |
| `yon` | Line numbers |
| `yoc` | Cursorline |
| `yoh` | Search highlight |

Line numbers are relative in Normal mode and absolute in Insert mode, switching automatically. `,fj` turns that behavior off entirely if it distracts.

## The statusline

Left to right: mode, git branch and diff counts, filename, breadcrumb of the code position, then diagnostics counts, the Colemak indicator, encoding, file format and filetype.

The Colemak indicator is the one to watch:

| Shows | Means |
|---|---|
| `CMK` | Typing is translated to Colemak. Normal |
| `QWE` | Raw QWERTY in this buffer. You pressed `CTRL-^` |

## Colours

Default scheme is tokyonight-moon.

```
:colorscheme anderson        " the old gVim look
:colorscheme tokyonight-day  " light
:colorscheme habamax         " built in, no plugin
```

Colour codes like `#a4c639` are painted in their actual colour in the buffer.

Indent guides are drawn, with the current scope highlighted, which is more than the Visual Studio Indent Guides extension did. Nested brackets are coloured by depth.

## Neovide

The GUI, replacing gVim. Same config, same everything; only the rendering differs.

```
neovide                      " dashboard
neovide path\to\file.cs
neovide .                    " open a directory
```

| Key | Does |
|---|---|
| `<C-=>` | Larger font |
| `<C-->` | Smaller font |
| `<C-0>` | Reset |

Font is CaskaydiaCove Nerd Font Mono at size 10, matching the gVim setup, with a fallback chain behind it. Cursor and scroll animation are on but short. The window remembers its size between runs. The mouse hides while typing, which is the old `mousehide` behavior.

Not portable from gVim, by design: scrollbars, the menu bar and the toolbar. Neovide has none of them.

Terminal Neovim in Windows Terminal is equally usable with the same config; Neovide is the option that feels like gVim.

## Which-key

Press `,` and pause. Every continuation appears, grouped and labelled. Then keep going and it narrows.

`,?` shows only buffer-local mappings, which is how you discover the filetype-specific ones.

This is the fastest way to learn the config, and worth using in preference to reading these documents once you know roughly what exists.

## Notifications and progress

Language server progress appears in the corner. Roslyn takes real time to load a large solution and the indicator is the difference between "working" and "the editor has hung".

## Plugin management

| Command | Does |
|---|---|
| `:Lazy` | The plugin manager UI |
| `:Lazy update` | Update everything |
| `:Lazy restore` | Roll every plugin back to the committed lockfile |
| `:Lazy profile` | Startup timing per plugin |
| `:Mason` | Manage language server and tool binaries |
| `:checkhealth` | Diagnose the whole setup |

`:Lazy restore` is the important one: `lazy-lock.json` is committed, so this puts every plugin back to a known-good state after an update goes wrong.

Startup is around 110ms with 61 plugins, because almost everything loads on demand.
