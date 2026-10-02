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

# .zcompdump caches which completion function handles which command.
# A full compinit scans $fpath and audits it for security issues before
# trusting the cache, which is slow. This runs the full check at most once
# every 24 hours and loads the cache directly otherwise.
#
# - '#q' enables glob qualifiers inside [[ ]]
# - 'N' expands to nothing instead of erroring when no match
# - '.' matches regular files only
# - 'mh+24' matches files modified more than 24 hours ago
autoload -Uz compinit
setopt extendedglob
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
  touch ~/.zcompdump # Updates the dumps timestamp
else
  compinit -C
fi

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

# ZSH Vi Mode
_clone_plugin https://github.com/jeffreytse/zsh-vi-mode
ZVM_SYSTEM_CLIPBOARD_ENABLED=true
ZVM_VI_HIGHLIGHT_BACKGROUND=#eceff4
ZVM_VI_HIGHLIGHT_FOREGROUND=#4c566a
source "$ZSH_PLUGINS/zsh-vi-mode/zsh-vi-mode.zsh"

# Rebinding p/P to use the system clipboard
function zvm_after_init() {
  zvm_bindkey vicmd 'p' zvm_paste_clipboard_after
  zvm_bindkey vicmd 'P' zvm_paste_clipboard_before
  zvm_bindkey visual 'p' zvm_visual_paste_clipboard
  zvm_bindkey visual 'P' zvm_visual_paste_clipboard
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
alias grc="nvim ~/.config/ghostty/config.ghostty"
alias lrc="nvim ~/.localrc"
alias trc="nvim ~/.config/tmux/tmux.conf"
alias zrc="nvim ~/.zshrc"
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
