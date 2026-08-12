# --- locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- auto-attach a single tmux session ---
if [ -z "$TMUX" ]; then
  tmux attach -t TMUX || tmux new -s TMUX
fi

# --- oh-my-zsh (prompt handled by starship, see bottom) ---
export ZSH="$HOME/.oh-my-zsh"
plugins=(git urltools bgnotify zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# --- command run counter (read by starship, resets with cls) ---
export CMD_COUNT_FILE="${TMPDIR:-/tmp}/.zsh_cmd_count_$$"
print 0 > "$CMD_COUNT_FILE"
_bump_count() { print $(( $(<"$CMD_COUNT_FILE") + 1 )) > "$CMD_COUNT_FILE"; }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _bump_count
cls() { clear && printf '\033[3J' && tmux clear-history 2>/dev/null; print 0 > "$CMD_COUNT_FILE"; }

# --- aliases ---
alias g++="/opt/homebrew/bin/g++-15"
alias gcc="/opt/homebrew/bin/gcc-15"

# --- eza listing functions (4-space indent, icons + color through the pipe) ---
_IND='    '
unalias ls ll 2>/dev/null
ls() { command eza --icons=always --color=always --group-directories-first "$@" | sed "s/^/$_IND/"; }
ll() { command eza -la --icons=always --color=always --git --group-directories-first "$@" | sed "s/^/$_IND/"; }
# one-per-line, first letter of each name emphasized (bold+underline)
lf() { command eza -1 --icons=always --color=always "$@" | perl -pe 's/(\e\[[0-9;]*m)+\K([[:alnum:]])/\e[1;4m$2\e[22;24m/' | sed "s/^/$_IND/"; }
# tree with the current dir name at the root instead of "."
lt() { command eza --tree --level=2 --icons=always --color=always "$@" | sed "1s|\.|$(basename "$PWD")|; s/^/$_IND/"; }
# indent any non-interactive command's output: `i cargo build`
i()  { "$@" 2>&1 | sed "s/^/$_IND/"; }

# --- zsh-syntax-highlighting: dim args, color commands/paths ---
ZSH_HIGHLIGHT_STYLES[default]='fg=244'
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'

# --- tools ---
source <(fzf --zsh)          # Ctrl-T files
eval "$(atuin init zsh)"     # Ctrl-R history search
eval "$(zoxide init zsh)"    # z <dir> jump
. "$HOME/.local/bin/env"     # uv

# --- pnpm ---
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac

# --- machine-specific tools (edit/remove for your own setup) ---
export PATH="$HOME/.lmstudio/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export PATH="$JAVA_HOME/bin:$PATH"
export SPARK_HOME=$(brew --prefix apache-spark)/libexec
export PATH="$SPARK_HOME/bin:$PATH"
export PYSPARK_PYTHON=$(brew --prefix python@3.12)/bin/python3.12
export PATH="/opt/homebrew/bin:$PATH"

# --- prompt ---
eval "$(starship init zsh)"
