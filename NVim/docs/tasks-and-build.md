# Tasks and building

Two ways to run a build. They exist alongside each other on purpose.

## `:make`, the dependable one

Runs `dotnet build` and puts the errors in the quickfix list. No plugin involved, and verified working against real MSBuild output.

```
:make               " build
:copen              " see the list
]q  [q              " walk the errors
:Cfilter /error/    " drop warnings
```

`makeprg` and the MSBuild `errorformat` are set automatically in `cs` buffers, so `:make` just works there. In other filetypes it falls back to whatever `makeprg` is.

Use `:make!` to build without jumping to the first error.

## Overseer, the nicer one

A task list with per-task output windows.

| Key | Does |
|---|---|
| `,or` | Run a task, chosen from a list |
| `,oo` | Toggle the task list |
| `,oq` | Quick action on a task: restart, stop, open output, dispose |
| `,ob` | Build a task, editing its arguments before running |

Registered templates, offered in `cs`, `sln` and `csproj` buffers:

| Template | Runs |
|---|---|
| `dotnet build` | `dotnet build` |
| `dotnet test` | `dotnet test` |
| `dotnet run` | `dotnet run` |

In the task list: `<CR>` opens a task's output, `r` restarts, `d` disposes, `?` shows all mappings. Tasks keep running while you edit, and their output stays available afterwards.

**Caveat.** Overseer's quickfix integration could not be verified during setup: the task runs and exits correctly, but under headless testing the captured output was empty. It very likely works interactively. If `,or` builds but the quickfix stays empty, that is this, and `:make` is the fallback. Both use the same errorformat.

## easy-dotnet

Solution-aware, and the right choice when you want it to figure out the project for you.

| Command | Does |
|---|---|
| `:Dotnet build` | Build, errors surfaced |
| `:Dotnet run` | Run, honouring `launchSettings.json` profiles |
| `:Dotnet test` | Run tests |
| `:Dotnet testrunner` | Test tree with per-test pass/fail icons |
| `:Dotnet restore` | Restore packages |
| `:Dotnet clean` | Clean |
| `:Dotnet secrets` | Edit user secrets |
| `:Dotnet outdated` | Outdated package references |
| `:Dotnet new` | Scaffold from a template |

### The test runner

`:Dotnet testrunner` opens a tree of every test in the solution. Run one, a class, or everything; results show as icons per test; failures can be expanded for their output. This is the Test Explorer equivalent.

## Which to use

| Want | Use |
|---|---|
| Errors in the quickfix, reliably | `:make` then `]q` |
| A task list, output kept around | `,or` |
| Build the right project without thinking | `:Dotnet build` |
| Run with a specific argument set | `:Dotnet run`, pick a launch profile |
| Run tests | `:Dotnet testrunner` |

## Understanding the output

MSBuild reports each diagnostic **once per build pass**, so an error in a project that another project references shows up twice in the quickfix list. Visual Studio dedupes in its Error List; the quickfix does not. Not a bug, just noise to expect.

The `[C:\path\Proj.csproj]` suffix on each message is MSBuild telling you which project produced it. In a multi-project solution that is genuinely useful, so it is kept rather than stripped.

## Running arbitrary commands

```
:!dotnet --version           " run once, show the output
:r !dotnet --list-sdks       " read the output into the buffer
:%!jq .                      " filter the whole buffer through a command
```

`:%!` is the workhorse: it pipes the buffer through an external program and replaces it with the result. That is how the JSON and XML formatting mappings work.
