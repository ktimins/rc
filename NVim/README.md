# Neovim configuration

Lua-based Neovim config, kept in this repo and junctioned into place. Independent of the gVim setup in `Vim/`: the two share no files and neither can break the other.

Design and implementation docs live in `Vim/vimrc/nvim-migration/`. Read them in numeric order; `01-colemak.md` is the non-negotiable piece and its acceptance checklist gates everything else.

## Install on a machine

Neovim reads its config from `%LOCALAPPDATA%\nvim` (`:echo stdpath('config')`). Point that at this folder with a directory junction. Junctions need no administrator rights or developer mode, unlike directory symlinks.

```cmd
mklink /J "%LOCALAPPDATA%\nvim" "C:\Users\<user>\Git\rc\NVim"
```

The user per machine follows `$LOCATION`: `WORK` is `ktimins`, `THEIA` is `rzite`, `ARES` is `rzitex`.

To undo, `rmdir "%LOCALAPPDATA%\nvim"`. Removing a junction does not touch the repo contents.

## What is not in this repo

Runtime state stays outside version control in Neovim's own directories: plugins and caches under `%LOCALAPPDATA%\nvim-data` (`stdpath('data')`), undo/swap/backup under `stdpath('state')`. These are deliberately not pointed at the `.vimstorage` directories the gVim setup uses, because Vim and Neovim disagree on undofile format and would contend over swap files.

## Requirements

- Neovim 0.12+. Not optional: nvim-treesitter's `main` branch and the Roslyn C# language server integration both require it
- A C compiler for treesitter parser builds; `zig` is the recommended one on Windows
- The tree-sitter CLI, `tar` and `curl` (all three are nvim-treesitter `main` requirements)
- `git`, `ripgrep`, `node`/`npm`
- .NET SDK on PATH for the C# tooling. This config targets modern .NET (8/9/10+); .NET Framework debugging stays in Visual Studio

### The tree-sitter CLI needs a real .exe on Windows

`npm install -g tree-sitter-cli` installs three shims into the npm global bin directory: an extension-less shell script, a `.cmd` and a `.ps1`. Neovim spawns processes through libuv, which cannot execute the extension-less script, so every parser build fails with `ENOENT: no such file or directory` after downloading successfully. The error names the download step's sibling, not the missing executable, which makes it easy to misread as a network problem.

The package does ship a genuine binary; it just is not the thing on PATH. Copy it next to the shims:

```sh
npm install -g tree-sitter-cli
cp "$(npm root -g)/tree-sitter-cli/tree-sitter.exe" "$(dirname "$(npm root -g)")/tree-sitter.exe"
```

Verify from inside Neovim, since `exepath()` will still report the shim while the spawn resolves the `.exe`:

```
:lua =vim.system({"tree-sitter","--version"},{text=true}):wait()
```

A non-zero `code` means parser builds will fail silently apart from an error in `:messages`.
