{ pkgs, ... }:

{
    programs.fish.enable = true;

    environment.systemPackages = with pkgs; [
        home-manager

        # desktop
        brightnessctl
        playerctl
        pavucontrol
        networkmanagerapplet
        xwayland-satellite

        onlyoffice-desktopeditors
        transmission_4-gtk

        vim
        git
        wget
    ];

    programs.localsend = {
        enable = true;
        openFirewall = true;
    };

    # services.mako.enable = true; # notifications - doesn't need because of noctalia?
}
