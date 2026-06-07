# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
    imports =
        [ # Include the results of the hardware scan.
            ./hardware-configuration.nix
        ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 15;
    boot.loader.efi.canTouchEfiVariables = true;

    # up to date kernel (need for my amazing epic cpu/igpu)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.hostName = "msi";

    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;

    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    hardware.graphics = {
        enable = true;
        enable32Bit = true; # CRITICAL for Steam, as many games/Steam itself are 32-bit
        extraPackages = with pkgs;  [ intel-media-driver ];
    };
    # programs.xwayland.enable = true;

    time.timeZone = "Europe/Prague";

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Select internationalisation properties.
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
        #   font = "Lat2-Terminus16";
        #   useXkbConfig = true; # use xkb.options in tty.
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;

    # --- compositor ---

    programs.niri.enable = true;
    # programs.hyprland.enable = true;

    # try to fix gpu
    # hardware.enableRedistributableFirmware = true;
    # hardware.cpu.intel.updateMicrocode = true;

    # ---------- Login (greetd + tuigreet) ----------
    services.greetd = {
        enable = true;
        settings.default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
            user = "greeter";
        };
    };

    # ---------- Audio (PipeWire) ----------
    security.rtkit.enable = true;
    # services.pulseaudio.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
    };

    # ---------- Memory: zram (ideal with 32 GB RAM, no disk swap) ----------
    zramSwap.enable = true;

    # ---------- Fonts ----------
    fonts.packages = with pkgs; [ 
        nerd-fonts.jetbrains-mono 
        jetbrains-mono
        nerd-font-patcher
    ];

    # ---------- Packages ----------
    environment.systemPackages = (with pkgs; [
        # -- always installed --
        home-manager
        alacritty            # terminal — niri's DEFAULT keybind expects this
        fuzzel               # launcher — niri's DEFAULT keybind expects this
        swaybg               # wallpaper
        wl-clipboard brightnessctl playerctl
        pavucontrol networkmanagerapplet
        neovim git wget

        zip 
        libnotify # notify-send

        xwayland-satellite

        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        mako # notifications
        # waybar               # status bar

        kanata
    ])
        ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
            claude-code
            codex
        ]);

    programs.fish.enable = true; 

    # ---------- Your user — don't lock yourself out ----------
    users.users.lmnk = {
        isNormalUser = true;
        extraGroups = [
            "wheel" "networkmanager" "video"
            "input" "uinput" # for kanata
        ];
        initialPassword = "lol"; # change after first login
    };

    hardware.uinput.enable = true;
    boot.kernelModules = [ "uinput" ];
    users.groups.uinput = { };

    # --- other auto-gen ---

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.mtr.enable = true;
    programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
    };

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    nixpkgs.overlays = [
        (final: prev: {
            steam = prev.steam.override {
                extraArgs = "-cef-disable-gpu-compositing";
            };
        })
    ];

    programs.gamescope.enable = true;
    programs.gamemode.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Copy the NixOS configuration file and link it from the resulting system
    # (/run/current-system/configuration.nix). This is useful in case you
    # accidentally delete configuration.nix.
    # system.copySystemConfiguration = true; # doesnt work with flakes?




    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "26.05"; # Did you read the comment?
}

