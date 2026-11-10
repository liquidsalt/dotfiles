{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # IDEs
    jetbrains.idea
    android-studio

    # Compilers and Interpreters and SDKs
    gcc     # c/c++
    rustc   # rust
    python3 # python
    jdk     # java
    go      # go

    # Package Mangers
    vcpkg # c/c++
    cargo # rust
    uv    # python

    # build tools
    gnumake        # general
    cmake          # c/c++
    unstable.xmake # c/c++

    # Language Servers
    clang-tools                  # c/c++
    rust-analyzer                # rust
    basedpyright ruff            # python
    jdt-language-server          # java
    gopls                        # go
    lua-language-server          # lua
    nixd                         # nix
    bash-language-server         # bash
    fish-lsp                     # fish
    qt6.qtdeclarative            # quickshell
    hyprls                       # hyprlang
    marksman                     # markdown
    taplo                        # toml
    yaml-language-server         # yaml
    vscode-langservers-extracted # json

    # Game Engines
    godot

    # Tools
    tokei
    unstable.claude-code
  ];
}
