# ~/.zshrc — interactive shells.
# PATH and other login-time setup lives in ~/.zprofile.

#-------------------------------------------------------------------------------
# History
#-------------------------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000          # entries kept in memory
SAVEHIST=50000          # entries written to disk

setopt APPEND_HISTORY         # add to the history file, never truncate it
setopt INC_APPEND_HISTORY     # write as commands run, not only at exit
setopt SHARE_HISTORY          # new commands are visible in other open shells
setopt HIST_IGNORE_DUPS       # drop a command repeated back-to-back
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicates of a repeated command
setopt HIST_IGNORE_SPACE      # a leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS     # tidy up whitespace before storing
setopt HIST_VERIFY            # expand !! and friends for review, don't run them
setopt EXTENDED_HISTORY       # record timestamp and duration

#-------------------------------------------------------------------------------
# Shell behaviour
#-------------------------------------------------------------------------------

setopt AUTO_CD                # `..` or a bare directory name changes directory
setopt AUTO_PUSHD             # every cd pushes onto the directory stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB          # ^, #, ~ in globs
setopt GLOB_DOTS              # globs match dotfiles too
setopt NO_CASE_GLOB           # case-insensitive globbing
setopt INTERACTIVE_COMMENTS   # allow # comments when typing commands
setopt NO_FLOW_CONTROL        # frees up Ctrl-S / Ctrl-Q
setopt NOTIFY                 # report background job status immediately

unsetopt BEEP

#-------------------------------------------------------------------------------
# Completion
#-------------------------------------------------------------------------------

# Homebrew's completion functions, added before compinit so they're picked up.
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit

# Rebuilding the completion cache on every shell start is slow. Do the full
# security check once a day; use the cached dump otherwise.
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

zmodload -i zsh/complist

# Arrow-key menu for completions.
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Case-insensitive, then partial-word, then substring matching.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*:warnings'     format '%F{red}no matches%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

# Colourise `kill` completion by process.
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Don't offer the file you're already editing, or . / .. for cd.
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#(.|..)'

#-------------------------------------------------------------------------------
# Keybindings
#-------------------------------------------------------------------------------

bindkey -e   # emacs-style; use `bindkey -v` for vi mode

# Search history for what you've already typed.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search      # Up
bindkey '^[[B' down-line-or-beginning-search    # Down
bindkey '^P'   up-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search

bindkey '^[[1;5C' forward-word      # Ctrl-Right
bindkey '^[[1;5D' backward-word     # Ctrl-Left
bindkey '^[[3~'   delete-char       # Delete
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^U'      backward-kill-line
bindkey '^[^?'    backward-kill-word

# In the completion menu, navigate with hjkl and cancel with Escape.
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect '^[' send-break

# Ctrl-X Ctrl-E opens the current command line in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

#-------------------------------------------------------------------------------
# Prompt
#-------------------------------------------------------------------------------

autoload -Uz colors && colors
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' formats       ' %F{magenta}%b%f%F{red}%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta}%b%f %F{yellow}(%a)%f%F{red}%u%c%f'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'

precmd() { vcs_info }

setopt PROMPT_SUBST

# cwd, git branch with dirty markers, and a caret that turns red on failure.
PROMPT='%F{cyan}%~%f${vcs_info_msg_0_}
%(?.%F{green}.%F{red})❯%f '
RPROMPT=''

#-------------------------------------------------------------------------------
# Environment
#-------------------------------------------------------------------------------

export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-R -F -X -i'      # colour, quit-if-one-screen, no clear, ci search
export CLICOLOR=1
export LSCOLORS='ExFxBxDxCxegedabagacad'

# Silence the macOS "default shell is now zsh" notice.
export BASH_SILENCE_DEPRECATION_WARNING=1

#-------------------------------------------------------------------------------
# Aliases
#-------------------------------------------------------------------------------

alias ls='ls -G'
alias ll='ls -Galh'
alias la='ls -Ga'
alias l='ls -G'
alias vim='nvim'
alias vi='nvim'
alias v='nvim'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Guard against accidental clobbering; -i prompts on overwrite.
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'
alias grep='grep --color=auto'

alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'

alias zshrc='$EDITOR ~/.zshrc'
alias reload='exec zsh'
alias path='print -l $path'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'

alias python='python3'
#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------

# Make a directory and cd into it.
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# Extract most archive formats without remembering the flags.
extract() {
  if [[ ! -f "$1" ]]; then
    print -u2 "extract: '$1' is not a file"
    return 1
  fi
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.Z)              uncompress "$1" ;;
    *.7z)             7z x    "$1" ;;
    *)                print -u2 "extract: unknown format '$1'"; return 1 ;;
  esac
}

#-------------------------------------------------------------------------------
# Tools
#-------------------------------------------------------------------------------

# fzf: Ctrl-T files, Ctrl-R history, Alt-C cd. Uses fd so .gitignore is honoured.
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)

  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded --info=inline'

  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
fi

#-------------------------------------------------------------------------------
# Plugins — must come last; both hook into the line editor.
#-------------------------------------------------------------------------------

# Inline suggestion from history; Right-arrow or End accepts it.
if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  bindkey '^ ' autosuggest-accept   # Ctrl-Space accepts without moving the cursor
fi

# Live syntax highlighting. Loads after autosuggestions, per its README.
if [[ -r /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
  source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

#-------------------------------------------------------------------------------
# Local overrides — machine-specific settings, not tracked in dotfiles.
#-------------------------------------------------------------------------------

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
export PATH="$HOME/.local/bin:$PATH"
