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
        ./mime.nix
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
            VISUAL = "nvim";
            # binary name, not package name -- xdg-open execs $BROWSER directly
            BROWSER = "zen-beta";
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
                wtype # text injection backend for voxtype
                flameshot grim # screenshots

                # Apps
                obsidian
                beeper
                morgen
                nsxiv
                teams-for-linux
                mpv
                obs-studio
                vesktop # discord
                vscodium
                pinta
                kdePackages.gwenview
                # todoist # -> need appimage?

                # PDF (yazi's display_pdf chain)
                zathura
                kdePackages.okular
                xournalpp
                pdfarranger pdfmixtool

                # CLI tools
                yazi ouch
                lazygit delta
                lazydocker
                starship
                manix # fast offline search of nixpkgs/NixOS option docs
                ani-cli # anime streaming (needs mpv, above)
                visidata # vd
                (llm.withPlugins { llm-openrouter = true; }) # simonw's LLM cli
                libqalculate # qalc

                # utils
                ripgrep
                fd
                jq
                eza
                fzf
                unzip
                zip
                file # mime detection; was only in yazi's wrapper before
                glib # gio -- xdg-open's fallback when no default is set
                dust duf # du / df
                procs # ps
                xh # http client
                doggo # DNS

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
                svelte-language-server
                dbeaver-bin
            ])
            ++ (
                # Packages that come from flake inputs
                let
                    sys = pkgs.stdenv.hostPlatform.system;

                    # ponytail: hard cap, not a fix — claude-code leaks off-heap
                    # memory while idle and can reach 20+ GB in minutes
                    # (anthropics/claude-code#67433), which OOMs the whole
                    # desktop. The cgroup kills the runaway session alone;
                    # transcripts survive on disk, so `claude --resume` recovers.
                    # Drop this wrapper once upstream fixes the leak.
                    claude-capped = pkgs.writeShellScriptBin "claude" ''
                        exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect \
                            -p MemoryMax=8G -p MemorySwapMax=2G \
                            ${inputs.llm-agents.packages.${sys}.claude-code}/bin/claude "$@"
                    '';
                in
                    [
                    inputs.noctalia.packages.${sys}.default # desktop shell
                    # inputs.sone.packages.${sys}.default # native TIDAL client

                    # llm tools
                    claude-capped
                    inputs.llm-agents.packages.${sys}.codex
                    inputs.llm-agents.packages.${sys}.herdr # agent-aware multiplexer
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
