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

choose_theme() {
  local choice
  echo
  echo "Choose a zsh prompt theme:"
  echo "  1) Cyan   (default)"
  echo "  2) Red"
  echo "  3) Green"
  echo "  4) Yellow"
  echo "  5) Blue"
  echo "  6) Magenta"
  echo
  read -r -p "Enter choice [1-6] (default 1): " choice

  case "${choice:-1}" in
    1) THEME_NAME="Cyan";    BRACKET_COLOR="cyan";    USERHOST_COLOR="cyan";    PATH_COLOR="green" ;;
    2) THEME_NAME="Red";     BRACKET_COLOR="red";     USERHOST_COLOR="cyan";    PATH_COLOR="green" ;;
    3) THEME_NAME="Green";   BRACKET_COLOR="green";   USERHOST_COLOR="cyan";    PATH_COLOR="yellow" ;;
    4) THEME_NAME="Yellow";  BRACKET_COLOR="yellow";  USERHOST_COLOR="cyan";    PATH_COLOR="green" ;;
    5) THEME_NAME="Blue";    BRACKET_COLOR="blue";    USERHOST_COLOR="cyan";    PATH_COLOR="green" ;;
    6) THEME_NAME="Magenta"; BRACKET_COLOR="magenta"; USERHOST_COLOR="cyan";    PATH_COLOR="green" ;;
    *) warn "Invalid choice, defaulting to Cyan"
       THEME_NAME="Cyan";    BRACKET_COLOR="cyan";    USERHOST_COLOR="cyan";    PATH_COLOR="green" ;;
  esac
}

choose_theme

info "Writing new ~/.zshrc with theme: $THEME_NAME"
cat > "$ZSHRC" <<ZSHRC_EOF
autoload -Uz compinit colors
compinit
colors

bindkey -e

setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

HISTFILE=\$HOME/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_USE_ASYNC=true

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "\$terminfo[kcuu1]" up-line-or-beginning-search
bindkey "\$terminfo[kcud1]" down-line-or-beginning-search

# Prompt theme selected during install
PARROT_PROMPT_THEME="${THEME_NAME}"
PARROT_PROMPT_BRACKET_COLOR="${BRACKET_COLOR}"
PARROT_PROMPT_USERHOST_COLOR="${USERHOST_COLOR}"
PARROT_PROMPT_PATH_COLOR="${PATH_COLOR}"

build_prompt() {
    local symbol='\$'
    [[ \$EUID -eq 0 ]] && symbol='#'

    PROMPT="%F{\${PARROT_PROMPT_BRACKET_COLOR}}┌─[%f%F{\${PARROT_PROMPT_USERHOST_COLOR}}%n@%m%f%F{\${PARROT_PROMPT_BRACKET_COLOR}}]─[%f%F{\${PARROT_PROMPT_PATH_COLOR}}%~%f%F{\${PARROT_PROMPT_BRACKET_COLOR}}]%f
%F{\${PARROT_PROMPT_BRACKET_COLOR}}└──╼ %f\$symbol "
}

precmd() {
    build_prompt
}
ZSHRC_EOF

if [ "${SHELL:-}" != "/bin/zsh" ]; then
  info "Setting zsh as your default shell"
  chsh -s /bin/zsh || warn "Could not change default shell automatically. Run: chsh -s /bin/zsh"
fi

info "Done"
echo "Installed theme: $THEME_NAME"
echo "Start a new shell with: exec zsh"
echo "Or log out and back in to use zsh as your default shell."