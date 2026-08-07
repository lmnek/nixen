# Desktop environment: compositor, login manager, fonts.
{ pkgs, ... }:

{
    # Compositor
    programs.niri.enable = true;

    # Login (greetd + tuigreet)
    services.greetd = {
        enable = true;
        settings.default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
            user = "greeter";
        };
    };

    # enable screensharing
    xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
            xdg-desktop-portal-termfilechooser
        ];
        # yazi as the file picker (niri module owns config.niri, so merge here).
        # useNautilus = false would need mkForce — it defines this key too.
        config.niri."org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };

    # Fonts
    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        jetbrains-mono
        nerd-font-patcher
    ];
}
