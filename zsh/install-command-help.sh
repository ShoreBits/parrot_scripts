#!/usr/bin/env bash
set -euo pipefail

info() { printf '\n[+] %s\n' "$*"; }
warn() { printf '\n[!] %s\n' "$*"; }

if ! command -v apt >/dev/null 2>&1; then
  echo "This script is intended for Parrot/Debian-based systems with apt." >&2
  exit 1
fi

info "Installing command help tools"
sudo apt update
sudo apt install -y man-db manpages

ZSHRC="$HOME/.zshrc"
BACKUP="$HOME/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"

if [ -f "$ZSHRC" ]; then
  info "Backing up existing ~/.zshrc to $BACKUP"
  cp "$ZSHRC" "$BACKUP"
else
  touch "$ZSHRC"
fi

BLOCK_START="# >>> parrot command help >>>"
BLOCK_END="# <<< parrot command help <<<"

TMP_BLOCK="$(mktemp)"
cat > "$TMP_BLOCK" <<'EOF'
# >>> parrot command help >>>

# Richer completion display
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for:%f %d'
zstyle ':completion:*:messages' format '%F{cyan}%d%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Shift+Tab: reverse completion menu
bindkey '^[[Z' reverse-menu-complete

cmdhelp() {
    if [ $# -eq 0 ]; then
        echo "Usage: cmdhelp <command>"
        return 1
    fi

    if command -v tldr >/dev/null 2>&1; then
        tldr "$1" 2>/dev/null && return 0
    fi

    man "$1" 2>/dev/null && return 0

    "$1" --help 2>/dev/null | less -R
}

chelp() {
    if [ $# -eq 0 ]; then
        echo "Usage: chelp <command>"
        return 1
    fi

    "$1" --help 2>/dev/null | less -R
}

findhelp() {
    if [ $# -eq 0 ]; then
        echo "Usage: findhelp <keyword>"
        return 1
    fi

    apropos "$*" 2>/dev/null || man -k "$*"
}

show_command_help_widget() {
    local cmd
    cmd="${BUFFER%% *}"

    if [ -z "$cmd" ]; then
        zle -M "Type a command first, then press Alt+h"
        return 0
    fi

    zle -I
    echo
    cmdhelp "$cmd"
    echo
    zle reset-prompt
}

zle -N show_command_help_widget
bindkey '^[h' show_command_help_widget

alias manfind='apropos'

# <<< parrot command help <<<
EOF

if grep -qF "$BLOCK_START" "$ZSHRC"; then
  info "Replacing existing command help block in ~/.zshrc"
  python3 - "$ZSHRC" "$TMP_BLOCK" <<'PY'
from pathlib import Path
import sys

zshrc = Path(sys.argv[1])
block_file = Path(sys.argv[2])

text = zshrc.read_text()
block = block_file.read_text()

start = "# >>> parrot command help >>>"
end = "# <<< parrot command help <<<"

before, rest = text.split(start, 1)
_, after = rest.split(end, 1)

zshrc.write_text(before + block + after)
PY
else
  info "Appending command help block to ~/.zshrc"
  printf '\n' >> "$ZSHRC"
  cat "$TMP_BLOCK" >> "$ZSHRC"
fi

rm -f "$TMP_BLOCK"

info "Updating man page database"
sudo mandb >/dev/null 2>&1 || warn "Could not update mandb automatically"

info "Done"
echo "Start a new shell with: exec zsh"
echo
echo "Then try:"
echo "  cmdhelp tar"
echo "  chelp ssh"
echo "  findhelp archive"
echo "  Type a command and press Alt+h"
echo "  Use Shift+Tab to reverse through completions"