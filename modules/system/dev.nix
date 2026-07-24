# Run-foreign-binaries support, so generic-Linux toolchains (mise, asdf, uv,
# pip wheels, npm native addons) work without per-project Nix packaging.
#
# Why both are needed on NixOS:
#   nix-ld   — provides a working /lib64/ld-linux-x86-64.so.2 (otherwise a
#              stub that aborts), so dynamically-linked prebuilt executables
#              (node, ruff, python-build-standalone, …) can start at all.
#   envfs    — provides /usr/bin/env and /bin/sh via FUSE, so the `#!/usr/bin/env`
#              shebangs those toolchains generate resolve.
# With both, `mise install` uses precompiled binaries (instant) instead of
# compiling everything from source.
{ pkgs, ... }:

{
    programs.nix-ld = {
        enable = true;
        # Generous library set: covers libc/libstdc++ for any prebuilt binary
        # plus the common libraries native Node addons and Python wheels dlopen.
        libraries = with pkgs; [
            stdenv.cc.cc.lib # libstdc++ / libgcc_s
            glibc
            zlib
            zstd
            openssl
            curl
            glib
            util-linux
            icu
            libxml2
            libxslt
            expat
            xz
            bzip2
            libffi
            ncurses
            readline
            sqlite
            libGL
            fontconfig
            freetype
            nss
            nspr
            libx11
            libxcb

            # Chromium's runtime deps, for the playwright MCP plugin's bundled
            # headless browser. Playwright downloads a generic-Linux Chrome that
            # dlopens these; without them it dies with "libatk-1.0.so.0: cannot
            # open shared object file". Verified to launch headless with this set.
            atk
            at-spi2-atk
            at-spi2-core
            cups
            dbus
            libdrm
            libxkbcommon
            mesa
            libgbm
            pango
            cairo
            alsa-lib
            gdk-pixbuf
            gtk3
            libXcomposite
            libXdamage
            libXext
            libXfixes
            libXrandr
            libxshmfence
            libXrender
            libXtst
        ];
    };

    services.envfs.enable = true;
}
