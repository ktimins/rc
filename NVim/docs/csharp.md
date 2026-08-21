# C#

Targets modern .NET (8, 9, 10 and later). .NET Framework projects still get full editing, navigation and completion; only **debugging** them stays in Visual Studio, because netcoredbg does not handle Framework processes reliably and Microsoft's vsdbg is license-restricted to VS and VS Code.

## Opening a solution

Change to the solution directory, then open any `.cs` file. Roslyn searches upward for the `.sln`.

```
cd C:\path\to\YourSolution
nvim src\Foo\Bar.cs
neovide src\Foo\Bar.cs
nvim .                     # open the directory, then pick from the tree
```

Starting `nvim` with no arguments gives you the dashboard; `,ff` or `<F8>` from there.

**Wait for Roslyn before trusting navigation.** It loads the whole solution, which takes seconds on a small one and considerably longer on a large one. Progress appears in the corner via fidget. Until it finishes, `grr` will under-report rather than error, which is the confusing failure mode.

| Command | Does |
|---|---|
| `:Roslyn target` | Choose which `.sln` to load, when several exist |
| `:LspInfo` | Confirm roslyn attached to this buffer |
| `:LspRestart` | Restart the server after a branch switch or a big change |

If your projects are not children of the `.sln` directory, Roslyn will not find them. Set `broad_search = true` on the roslyn.nvim spec in `lua/plugins/csharp.lua`.

## Navigating code

| Key | Does |
|---|---|
| `<C-]>` | Go to definition, across project boundaries |
| `grr` | Find references, solution-wide |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `grn` | Rename across the solution |
| `gra` | Code actions (add using, generate member, extract) |
| `K` | Hover: signature and the XML doc comment |
| `gO` | Symbols in this file |
| `<F10>` | Symbol outline sidebar |
| `,ls` | Symbols in a Trouble panel |
| `,fg` | Grep the solution text |

The statusline breadcrumb shows where the cursor is in the class and member tree, which is the equivalent of the context line Visual Studio puts above the editor.

`gd` is **not** LSP go-to-definition here; it is Vim's lexical local declaration. Use `<C-]>`.

## Building

Two paths, deliberately.

**`:make`** runs `dotnet build` and puts errors in the quickfix list. Depends on no plugin and is verified working.

```
:make            " build, populate quickfix
:copen           " open the list
]q  [q           " next / previous error
:Cfilter /error/ " narrow to errors only, dropping warnings
```

**Overseer** gives a task UI on top.

| Key | Does |
|---|---|
| `,or` | Run a task: `dotnet build`, `dotnet test`, `dotnet run` |
| `,oo` | Toggle the task list, with per-task output |
| `,oq` | Quick action on a task: restart, stop, open output |

If `,or` runs a build but the quickfix stays empty, use `:make` instead and see [troubleshooting.md](troubleshooting.md); that integration is unverified.

MSBuild reports each diagnostic once per build pass, so an error in a project that another references appears twice. Visual Studio dedupes in its Error List; the quickfix does not.

## Running and testing

easy-dotnet provides the solution-aware commands.

| Command | Does |
|---|---|
| `:Dotnet build` | Build, with errors surfaced |
| `:Dotnet run` | Run, honouring `launchSettings.json` profiles |
| `:Dotnet test` | Run tests |
| `:Dotnet testrunner` | Rider-style test tree with per-test state icons |
| `:Dotnet secrets` | Edit user secrets for the project |
| `:Dotnet outdated` | Show outdated package references |
| `:Dotnet new` | Scaffold a project or file from a template |

### Command line arguments

Visual Studio's Smart Command Line Arguments extension has no direct equivalent. The closest workflows, best first:

1. **`launchSettings.json` profiles.** Define a profile per argument set under `Properties/launchSettings.json`; easy-dotnet prompts you to pick one. Visual Studio reads the same file, so both editors share one source of truth
2. **Named debug configurations** in `.vscode/launch.json`, which nvim-dap reads automatically
3. **A prompt**, for one-offs

## Formatting

| Key | Does |
|---|---|
| `,cf` | Format the buffer, or the selection in visual mode |

Uses csharpier. Formatting is on demand, not on save. Roslyn also honours the `.editorconfig` analyzers your solution already carries, so its diagnostics reflect your team's style rules without extra setup.

## Diagnostics

| Key | Does |
|---|---|
| `]d` / `[d` | Next / previous diagnostic |
| `<C-w>d` | Show the full message under the cursor |
| `,lb` | Every diagnostic in this buffer |
| `,ld` | Every diagnostic in the solution |
| `gra` | Code action to fix the one under the cursor |

`,ld` is the closest thing to the Visual Studio Error List.

## Debugging

See [debugging.md](debugging.md). Modern .NET only.

## Visual Studio equivalents

| Visual Studio | Here |
|---|---|
| IntelliSense, go to, rename, find refs | Roslyn LSP, same analysis engine |
| Solution Explorer | `<F8>` file tree, `:Dotnet` project commands |
| CodeNav member list | `<F10>` outline, statusline breadcrumb |
| Error List | `,ld` |
| Git Diff Margin | Gutter signs, `,hp` to preview a hunk |
| Indent Guides | Built in, with current-scope highlighting |
| Rainbow Braces | Built in, treesitter-aware |
| TODO highlighter | Built in, plus `,td` to list them project-wide |
| Test Explorer | `:Dotnet testrunner` |
| Ctrl+D multi-cursor | Not installed. `grn` for renames, `,rr` for the rest |
| Ctrl+Shift+H replace | `,rr` |
| MetaOutput log hub | Partially: build output yes, arbitrary log dashboards no |
