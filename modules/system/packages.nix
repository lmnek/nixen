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
        # 0.8.2 treats undecorated transient DIALOG windows as popups; a popup
        # dies with its parent, so e.g. Qt dialogs whose parent closes never
        # show (Supreeeme/xwayland-satellite#470, #487). Upstream PR #480
        # adds the `forced_size` condition; drop this once it's merged.
        (xwayland-satellite.overrideAttrs {
            postPatch = ''
                substituteInPlace src/xstate/mod.rs --replace-fail \
                    'self.has_transient_for && motif_no_decor)' \
                    'self.has_transient_for && motif_no_decor && forced_size)'
            '';
        })

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
