#!/usr/bin/env bash
set -euo pipefail

info() { printf '\n[+] %s\n' "$*"; }
warn() { printf '\n[!] %s\n' "$*"; }

if ! command -v apt >/dev/null 2>&1; then
  echo "This script is intended for Parrot/Debian-based systems with apt." >&2
  exit 1
fi

ZSH_BIN="/usr/bin/zsh"
if [ ! -x "$ZSH_BIN" ]; then
  ZSH_BIN="/bin/zsh"
fi

CURRENT_USER="${SUDO_USER:-$USER}"
CURRENT_HOME="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"
if [ -z "${CURRENT_HOME:-}" ]; then
  CURRENT_HOME="$HOME"
fi

ZSHRC="$CURRENT_HOME/.zshrc"
BACKUP="$CURRENT_HOME/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"

ensure_zsh_in_shells() {
  if ! grep -qx "$ZSH_BIN" /etc/shells 2>/dev/null; then
    info "Adding $ZSH_BIN to /etc/shells"
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  fi
}

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

choose_install_mode() {
  local choice
  echo
  echo "Choose install scope:"
  echo "  1) Current user only"
  echo "  2) System default for newly created users"
  echo "  3) System default for new users + change all existing normal users"
  echo
  read -r -p "Enter choice [1-3] (default 1): " choice

  case "${choice:-1}" in
    1) INSTALL_MODE="current" ;;
    2) INSTALL_MODE="system_default" ;;
    3) INSTALL_MODE="system_all" ;;
    *) warn "Invalid choice, defaulting to current user only"
       INSTALL_MODE="current" ;;
  esac
}

write_zshrc() {
  local target_zshrc="$1"
  local target_user="$2"

  if [ -f "$target_zshrc" ]; then
    local backup_file="${target_zshrc}.bak.$(date +%Y%m%d-%H%M%S)"
    info "Backing up existing $target_zshrc to $backup_file"
    sudo cp "$target_zshrc" "$backup_file"
    sudo chown "$target_user":"$target_user" "$backup_file" 2>/dev/null || true
  fi

  info "Writing new $target_zshrc with theme: $THEME_NAME"
  sudo tee "$target_zshrc" >/dev/null <<ZSHRC_EOF
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

  sudo chown "$target_user":"$target_user" "$target_zshrc" 2>/dev/null || true
}

set_shell_for_user() {
  local user_name="$1"
  info "Setting zsh as default shell for user: $user_name"
  sudo usermod -s "$ZSH_BIN" "$user_name" || warn "Could not change shell for $user_name"
}

set_system_default_shell() {
  info "Setting system default shell for newly created users to $ZSH_BIN"
  sudo useradd -D -s "$ZSH_BIN"
}

set_adduser_default_shell() {
  info "Setting adduser default shell to $ZSH_BIN in /etc/adduser.conf"

  if grep -q '^DSHELL=' /etc/adduser.conf; then
    sudo sed -i "s|^DSHELL=.*|DSHELL=$ZSH_BIN|" /etc/adduser.conf
  elif grep -q '^#DSHELL=' /etc/adduser.conf; then
    sudo sed -i "s|^#DSHELL=.*|DSHELL=$ZSH_BIN|" /etc/adduser.conf
  else
    echo "DSHELL=$ZSH_BIN" | sudo tee -a /etc/adduser.conf >/dev/null
  fi
}

copy_to_skel() {
  info "Copying default .zshrc to /etc/skel for future users"
  sudo cp "$ZSHRC" /etc/skel/.zshrc
}

set_shell_for_existing_normal_users() {
  info "Changing shell for all existing normal users"
  getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' | while read -r user_name; do
    sudo usermod -s "$ZSH_BIN" "$user_name" || warn "Could not change shell for $user_name"
  done
}

info "Installing zsh and zsh plugins"
sudo apt update
sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting

ensure_zsh_in_shells
choose_theme
choose_install_mode

write_zshrc "$ZSHRC" "$CURRENT_USER"

case "$INSTALL_MODE" in
  current)
    set_shell_for_user "$CURRENT_USER"
    ;;
  system_default)
    set_system_default_shell
    set_adduser_default_shell
    copy_to_skel
    set_shell_for_user "$CURRENT_USER"
    ;;
  system_all)
    set_system_default_shell
    set_adduser_default_shell
    copy_to_skel
    set_shell_for_existing_normal_users
    ;;
esac

info "Done"
echo "Installed theme: $THEME_NAME"
echo "Install mode: $INSTALL_MODE"
echo "Start a new shell with: exec zsh"
echo "Or log out and back in to use zsh as your default shell."