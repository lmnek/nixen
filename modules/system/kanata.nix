# Kanata keyboard remapper, run as a systemd service (kanata-msi.service).
{ lib, pkgs, ... }:

{
    # The kanata CLI on PATH (for `kanata --check ...` etc.).
    environment.systemPackages = [ pkgs.kanata ];

    # The service brings its own kanata copy + enables kernel uinput, etc...
    services.kanata = {
        enable = true;
        keyboards.msi = {
            configFile = "/home/lmnk/repos/dotfiles/tilde/.config/kanata/kanata.kbd";
        };
    };

    systemd.services.kanata-msi.serviceConfig = {
        ProtectHome = lib.mkForce "tmpfs";
        BindReadOnlyPaths = [ "/home/lmnk/repos/dotfiles/tilde/.config/kanata" ];
    };

    users.users.lmnk.extraGroups = [
        "input"
        "uinput"
    ];
}
