# Steam and gaming. Imported by modules/system/default.nix.
# Note: 32-bit graphics (hardware.graphics.enable32Bit) in the main system module.
{ pkgs, ... }:

{
    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    nixpkgs.overlays = [
        (final: prev: {
            steam = prev.steam.override {
                extraArgs = "-cef-disable-gpu-compositing";
            };
        })
    ];

    programs.gamescope.enable = true;
    programs.gamemode.enable = true;
}
