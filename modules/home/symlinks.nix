# Out-of-store symlinks to live dotfiles in ~/repos/dotfiles.
# Editing those files takes effect immediately — no rebuild needed.
{ config, lib, ... }:

{
    xdg.configFile =
        let
            dotfiles = "${config.home.homeDirectory}/repos/dotfiles/tilde/.config";
        in
            lib.genAttrs
        [
            "ghostty"
            "fish"
            "starship.toml"
            "yazi"
            "nvim"
            "zellij"
            "lazygit"
            "niri"
            "noctalia"
            "claude"
            "fastfetch"
        ]
        (path: {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
            recursive = true;
        });
}
