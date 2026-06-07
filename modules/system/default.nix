# System-wide configuration. Imported by hosts/msi via ../../modules/system.
# Hardware scan, disk layout, hostname and stateVersion live in hosts/msi/.
# Help: configuration.nix(5), https://search.nixos.org/options, `nixos-help`.

{
config,
lib,
pkgs,
inputs,
...
}:

{
    imports = [
        ./desktop.nix
        ./gaming.nix
        ./kanata.nix
        ./networking.nix
        ./nix.nix
        ./packages.nix
        ./services.nix
    ];

    # systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 15;
    boot.loader.efi.canTouchEfiVariables = true;

    # up to date kernel (need for my amazing panther lake cpu/igpu)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    hardware.bluetooth.enable = true;

    hardware.graphics = {
        enable = true;
        enable32Bit = true; # CRITICAL for Steam, as many games/Steam itself are 32-bit
        extraPackages = with pkgs; [ intel-media-driver ];
    };

    # memory: zram (ideal with 32 GB RAM, no disk swap)
    zramSwap.enable = true;

    time.timeZone = "Europe/Prague";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "cs_CZ.UTF-8";
        LC_IDENTIFICATION = "cs_CZ.UTF-8";
        LC_MEASUREMENT = "cs_CZ.UTF-8";
        LC_MONETARY = "cs_CZ.UTF-8";
        LC_NAME = "cs_CZ.UTF-8";
        LC_NUMERIC = "cs_CZ.UTF-8";
        LC_PAPER = "cs_CZ.UTF-8";
        LC_TELEPHONE = "cs_CZ.UTF-8";
        LC_TIME = "cs_CZ.UTF-8";
    };

    console = {
        keyMap = "us";
        font = "Lat2-Terminus16"; # for nicer tty
    };

    # ---------- Audio (PipeWire) ----------
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
    };

    # ---------- User ----------
    users.users.lmnk = {
        isNormalUser = true;
        extraGroups = [
            "wheel"
            "networkmanager"
            "video"
        ];
        initialPassword = "lol"; # change after first login
    };

    # ---------- Other ----------
    programs.mtr.enable = true;
    programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
    };

    # NOTE: system.stateVersion is set in hosts/msi/default.nix (it's per-host).
}
