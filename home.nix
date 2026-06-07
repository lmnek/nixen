{ config, lib, pkgs, ... }:

{
    home = {
        username = "lmnk";
        homeDirectory = "/home/lmnk";
        stateVersion = "26.05";
        packages = with pkgs; [
            # Apps
            # beeper
            ghostty

            # CLI tools
            yazi
            lazygit
            fish
            starship

            # utils
            ripgrep
            fd
            jq
            eza
            fzf
            unzip

            # binaries your fisher plugins call:
            fd grc
            # yazi previewers/openers:
            ffmpeg p7zip poppler imagemagick
        ];
    };

    programs.zellij.enable = true;

    programs.neovim = {
        enable = true;
        defaultEditor = true;
        sideloadInitLua = true;
        # PATH additions visible ONLY inside nvim (via wrapper), keeps env clean:
        extraPackages = with pkgs; [
            # build toolchain for lazy.nvim build steps & treesitter parser compilation
            gcc gnumake
            # treesitter main branch hard-requires the CLI
            tree-sitter
            # things plugins shell out to
            ripgrep fd git curl unzip
            # your LSPs/formatters/linters — replaces Mason
            lua-language-server
            nixd # or nil — LSP for editing your new .nix files
            stylua
            # pyright, rust-analyzer, gopls, clangd, prettierd, ... whatever you used via Mason
        ];
    };

    programs.alacritty = {
        enable = true;
        settings = {
            font = {
                size = 16.0;
                normal = {
                    family = "JetBrains Mono";
                    style = "Bold";
                };
            };
            terminal = {
                shell = "fish";
            };
        };
    };


    # Symlink farm
    xdg.configFile =
        let
            dotfiles = "${config.home.homeDirectory}/repos/dotfiles/tilde/.config";
        in
            lib.mapAttrs (name: path: {
                source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
                recursive = true;
            }) {
            ghostty = "ghostty";
            fish = "fish";
            starship = "starship.toml";
            yazi = "yazi";
            nvim = "nvim";
            zellij = "zellij";
        };
}
