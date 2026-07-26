# Out-of-store symlinks to live dotfiles in ~/repos/dotfiles.
# Editing those files takes effect immediately — no rebuild needed.
{ config, lib, ... }:

{
    home.file.".local/bin".source =
        config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/repos/dotfiles/tilde/.local/bin";

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
