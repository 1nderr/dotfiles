# .localrc is used for config that is specific to the machine
if [[ -f ~/.localrc ]]; then
  source ~/.localrc
else
  touch ~/.localrc
fi

# ============================================================
# SECTION 1: ENVIRONMENT
# ============================================================

export BAT_THEME="Nord"

# Prevents pip from installing modules globally
export PIP_REQUIRE_VIRTUALENV=true

# Makes Neovim the default editor
export EDITOR=nvim
export VISUAL=nvim

# ============================================================
# SECTION 2: OPTIONS
# ============================================================

# Writes history to a file instead of memory
HISTFILE=~/.zsh_history

# Sets the history to save up to 100000 commands
HISTSIZE=100000
SAVEHIST=$HISTSIZE

# Writes commands immediately to history file which allows multiple
# shells to share history
setopt sharehistory

# Ignores and prevents duplicate commands
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Ignores commands that start with space
setopt hist_ignore_space

# Enables globs to match hidden files and directories
setopt globdots

# Ignores ctrl+D and EOF to prevent accidental exits
setopt ignoreeof

# ============================================================
# SECTION 3: TOOL INITIALIZATION
# ============================================================

autoload -Uz compinit
compinit
eval "$(~/.local/bin/mise activate zsh)"
source <(fzf --zsh)
eval "$(zoxide init zsh --cmd cd)"

# Used for tmux-sessionizer
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi

# ============================================================
# SECTION 4: PLUGINS
# ============================================================

ZSH_PLUGINS="${XDG_DATA_HOME:-${HOME}/.local/share}/zsh-plugins"
mkdir -p "$ZSH_PLUGINS"

_clone_plugin() {
  local url="$1"
  local dir="$ZSH_PLUGINS/${url##*/}"
  [ -d "$dir" ] || git clone "$url" "$dir"
}

# FZF Tab
_clone_plugin https://github.com/Aloxaf/fzf-tab
source "$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"

# Enables multi-select in the fzf window
zstyle ':fzf-tab:*' fzf-bindings 'tab:toggle'

# History Substring Search
_clone_plugin https://github.com/zsh-users/zsh-history-substring-search
source "$ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh"

# Turns off highlighting of the substring that was typed in
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=''

# Binds up and down arrows to use substring search when going through history
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

# ============================================================
# SECTION 5: PROMPT
# ============================================================

# Loads add-zsh-hook and vcs_info from the fpath.
# add-zsh-hook lets you run functions when shell events are emitted
# vcs_info gives you version control information
autoload -Uz add-zsh-hook vcs_info

# Limits vcs_info to only check if the current dir is a git repo to
# save it from executing extra checks
zstyle ':vcs_info:*' enable git

# Sets the format to [main]. 6 is cyan, %b gives the branch
# Sets the action format [main|rebase-i]. %a gives the action
zstyle ':vcs_info:*' formats ' %F{6}[%b]%f'
zstyle ':vcs_info:*' actionformats ' %F{6}[%b|%a]%f'

# Runs vcs_info before every prompt render
add-zsh-hook precmd vcs_info

# An option that enables the expanding of variables within the prompt
setopt prompt_subst

PROMPT=$'\n%F{4}%n%f' # 4 is blue, %n gives the user name

# If using ssh, add some text to the prompt to indicate that
if [ -n "$SSH_CLIENT" ] && [ -n "$SSH_TTY" ]; then
  PROMPT+='%F{1}[ssh]%f' # 1 is red
fi

PROMPT+=' %F{2}%4(~|…/%3~|%~)%f' # 2 is green, path shortens to 3 directories
PROMPT+='${vcs_info_msg_0_}'
PROMPT+=$'\n%F{5}→%f ' # 5 is magenta

# ============================================================
# SECTION 6: ALIASES
# ============================================================
alias cat="bat -pp"
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias grc="vi ~/.config/ghostty/config.ghostty"
alias lrc="vi ~/.localrc"
alias trc="vi ~/.config/tmux/tmux.conf"
alias zrc="vi ~/.zshrc"
alias ls="ls -A --color=auto"
alias rl="exec zsh"
alias tl="tmux source ~/.config/tmux/tmux.conf"
alias -s {md,json,toml,yaml,yml,txt,conf,cfg,ini,env,properties}="cat"
alias -s {png,jpg,jpeg,gif,webp,bmp,svg,avif,heic,heif,ico}="chafa"
alias -s git="git clone"

# ============================================================
# SECTION 7: START UP
# ============================================================

# If not already using tmux, then reconnect to the last session
# or create a new session. Does not attach to tmux in ssh
if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
  test -z "$TMUX" && (tmux attach || tmux new-session)
fi
