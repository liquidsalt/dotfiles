{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Compilers/Interpreters
    clang   # c/c++
    zig     # zig
    rustc   # rust
    python3 # python
    jdk     # java

    # Build Tools
    unstable.xmake # c/c++
    cargo          # rust
    uv             # python

    # Language Servers
    clang-tools                  # c/c++
    zls                          # zig
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
  ];
}
