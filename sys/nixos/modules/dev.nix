{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Compilers/Interpreters
    clang   # c/c++
    rustc   # rust
    python3 # python
    jdk     # java
    go      # go

    # Build Tools
    unstable.xmake # c/c++
    cargo          # rust
    uv             # python

    # Language Servers
    clang-tools                  # c/c++
    rust-analyzer                # rust
    basedpyright ruff            # python
    jdt-language-server          # java
    lua-language-server          # lua
    nixd                         # nix
    bash-language-server         # bash
    qt6.qtdeclarative            # quickshell

    # IDEs
    jetbrains.idea
    android-studio

    # Game Engines
    godot

    # Tools
    tokei
    unstable.claude-code
  ];
}
