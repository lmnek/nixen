
Backup noctalia & niri configs (-> play around)

Migration:
- symlink rest of programs
- functional neovim - LSPs
- go through apps from arch
- emoji picker, keybinds for pickers, ...
- scratchpads & named workspaces
- commit rest of old files
- obsidian

Fixes:
- zellij ressurection - see: https://www.reddit.com/r/NixOS/comments/1b9o3hs/zellij_session_resurrection_help/
- zen browser -> missing configuration:
    * missing keybinds!!! - ctrl+c, ctrl+b, switching workspaces
    * positions on tab (e.g. extension placements, etc...)
    * colors per workspace (commented out now)
    * set container per workspace

improvements:
- Formatter on save for nix (nixfmt-rfc-style + conform.nvim)
- enable hibernate
- combine nixen and dotfiles:
    - claude --resume 118571e1-3e71-4af4-b5fc-b9d98a87307f
