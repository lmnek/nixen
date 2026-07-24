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

    # disable Panel Self Refresh -> avoid screen glitches
    # NOTE: could be fixed in future kernels
    boot.kernelParams = [ "xe.enable_panel_replay=0" ]; # boots, fallback to PSR2
    # boot.kernelParams = [ "xe.enable_psr=0" "xe.enable_panel_replay=0" ]; # didnt try yet
    # boot.kernelParams = [ "xe.enable_psr=0" ]; # boots but doesnt fix - WARNING: shorter battery time!
    # boot.kernelParams = [ "xe.enable_psr=0" "xe.enable_psr2_sel_fetch=0" ]; # freezes login page

    # ---------- Home Manager (wired as a NixOS module) ----------
    # A single `nixos-rebuild switch` now applies both system and home.
    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        # Rename any pre-existing, unmanaged file HM wants to own to
        # "<name>.hm-backup" instead of aborting the switch. Needed the first
        # time the Zen module takes over an existing ~/.config/zen profile.
        backupFileExtension = "hm-backup";
        users.lmnk.imports = [ ../../modules/home ];
    };

    # Never change this!!!
    system.stateVersion = "26.05";
}
