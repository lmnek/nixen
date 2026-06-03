{ config, pkgs, ... }:

{
    home = {
        username = "lmnk";
        homeDirectory = "/home/lmnk";
        stateVersion = "23.11";
        packages = with pkgs; [
            ripgrep
            fd
            jq
            eza
            fzf
            lf
            starship
            fish
        ];
    };

    programs.alacritty = {
        enable = true;
        settings = {
            font = {
                size = 13.0;
                normal = {
                    family = "JetBrains Mono";
                    style = "Bold";
                };
            };
            shell = "fish";
        };
    };

# Symlink the entire .config directory
# home.file.".config".source = ./dotfiles/.config;

    xdg.configFile = {
        nvim = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/dotfiles/.config/nvim";
            recursive = true;
        };
        zellij = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/dotfiles/.config/zellij";
            recursive = true;
        };
        fish = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/dotfiles/.config/fish";
            recursive = true;
        };
        starship.source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/dotfiles/.config/starship.toml";
    };
}
