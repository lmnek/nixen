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

    # Fonts
    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        jetbrains-mono
        nerd-font-patcher
    ];
}
