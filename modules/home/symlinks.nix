# Out-of-store symlinks to live dotfiles in ~/repos/dotfiles.
# Editing those files takes effect immediately — no rebuild needed.
{ config, lib, ... }:

{
    xdg.configFile =
        let
            dotfiles = "${config.home.homeDirectory}/repos/dotfiles/tilde/.config";
        in
            lib.mapAttrs
        (name: path: {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
            recursive = true;
        })
        {
            ghostty = "ghostty";
            fish = "fish";
            starship = "starship.toml";
            yazi = "yazi";
            nvim = "nvim";
            zellij = "zellij";
        };
}
