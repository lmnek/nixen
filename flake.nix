# ~/repos/nixen/flake.nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        noctalia = {
            url = "github:noctalia-dev/noctalia";
        };

        zen-browser = {
            url = "github:0xc000022070/zen-browser-flake";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        firefox-addons = { # rycee NUR — declarative, version-pinned extensions
            url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # sone.url = "github:lullabyX/sone"; # native TIDAL client # WARNING: crashes now

        llm-agents.url = "github:numtide/llm-agents.nix";

        voxtype.url = "github:peteonrails/voxtype";

        nix-index-database = {
            url = "github:nix-community/nix-index-database";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        {
        self,
        nixpkgs,
        disko,
        home-manager,
        ...
        }@inputs:
        let
            system = "x86_64-linux";
        in
            {
            nixosConfigurations.msi = nixpkgs.lib.nixosSystem {
                # msi = hostname
                inherit system;
                specialArgs = { inherit inputs; }; # makes `inputs` visible in modules
                modules = [
                    disko.nixosModules.disko
                    home-manager.nixosModules.default
                    ./hosts/msi # the whole machine, one import
                ];
            };
        };
}
