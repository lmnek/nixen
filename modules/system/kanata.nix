# Kanata keyboard remapper.
{ pkgs, ... }:

{
    environment.systemPackages = [ pkgs.kanata ];

    # kanata writes to a virtual keyboard via /dev/uinput
    hardware.uinput.enable = true;
    boot.kernelModules = [ "uinput" ];
    users.groups.uinput = { };

    # merged into the user's extraGroups defined in default.nix
    users.users.lmnk.extraGroups = [
        "input"
        "uinput"
    ];
}
