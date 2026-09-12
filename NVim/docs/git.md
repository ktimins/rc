# Git

Four layers, each good at a different thing: gutter signs for the line you are on, fugitive for git operations, diffview for comparing, gv for history.

## Hunks in the current file

Signs in the gutter show added, changed and removed lines. This replaces the Git Diff Margin extension, and does considerably more.

| Key | Does |
|---|---|
| `]c` / `[c` | Next / previous hunk |
| `,hp` | Preview this hunk inline |
| `,hs` | Stage this hunk |
| `,hr` | Reset this hunk to HEAD |
| `,hb` | Blame this line |

These are buffer-local and only exist in a file git is tracking, so they will be absent in a scratch buffer.

Staging hunk by hunk from inside the file is the fastest way to build a focused commit. In gVim this was unreachable: the old gitgutter config disabled every hunk mapping and never replaced them, so only the signs ever worked.

| Command | Does |
|---|---|
| `:Gitsigns toggle_current_line_blame` | Show blame for the current line continuously |
| `:Gitsigns diffthis` | Diff this file against the index |
| `:Gitsigns blame` | Full-file blame in a split |

## Git operations

fugitive. `:Git` takes anything the git CLI does.

| Command | Does |
|---|---|
| `:Git` | Status window; the hub for everything else |
| `:Git blame` | Blame in a split, aligned with the file |
| `:Git commit` | Commit |
| `:Git push` / `:Git pull` | As expected |
| `:Gdiffsplit` | Diff this file against the index, side by side |
| `:Gread` | Replace the buffer with the committed version |
| `:Gwrite` | Stage the whole file |
| `:GBrowse` | Open the current line on GitHub |

In the `:Git` status window: `s` stages, `u` unstages, `=` expands the diff inline, `cc` starts a commit, `dd` opens a diff, `g?` shows all mappings.

`:GBrowse` on a visual selection links to exactly those lines, which is the fastest way to point a colleague at code.

## Comparing and history

diffview, the closest thing here to the Visual Studio diff viewer.

| Key | Does |
|---|---|
| `,vo` | Open the diff view of working tree against HEAD |
| `,vc` | Close it |
| `,vh` | Repository file history |
| `,vf` | History of just this file |

```
:DiffviewOpen main..HEAD     " compare against a branch
:DiffviewOpen HEAD~3         " compare against three commits ago
:DiffviewFileHistory %       " this file's history
```

The file panel lists everything changed; move through it and each file opens side by side. For merge conflicts it gives a three-pane view with both sides and the result.

Inside the view: `<Tab>` and `<S-Tab>` cycle files, `g?` shows all mappings, `,vc` closes.

## Commit browser

| Command | Does |
|---|---|
| `:GV` | Browse commits |
| `:GV!` | Only commits touching this file |
| `:GV -S foo` | Only commits that changed occurrences of `foo` |

`:GV -S` is pickaxe search, and it is the right tool for "when did this string appear or disappear".

## Through Telescope

```
:Telescope git_branches      " switch branch, or diff against one
:Telescope git_commits       " browse and check out
:Telescope git_bcommits      " commits touching this file
:Telescope git_status        " changed files, with a diff preview
:Telescope git_stash
```

## Which to reach for

| Want | Use |
|---|---|
| Stage part of a file | `,hs` on each hunk |
| See who changed this line | `,hb` |
| Full history of a file | `,vf` |
| Compare against another branch | `:DiffviewOpen main..HEAD` |
| Resolve a merge conflict | `,vo` for the three-pane view |
| Find when a string changed | `:GV -S string` |
| Share a link to code | `:GBrowse` |
| Anything else | `:Git <whatever git does>` |
