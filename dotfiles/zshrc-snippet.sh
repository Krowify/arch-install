# >>> linux-installation dotfiles (stage 5) >>>
# Managed by 5-dotfiles.sh -- safe to edit, this block is only ever
# appended once (guarded by the marker comments above/below).

# zsh-syntax-highlighting must be sourced LAST of the plugins below
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /etc/profile.d/autojump.sh ]] && source /etc/profile.d/autojump.sh

[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh

# --cmd cd makes zoxide take over the 'cd' command itself (still does
# normal exact-path cd, but also learns/fuzzy-matches over time) instead
# of only adding a separate 'z' command alongside it
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

alias ll='ls -lah'
alias grep='grep --color=auto'

# -b makes kate block until the document is closed, which tools that
# shell out to $EDITOR (git commit, crontab -e, visudo, ...) require
export EDITOR="kate -b"
export TERMINAL=alacritty

command -v fastfetch >/dev/null 2>&1 && fastfetch

# starship replaces the zsh prompt entirely -- keep this last so nothing
# below it can override $PROMPT/$PS1 out from under it
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# <<< linux-installation dotfiles (stage 5) <<<
