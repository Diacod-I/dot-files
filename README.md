# dot-files

My terminal setup with **zsh + starship + tmux + Neovim** for MacOS (Apple Silicon).

<img width="1470" height="919" alt="Screenshot 2026-08-13 at 2 40 06 AM" src="https://github.com/user-attachments/assets/990e73fe-3820-43cc-9692-9e511d1feebf" />


---

## What's here

| Path | Configures |
|------|------------|
| [`zsh/.zshrc`](zsh/.zshrc) | shell: eza listing functions, fzf/atuin/zoxide, syntax highlighting, a run counter |
| [`starship/starship.toml`](starship/starship.toml) | prompt: repo-aware rows, off-main guard, language versions, pane-aware rule |
| [`tmux/.tmux.conf`](tmux/.tmux.conf) | multiplexer: `C-a` prefix, popup rename/move, resurrect/continuum, vim-navigator |
| [`nvim/init.lua`](nvim/init.lua) | editor: lazy.nvim, LSP (pyright + ruff), treesitter, harpoon, telescope |

---

## Features 

### Context-based prompt
The prompt is displayed a column format unlike most other prompts where every detail is dumped onto one row.
- **Directory row** shows the repo-relative path inside a git repo (`myrepo/src/api`),
  and the path from `~` when you're loose in the filesystem. 
- **Branch row** appears *only* inside a repo — and turns into a white-on-red
  `⚠ OFF-MAIN` flag the moment you're not on `main`/`master` (personally
  saved me from committing to the wrong branch more than once).
- **venv row** shows only when a virtualenv is active.
- **Language rows** (`rust`, `py`) auto-hide outside the relevant project.
- Full-width rule with a run counter, so each command's
  output is visually bracketed. It's **tmux-pane-aware and resize-safe** 
  (measures `#{pane_width}` per draw), and it carries a command counter (`#7`) that resets with `cls`.

### Listing commands that are actually scannable
`ls`/`ll`/`lf`/`lt` are functions wrapping [`eza`](https://github.com/eza-community/eza),
indented for readability. `lf` is a one-per-line view that **emphasizes the first
letter of each name**, turning a wall of ~30 project folders into something you
can eye-scan alphabetically.

### git rebase / merge you can actually read
The interactive-rebase screen is **color-coded per command** (green `pick`, red
`drop`, purple `squash`, …) via a `gitrebase` FileType autocmd, and
[`git-conflict.nvim`](https://github.com/akinsho/git-conflict.nvim) handles merge
markers inline.

---

## Requirements

```sh
brew install starship eza fzf atuin zoxide ripgrep fd bat ast-grep tealdeer neovim tmux
```

Plus a **Nerd Font** for the prompt glyphs and eza icons (I use 0xProto).

---

## Install

1) Symlink config files into place:

```sh
git clone https://github.com/Diacod-I/dot-files ~/dot-files
cd ~/dot-files

ln -sf "$PWD/zsh/.zshrc"              ~/.zshrc
ln -sf "$PWD/starship/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/tmux/.tmux.conf"        ~/.tmux.conf
ln -sf "$PWD/nvim/init.lua"          ~/.config/nvim/init.lua
```

2) Install [tpm](https://github.com/tmux-plugins/tpm), open tmux, press `prefix + I`.
3) Open `nvim` — lazy.nvim bootstraps itself and installs everything on first launch.
4) Install [oh-my-zsh](https://ohmyz.sh/) with the `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins.

---

## Notes / caveats

- Built and tested on **macOS, Apple Silicon, Homebrew**. Linux works with minor path tweaks.
- The `.zshrc` has a *machine-specific tools* block (Java/Spark/Postgres/etc.) — edit or delete it for your setup.
- `init.lua` enables a `solidity_ls` LSP; remove it from the server list if you don't do Solidity.
- The prompt shells out a few times per draw. It's snappy in normal repos; in very large
  repos you can raise `command_timeout` or trim modules.
- Neovim 0.12 requires nvim-treesitter's **`main`** branch, which has a different
  API (`require("nvim-treesitter").install{...}` + manual `vim.treesitter.start`).
  My config also registers the `git_rebase` parser against the `gitrebase` filetype
  (the names don't match by default) and disables treesitter in the Telescope
  previewer to dodge a `languagetree` crash. If you're on 0.12 and hit either, this
  is the fix.

---
