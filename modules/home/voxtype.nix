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
in
{
    # Upstream module: installs the package, writes
    # ~/.config/voxtype/config.toml and the systemd user service
    imports = [ inputs.voxtype.homeManagerModules.default ];

    # Recording-state overlay ([osd] enabled by default). The daemon's
    # dispatcher finds this frontend via PATH.
    home.packages = [ inputs.voxtype.packages.${sys}.osd-gtk4 ];

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

            # soniox streaming only works in toggle mode (PTT gets
            # auto-promoted anyway; this silences the warning)
            hotkey.mode = "toggle";
        };
    };

    # soniox reads SONIOX_API_KEY from env; user services don't
    # inherit shell env. Put `SONIOX_API_KEY=...` in this file
    # (chmod 600, never in the repo -> nix store is world-readable)
    systemd.user.services.voxtype.Service.EnvironmentFile = "%h/.config/voxtype/secrets.env";
}
