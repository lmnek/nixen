
host := "msi"

# List available recipes
default:
    @just --list

# Rebuild and switch to the new system config (system + home)
switch:
    sudo nixos-rebuild switch --flake .#{{host}}

# Build and activate without making it the boot default (reverts on reboot)
test:
    sudo nixos-rebuild test --flake .#{{host}}

# Build the config but only apply it on next boot
boot:
    sudo nixos-rebuild boot --flake .#{{host}}

# Dry-build: show what would change without activating
dry:
    nixos-rebuild dry-build --flake .#{{host}}

# Update all flake inputs
update:
    nix flake update

# Update a single flake input, e.g. `just update-input nixpkgs`
update-input input:
    nix flake update {{input}}

# Update inputs then switch
up: update switch

# Check the flake evaluates and builds
check:
    nix flake check

# Garbage-collect: delete generations older than 7 days, then collect
gc:
    sudo nix-collect-garbage --delete-older-than 7d
    nix-collect-garbage --delete-older-than 7d

# Keep only the N most recent system generations, then collect garbage
gc-keep count="5":
    sudo nix-env --delete-generations +{{count}} --profile /nix/var/nix/profiles/system
    sudo nix-collect-garbage

# Aggressively free space: remove all old generations
gc-all:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# List system generations
generations:
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
