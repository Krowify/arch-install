# >>> linux-installation dotfiles (stage 6) >>>
# Managed by 6-dotfiles.sh -- safe to edit, this block is only ever
# appended once (guarded by the marker comments above/below).

# zsh-syntax-highlighting must be sourced LAST of the plugins below
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /etc/profile.d/autojump.sh ]] && source /etc/profile.d/autojump.sh

[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ll='ls -lah'
alias grep='grep --color=auto'

export EDITOR=vim
export TERMINAL=alacritty
# <<< linux-installation dotfiles (stage 6) <<<
