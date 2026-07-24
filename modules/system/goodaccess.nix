# GoodAccess — proprietary ZTNA/VPN client, shipped only as an amd64 .deb.
#
# The .deb is two hardcoded-path parts:
#   * a .NET root daemon (/usr/share/GoodAccess/service/GoodAccessService) that
#     drives a bundled OpenVPN + DNS scripts, run as the `goodaccess.service`
#     systemd unit;
#   * an Electron GUI (/usr/share/GoodAccess/client/goodaccess) that talks to
#     the daemon over /tmp/CoreFxPipe_GoodAccessPipe.
#
# nix-ld (dev.nix) already gives us /lib64/ld-linux + the Electron libs, so this
# module only: adds the daemon's extra libs, lays the vendor tree down at its
# hardcoded /usr path (writable — the DNS script writes state next to itself),
# recreates the systemd unit, and ships a GUI launcher + desktop entry.
#
# Upgrades: bump `version` + `hash`, then `sudo rm -rf /usr/share/GoodAccess`
# before rebuilding (the tmpfiles `C` rule only copies when absent).
{
config,
lib,
pkgs,
...
}:

let
    version = "4.7.2-1";

    # Tools the vendor's OpenVPN up/down + DNS scripts shell out to. They reset
    # PATH to /bin:/usr/bin:/sbin (empty on NixOS), so we splice these in below.
    scriptTools = with pkgs; [
        iproute2
        systemd # resolvectl, busctl
        util-linux # logger
        iputils
        dmidecode
        coreutils
        gnugrep
        gnused
        gawk
        bash
        procps
    ];

    # Unpack the .deb and fix the scripts' hardcoded PATH.
    gaFiles = pkgs.stdenvNoCC.mkDerivation {
        pname = "goodaccess-files";
        inherit version;
        src = pkgs.fetchurl {
            url = "https://goodaccess-storage.b-cdn.net/applications/prod/linux/repos/deb/pool/main/goodaccess_${version}_amd64.deb";
            hash = "sha256-J2Hkkj62l8GBvCkVHBN/cihG8ZgrQTra567vId/9aaI=";
        };
        nativeBuildInputs = [ pkgs.dpkg ];
        unpackPhase = "dpkg-deb -x $src .";
        installPhase = ''
            mkdir -p $out
            cp -r usr/share/GoodAccess $out/GoodAccess
            for f in client.up client.down root-domain.sh systemd-pre-start.sh; do
                substituteInPlace $out/GoodAccess/service/$f \
                    --replace 'PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin' \
                              'PATH=${lib.makeBinPath scriptTools}:/bin:/usr/bin:/sbin'
            done
        '';
        dontFixup = true; # leave the vendor binaries alone; nix-ld handles the loader
    };

    # systemd units don't inherit nix-ld's session env, so hand it to the daemon
    # explicitly, using the full (merged) nix-ld library set from dev.nix + here.
    ldEnv = {
        NIX_LD = "${pkgs.stdenv.cc.bintools.dynamicLinker}";
        NIX_LD_LIBRARY_PATH = lib.makeLibraryPath config.programs.nix-ld.libraries;
    };

    # GUI launcher. --no-sandbox because the store's chrome-sandbox isn't setuid.
    gaClient = pkgs.writeShellScriptBin "goodaccess" ''
        export NIX_LD="${ldEnv.NIX_LD}"
        export NIX_LD_LIBRARY_PATH="${ldEnv.NIX_LD_LIBRARY_PATH}''${NIX_LD_LIBRARY_PATH:+:$NIX_LD_LIBRARY_PATH}"
        exec /usr/share/GoodAccess/client/goodaccess --no-sandbox "$@"
    '';

    gaDesktop = pkgs.makeDesktopItem {
        name = "goodaccess";
        desktopName = "GoodAccess";
        exec = "goodaccess %U";
        icon = "${gaFiles}/GoodAccess/client/resources/assets/icon.png";
        comment = "GoodAccess ZTNA client";
        categories = [ "Network" "Utility" ];
        mimeTypes = [ "x-scheme-handler/goodaccess" ]; # SSO login callback
    };
in
{
    # Daemon extras on top of dev.nix's nix-ld set: .NET Kerberos + OpenVPN's
    # compression/privilege libs. (Merged with dev.nix by the module system.)
    programs.nix-ld.libraries = with pkgs; [
        krb5
        lzo
        lz4
        libcap_ng
    ];

    # Vendor hardcodes /usr/share/GoodAccess and writes root-domain.save there,
    # so it must be a real writable copy, not a read-only store symlink.
    systemd.tmpfiles.rules = [
        "C /usr/share/GoodAccess 0755 root root - ${gaFiles}/GoodAccess"
        "d /opt/GoodAccess 0755 root root -" # the daemon's Sentry cache dir
    ];

    # The root VPN daemon (mirrors the vendor's goodaccess.service). Runs as root
    # natively so OpenVPN keeps NET_ADMIN + real /dev/net/tun.
    systemd.services.goodaccess = {
        description = "GoodAccess Service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = scriptTools;
        environment = ldEnv;
        serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 1;
            ExecStartPre = "${pkgs.bash}/bin/sh -c 'rm -f /tmp/CoreFxPipe_GoodAccessPipe*'";
            ExecStart = "/usr/share/GoodAccess/service/GoodAccessService";
            ExecStopPost = "${pkgs.bash}/bin/sh -c 'rm -f /tmp/CoreFxPipe_GoodAccessPipe*'";
        };
    };

    environment.systemPackages = [ gaClient gaDesktop ];
}
