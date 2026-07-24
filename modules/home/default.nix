{
config,
lib,
pkgs,
inputs,
...
}:

{
    imports = [
        ./neovim.nix
        ./symlinks.nix
        ./slack.nix
        ./voxtype.nix
        inputs.nix-index-database.homeModules.default
    ];

    # `,` runs any nixpkgs program without installing 🌟
    # -> uses a prebuilt nix-index database -> no slow local index build
    programs.nix-index-database.comma.enable = true;

    # username and homeDirectory are supplied automatically by the
    # home-manager NixOS module (from users.users.lmnk in the system config)
    home = {
        stateVersion = "26.05";

        # User-level env vars, set once at login
        sessionVariables = {
            TERMINAL = "ghostty";
            PAGER = "less";
            LESS = "-R"; # keep colors when paging
            # EDITOR already set by neovim option
        };

        packages =
            (with pkgs; [
                # Desktop
                ghostty
                fuzzel # launcher
                swaybg # wallpaper
                libnotify # notify-send
                cliphist wl-clipboard wl-clip-persist # clipboard
                ripdrag
                wtype # text injection backend for handy/voxtype
                flameshot grim # screenshots

                # Apps
                obsidian
                beeper
                morgen
                handy
                nsxiv
                teams-for-linux
                mpv
                obs-studio
                vesktop # discord
                # todoist # -> need appimage?
                # gwenview

                # CLI tools
                yazi
                lazygit
                delta
                lazydocker
                starship
                manix # fast offline search of nixpkgs/NixOS option docs
                libqalculate # qalc

                # utils
                ripgrep
                fd
                jq
                eza
                fzf
                unzip
                zip

                # depencies
                grc # fisher plugins call it
                ffmpeg
                p7zip
                poppler
                imagemagick # yazi previewers/openers

                # dev
                nodejs # node, npm, npx
                yarn
                python3 uv
                dbeaver-bin
            ])
            ++ (
                # Packages that come from flake inputs
                let
                    sys = pkgs.stdenv.hostPlatform.system;
                in
                    [
                    inputs.noctalia.packages.${sys}.default # desktop shell
                    # inputs.sone.packages.${sys}.default # native TIDAL client

                    # llm tools
                    inputs.llm-agents.packages.${sys}.claude-code
                    inputs.llm-agents.packages.${sys}.codex
                ]
            );
    };

    # Auto-loads per-project dev shells on `cd` + nix-direnv cachin
    # Drop a `.envrc` with `use flake` in a project dir and run `direnv allow`
    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };

    # Polyglot runtime/tool manager (the workplace standard). Installs prebuilt
    # binaries for node/python/uv/… which run thanks to nix-ld + envfs (see
    # modules/system/dev.nix). Shell integration adds its shims to PATH.
    programs.mise.enable = true;

    programs.zellij.enable = true;

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
}
