# Zsh shell tools for Parrot OS

Helper scripts for setting up and customising a Parrot OS laptop.
## `install-zsh-autocomplete.sh`

Adds ZSH, autocomplete/autosuggestions, and improved command history behaviour.

This script installs and configures `zsh` with:
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- history-based autosuggestions
- menu-style tab completion
- a custom two-line prompt

The script also:
-  backs up any existing `~/.zshrc`
- writes a new `~/.zshrc`
- attempts to set `zsh` as the default shell

### Requirements

- Parrot OS or another Debian-based Linux distribution
- `apt`
- a user account with `sudo` access
### Installation

Clone the repository and run the script:

```bash
git clone https://github.com/ShoreBits/parrot_scripts.git
cd parrot_scripts/zsh
chmod +x install-zsh-autocomplete.sh
./install-zsh-autocomplete.sh
exec zsh
```

### Restore

If you want to restore your previous shell configuration:

```bash
cp ~/.zshrc.bak.YYYYMMDD-HHMMSS ~/.zshrc
exec zsh
```

### Keyboard shortcuts
This setup enables a few useful shell shortcuts:

- Up Arrow / Down Arrow
	Search backward and forward through command history using the text already typed on the line.
- Right Arrow
	Accept the inline autosuggestion shown from command history.
- Tab
	Open the completion menu and select available command or path completions.
	
### Example

If you previously ran:

```bash
git status
git pull
git push
```

and then type:

```bash
git
```

you can:
- press Up or Down to cycle through matching history
- press Right Arrow to accept the inline suggestion
- press Tab to open completion options

## install-command-help.sh

Adds richer command completion and helper functions for learning commands.

Features include:
- improved completion descriptions
- Shift+Tab for reverse completion
- cmdhelp <command> for help and examples
- chelp <command> for --help output
- findhelp `<keyword>` for searching command descriptions
- Alt+h to show help for the command currently being typed

### Installation

From the 'zsh' directory:
```bash
chmod +x install-command-help.sh
./install-command-help.sh
exec zsh
```

### Usage

After installing, you can use:
```bash
cmdhelp tar
chelp ssh
findhelp archive
```

You can also start typing a command and press:
- Alt+h to open help for the command currently on the line
- Shift+Tab to move backward through completion suggestions

### Notes

This script complements `install-zsh-autocomplete.sh` and is intended to make command discovery and help easier while working in Zsh.