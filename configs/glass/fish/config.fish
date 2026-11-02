set -g fish_greeting # no welcome banner

set -gx EDITOR nvim
set -gx SUDO_EDITOR nvim

abbr -a cddev 'cd ~/projects/dev'

if status is-interactive
    starship init fish | source
end
