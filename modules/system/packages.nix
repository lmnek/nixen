{ pkgs, ... }:

{
    programs.fish.enable = true;

    environment.systemPackages = with pkgs; [
        home-manager

        # desktop
        wl-clipboard
        brightnessctl
        playerctl
        pavucontrol
        networkmanagerapplet
        xwayland-satellite

        vim
        git
        wget
        just # utils
        croc # p2p file transfer
    ];

    programs.localsend = {
        enable = true;
        openFirewall = true;
    };

    # services.mako.enable = true; # notifications - doesn't need because of noctalia?
}
