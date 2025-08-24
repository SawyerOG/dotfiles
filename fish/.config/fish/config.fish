# ~/.config/fish/config.fish

# No welcome message
set -g fish_greeting ""

# Add Go to PATH
set -gx GOPATH "$HOME/go"
fish_add_path -g "$GOPATH/bin"
fish_add_path -g "/usr/local/go/bin"
fish_add_path -g "/usr/lib/go/bin"

# Shorten path function
function fish_prompt
    # Get current working directory and shorten ~ to ~
    set -l cwd (prompt_pwd)

    # Optional: shorten home to ~
    set cwd (string replace "$HOME" $cwd)

    # Show prompt
    echo -n "> $cwd "
end
