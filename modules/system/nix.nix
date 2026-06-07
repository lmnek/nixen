# Nix daemon configuration: features, binary caches, garbage collection.

{ ... }:

{
    nix.settings.experimental-features = [
        "nix-command"
        "flakes"
    ];
    nixpkgs.config.allowUnfree = true;

    # Binary caches. Declared here (not in flake.nix nixConfig) so they always
    # apply without --accept-flake-config. trusted-users lets flakes that ship
    # their own substituters (e.g. via nixConfig) use them without prompting.
    nix.settings.trusted-users = [
        "root"
        "lmnk"
    ];
    nix.settings.substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cache.numtide.com"
    ];
    nix.settings.trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];

    # Garbage collection + automatic store deduplication
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
    };
    nix.settings.auto-optimise-store = true;
}
