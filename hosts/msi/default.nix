# Host entry point for "msi" — picks which modules this machine uses
# and holds the few settings that are genuinely specific to this box.
{ inputs, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./disko.nix
        ../../modules/system
    ];

    networking.hostName = "msi";

    # ---------- Home Manager (wired as a NixOS module) ----------
    # A single `nixos-rebuild switch` now applies both system and home.
    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users.lmnk.imports = [ ../../modules/home ];
    };

    # Never change this!!!
    system.stateVersion = "26.05";
}
