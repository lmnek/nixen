# Container runtime. Imported by modules/system/default.nix.
#
# Rootful Docker daemon + CLI. The mindwell-ai-assistant repo needs this for
# integration tests: testcontainers spins up a throwaway Postgres container,
# talking to the daemon socket directly (no docker-compose involved).
{ pkgs, ... }:

{
    virtualisation.docker = {
        enable = true;
        # Reclaim disk from dangling images/containers weekly.
        autoPrune = {
            enable = true;
            dates = "weekly";
        };

        # Keep bridges out of 172.16/12: GoodAccess's tunnel gateway+DNS is
        # 172.21.0.1, and a bridge holding that address wins in the kernel's
        # `local` table, black-holing everything the VPN sends its gateway.
        daemon.settings.default-address-pools = [
            { base = "10.201.0.0/16"; size = 24; }
        ];
    };

    # `docker compose` v2 subcommand (the compose plugin) + the standalone
    # `docker-compose` binary, for the day a compose file shows up.
    environment.systemPackages = [ pkgs.docker-compose ];

    # User must join the `docker` group to reach the socket without sudo.
    users.users.lmnk.extraGroups = [ "docker" ];
}
