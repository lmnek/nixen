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
    };

    # `docker compose` v2 subcommand (the compose plugin) + the standalone
    # `docker-compose` binary, for the day a compose file shows up.
    environment.systemPackages = [ pkgs.docker-compose ];

    # User must join the `docker` group to reach the socket without sudo.
    users.users.lmnk.extraGroups = [ "docker" ];
}
