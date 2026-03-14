#!/usr/bin/env bash
set -euo pipefail

info() { printf '\n[+] %s\n' "$*"; }
warn() { printf '\n[!] %s\n' "$*"; }

if ! command -v apt >/dev/null 2>&1; then
  echo "This script is intended for Parrot/Debian-based systems with apt." >&2
  exit 1
fi

info "Installing zsh and zsh plugins"
sudo apt update
sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting

ZSHRC="$HOME/.zshrc"
BACKUP="$HOME/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"

if [ -f "$ZSHRC" ]; then
  info "Backing up existing ~/.zshrc to $BACKUP"
  cp "$ZSHRC" "$BACKUP"
fi

info "Writing new ~/.zshrc"
cat > "$ZSHRC" <<'ZSHRC_EOF'
autoload -Uz compinit colors
compinit
colors

setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

HISTSIZE=5000
SAVEHIST=5000

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "$terminfo[kcuu1]" up-line-or-beginning-search
bindkey "$terminfo[kcud1]" down-line-or-beginning-search

build_prompt() {
    local symbol='$'
    [[ $EUID -eq 0 ]] && symbol='#'
    PROMPT=$'%F{81}┌─[%f%F{47}%n@%m%f%F{81}]─[%f%F{39}%~%f%F{81}]%f\n%F{81}└──╼ %f'"$symbol "
}
precmd_functions=(build_prompt)
ZSHRC_EOF

if [ "${SHELL:-}" != "/bin/zsh" ]; then
  info "Setting zsh as your default shell"
  chsh -s /bin/zsh || warn "Could not change default shell automatically. Run: chsh -s /bin/zsh"
fi

info "Done"
echo "Start a new shell with: exec zsh"
echo "Or log out and back in to use zsh as your default shell."
