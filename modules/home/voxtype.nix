{ pkgs, inputs, ... }:

let
    sys = pkgs.stdenv.hostPlatform.system;

    # default = symlinkJoin wrapper -> must override the unwrapped
    # build; wrapper only adds runtime tools to PATH (wtype etc.,
    # which we install ourselves in default.nix)
    voxtype = inputs.voxtype.packages.${sys}.voxtype-unwrapped.overrideAttrs (old: {
        cargoBuildFeatures = (old.cargoBuildFeatures or []) ++ [ "soniox" ];
        cargoCheckFeatures = (old.cargoCheckFeatures or []) ++ [ "soniox" ];
    });

    # Preconfigured upstream OSD look; swap the filename to experiment:
    # - showcase-orbit        frameless circular badge, breathing rings
    # - showcase-signal-stack wide strip, waveform + ghost echo trace
    # - showcase-bars         wide panel, vertical bar meter + peak rail
    # - showcase-prism-scope  square panel: ring, waveform, bars, meter
    recipe = builtins.fromTOML (builtins.readFile
        "${inputs.voxtype}/examples/osd-recipes/showcase-orbit.toml");
in
{
    # Upstream module: installs the package, writes
    # ~/.config/voxtype/config.toml and the systemd user service
    imports = [ inputs.voxtype.homeManagerModules.default ];

    # Recording-state overlay ([osd] enabled by default) uses the
    # quickshell frontend (the only riceable one); qs found via PATH,
    # QML tree via env var below
    home.packages = [ pkgs.quickshell ];

    programs.voxtype = {
        enable = true;
        package = voxtype;
        service.enable = true;
        settings = {
            # set via settings: the module's `engine` option enum
            # doesn't know soniox (yet), but settings wins in the
            # generated toml
            engine = "soniox";
            soniox.language_hints = [ "cs" "en" ];

            # default caps a session at 60s; streaming soniox can go much longer
            audio.max_duration_secs = 900;

            # soniox streaming only works in toggle mode (PTT gets
            # auto-promoted anyway; this silences the warning)
            hotkey.mode = "toggle";

            # fallback = built-in palette (recipes default to omarchy,
            # which we don't run)
            osd = recipe.osd // { palette = "fallback"; };
        };
    };

    # soniox reads SONIOX_API_KEY from env; user services don't
    # inherit shell env. Put `SONIOX_API_KEY=...` in this file
    # (chmod 600, never in the repo -> nix store is world-readable)
    systemd.user.services.voxtype.Service.EnvironmentFile = "%h/.config/voxtype/secrets.env";

    # QML tree for the quickshell OSD, straight from the flake source
    systemd.user.services.voxtype.Service.Environment = [
        "VOXTYPE_OSD_QML_PATH=${inputs.voxtype}/quickshell"
    ];
}
