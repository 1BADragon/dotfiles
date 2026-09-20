# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt EXTENDED_GLOB         # (#q...) qualifiers, ^ negation, ~ exclusion
setopt INTERACTIVE_COMMENTS  # a pasted command with a trailing # is not an error

HISTFILE="$HOME/.zhistory"
HISTSIZE=500000
SAVEHIST=500000
setopt appendhistory
setopt SHARE_HISTORY         # implies INC_APPEND_HISTORY, so that is not set here
setopt EXTENDED_HISTORY      # record timestamps; worth it at 500k entries
setopt HIST_IGNORE_SPACE     # a leading space keeps a command out of history
setopt HIST_IGNORE_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_VERIFY           # expand !! for review instead of running it blind

fpath=($HOME/.zsh_completions $fpath)

autoload -Uz compinit promptinit

# compinit stats every file in fpath, which is the slowest part of startup.
# Do the full check once a day and load the cached dump the rest of the time;
# -C skips the check entirely. Delete the dump to force a rebuild after
# installing something that ships completions.
_zcomp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_zcomp_dir ]] || mkdir -p $_zcomp_dir
if [[ -n $_zcomp_dir/zcompdump(#qN.mh-24) ]]; then
  compinit -C -d $_zcomp_dir/zcompdump
else
  compinit -d $_zcomp_dir/zcompdump
  # compinit only rewrites the dump when fpath actually changed, so its mtime
  # would otherwise stay stale and every later start would redo the full check.
  touch $_zcomp_dir/zcompdump
fi
promptinit

zstyle ':completion:*' menu select                         # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}      # colour the matches
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_zcomp_dir/compcache"
unset _zcomp_dir

# powerlevel10k installs to a different prefix on every platform: the Arch
# package, Homebrew on Apple silicon, Homebrew on Intel, or a manual clone.
# Source whichever one this machine actually has instead of hardcoding one.
for _p10k in \
  /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme \
  /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme \
  /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme \
  "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"; do
  if [[ -r $_p10k ]]; then
    source $_p10k
    break
  fi
done
unset _p10k

alias ls='ls --color=auto'
alias ll='ls -alh'
alias grep='grep --color=auto'

[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

export EDITOR=hx
export PATH=~/.local/bin:~/.cargo/bin:$PATH

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Every one of these is an Arch package under the same prefix. Sourcing is
# conditional only so that a machine where they are not installed yet still
# gets a working shell rather than an error on every prompt.
_source_plugin() {
  local p=/usr/share/zsh/plugins/$1/$1.zsh
  [[ -r $p ]] || return 1
  source $p
}

# Order is not arbitrary. zsh-syntax-highlighting wants to be sourced after the
# widgets it wraps, so autosuggestions goes first; history-substring-search
# asks to be loaded after syntax highlighting, so it goes last.
_source_plugin zsh-autosuggestions
_source_plugin zsh-syntax-highlighting
if _source_plugin zsh-history-substring-search; then
  # Bind both the terminfo sequences and the raw ones: kitty sends
  # application-mode cursor keys, and terminfo is empty in some contexts.
  zmodload -i zsh/terminfo
  [[ -n ${terminfo[kcuu1]} ]] && bindkey ${terminfo[kcuu1]} history-substring-search-up
  [[ -n ${terminfo[kcud1]} ]] && bindkey ${terminfo[kcud1]} history-substring-search-down
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

unset -f _source_plugin
