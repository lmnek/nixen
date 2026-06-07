# Standalone background daemons. Imported by modules/system/default.nix.
#
# Deliberately NOT here: PipeWire (audio) and greetd (login).
# Will naturally become audio.nix / desktop.nix if split later.
{ ... }:

{
    # Power management
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    # Printing (CUPS)
    services.printing.enable = true;

    # Touchpad (enabled by default in most desktopManagers)
    services.libinput.enable = true;

    # Inbound SSH intentionally disabled. Re-enable with key-only auth if needed:
    #   services.openssh.enable = true;
    #   services.openssh.settings.PasswordAuthentication = false;
}
