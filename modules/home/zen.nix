# Zen Browser. Three profiles: Default_Release (daily driver), Chill (socials
# and video), WebApp (PWAs).
#
# Spaces, containers and keyboard shortcuts are written into Zen's own state
# files, so Zen must be closed during a switch that changes them, and a fresh
# profile needs the launch-once bootstrap in docs/SETUP.md. Policies, settings
# and extensions apply on the first switch regardless.
{
    inputs,
    pkgs,
    lib,
    ...
}: let
    # The overlay, not inputs.firefox-addons.packages.*, so addons build against
    # our pkgs and inherit allowUnfree. Unhook ships under a non-free EULA.
    firefox-addons = (pkgs.extend inputs.firefox-addons.overlays.default).firefox-addons;

    zenIcon = name: "chrome://browser/skin/zen-icons/selectable/${name}.svg";

    # Zen theme-store UUIDs. Declaring a disabled mod re-enables it, so this is
    # only the enabled set.
    modsShared = [
        "72f8f48d-86b9-4487-acea-eb4977b18f21" # Better CtrlTab Panel (@psu)
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar (@RobotoSkunk)
        "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # SuperPins (@CosmoCreeper)
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites (@Ivaon)
        "c01d3e22-1cee-45c1-a25e-53c0f180eea8" # Ghost Tabs (@Seismix)
    ];

    # Shared by all three profiles, so the bindings never change under you when
    # you switch profile. Zen ships workspace-switch and sidebar-toggle unbound,
    # so these are real overrides. The flake replaces every binding field of an
    # overridden id, unset modifiers becoming false and unset keycodes cleared,
    # so each entry is a whole binding rather than a patch.
    keyboardShortcutsShared =
        [
            # Ctrl+B toggles the icons-only sidebar...
            {
                id = "zen-toggle-sidebar";
                key = "b";
                modifiers.accel = true;
            }
            # ...which the bookmarks sidebar would otherwise shadow
            {
                id = "viewBookmarksSidebarKb";
                disabled = true;
            }
            # Ctrl+Q and Ctrl+E step through workspaces...
            {
                id = "zen-workspace-backward";
                key = "q";
                modifiers.accel = true;
            }
            {
                id = "zen-workspace-forward";
                key = "e";
                modifiers.accel = true;
            }
            # ...so quit has to vacate Ctrl+Q, which also stops accidental quits
            {
                id = "key_quitApplication";
                disabled = true;
            }
            # Frees Ctrl+Shift+L for Bitwarden autofill
            {
                id = "key_inspector";
                disabled = true;
            }
        ]
        # Ctrl+Alt+1..6 jump to a workspace, unbound by default
        ++ map (n: {
            id = "zen-workspace-switch-${toString n}";
            key = toString n;
            modifiers = {
                alt = true;
                accel = true;
            };
        }) (lib.range 1 6);

    # Zen keeps drawing its own window buttons. Turning that off with
    # browser.tabs.inTitlebar = 0 hands decoration to GTK, which under a
    # Wayland compositor with no server-side decorations draws a client-side
    # header bar instead, so hide the buttons and keep the custom titlebar.
    userChromeShared = ''
        .titlebar-buttonbox-container { display: none !important; }
    '';

    # Toolbar layout, copied from the Default_Release profile in
    # repos/secret-dotfiles. This lands in user.js, which Zen re-applies at
    # every launch, so the layout is locked: rearranging buttons in the UI
    # reverts on the next start. Change it here instead.
    #
    # Extension buttons are keyed by widget id, which is the addon id with
    # every non-alphanumeric character replaced by an underscore, plus
    # "-browser-action". An addon not named here lands in the overflow area.
    uiCustomizationState = builtins.toJSON {
        placements = {
            "nav-bar" = [
                "back-button"
                "forward-button"
                "customizableui-special-spring1"
                "vertical-spacer"
                "stop-reload-button"
                "urlbar-container"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action" # Bitwarden
                "jid0-adyhmvsp91nuo8prv0mn2vkeb84_jetpack-browser-action" # Raindrop.io
                "wappalyzer_crunchlabz_com-browser-action"
                "customizableui-special-spring39"
                "downloads-button"
                "history-panelmenu"
            ];
            "zen-sidebar-top-buttons" = ["firefox-view-button"];
            "zen-sidebar-foot-buttons" = [
                "zen-workspaces-button"
                "zen-create-new-button"
            ];
            "zen-sidebar-bottom-buttons" = ["zen-workspaces-button"];
            "zen-sidebar-icons-wrapper" = [
                "zen-profile-button"
                "zen-workspaces-button"
                "downloads-button"
            ];
            "PersonalToolbar" = ["personal-bookmarks"];
            "toolbar-menubar" = ["menubar-items"];
            "TabsToolbar" = ["tabbrowser-tabs"];
            "vertical-tabs" = [];
            "widget-overflow-fixed-list" = [];
            # ponytail: unified-extensions-area left undeclared. Unplaced addons
            # land in that popup anyway, so declaring it would only fix the
            # order of a hidden list, at the cost of 28 opaque ids.
        };
        # Buttons the browser already knows about, so Zen's migration on upgrade
        # does not re-place them. Trimmed to the ones actually referenced above.
        seen = [
            "developer-button"
            "screenshot-button"
            "_fa3caadf-e614-4f06-8375-f80c011714a4_-browser-action" # X-Clacks, popup only
            "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
            "jid0-adyhmvsp91nuo8prv0mn2vkeb84_jetpack-browser-action"
            "zotero_chnm_gmu_edu-browser-action" # in `seen` but unplaced, so it stays in the popup
            "wappalyzer_crunchlabz_com-browser-action"
            "ublock0_raymondhill_net-browser-action"
            # SponsorBlock's manifest asks for the navbar, so leaving it out of
            # `seen` made Zen re-add it to nav-bar on every launch.
            "sponsorblocker_ajay_app-browser-action"
        ];
        dirtyAreaCache = [
            "nav-bar"
            "vertical-tabs"
            "zen-sidebar-icons-wrapper"
            "PersonalToolbar"
            "toolbar-menubar"
            "TabsToolbar"
            "unified-extensions-area"
            "zen-sidebar-bottom-buttons"
            "zen-sidebar-top-buttons"
            "widget-overflow-fixed-list"
            "zen-sidebar-foot-buttons"
        ];
        # 24, not the 23 the source profile carries. user.js re-applies this at
        # every launch, so declaring an outdated version would make Zen re-run
        # its layout migration on every single start.
        currentVersion = 24;
    };

    # Cookie jars. The ids are the userContextId values the spaces below bind to.
    containersShared = {
        "Default" = {
            id = 1;
            icon = "fingerprint";
            color = "yellow";
        };
        "Uni (UA)" = {
            id = 2;
            icon = "chill";
            color = "red";
        };
        "Uni (CTU)" = {
            id = 3;
            icon = "chill";
            color = "blue";
        };
        "Relax" = {
            id = 6;
            icon = "food";
            color = "turquoise";
        };
        "Work (MW)" = {
            id = 7;
            icon = "vacation";
            color = "pink";
        };
    };
in {
    imports = [inputs.zen-browser.homeModules.beta];

    programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;

        # policies.json, enforced browser-wide.
        policies = {
            DisableAppUpdate = true; # Nix owns the package
            DisableTelemetry = true;
            DisablePocket = true;
            DontCheckDefaultBrowser = true;
        };

        profiles = {
            Default_Release = {
                id = 0;
                isDefault = true;
                # Distinct from ~/.zen-personal, which is launched by hand with
                # `zen-beta --profile ~/.zen-personal`. That keeps the real
                # workspaces out of reach of the spaces declared below.

                # prefs.js, user-overridable. A curated slice: telemetry,
                # timestamps, migration flags and session state are dropped.
                settings = {
                    # Zen UI
                    "zen.urlbar.behavior" = "float";
                    "zen.welcome-screen.seen" = true;
                    "zen.glance.enabled" = false;
                    "zen.view.compact.hide-toolbar" = true;
                    "zen.view.compact.enable-at-startup" = false;
                    "zen.view.use-single-toolbar" = false;
                    "zen.tab-unloader.timeout-minutes" = 60;
                    "zen.theme.accent-color" = "#d4bbff";
                    "zen.sidebar.close-on-blur" = false;
                    "zen.themes.disable-all" = false;
                    "zen.workspaces.separate-essentials" = false;
                    "zen.workspaces.show-workspace-indicator" = false;
                    "zen.workspaces.indicator-name-center" = false;

                    # Privacy and behaviour
                    "signon.rememberSignons" = false; # Bitwarden handles logins
                    "browser.startup.homepage" = "https://app.raindrop.io/my/-1";
                    "browser.contentblocking.category" = "standard";
                    "browser.translations.neverTranslateLanguages" = "cs";
                    "browser.translations.mostRecentTargetLanguages" = "en";
                    "privacy.history.custom" = true;
                    "privacy.clearHistory.formdata" = true;
                    "privacy.clearOnShutdown_v2.formdata" = true;

                    # Linux integration
                    "layout.css.prefers-color-scheme.content-override" = 0; # force dark page content
                    "widget.use-xdg-desktop-portal.file-picker" = 1; # native GTK file picker
                    "browser.tabs.inTitlebar" = -1; # auto; pinned, see userChromeShared

                    "browser.uiCustomization.state" = uiCustomizationState;
                };

                userChrome = userChromeShared;

                # Version-pinned via the rycee NUR.
                extensions = {
                    force = true; # overwrite extensions.json so these always apply
                    packages = with firefox-addons; [
                        ublock-origin
                        bitwarden
                        surfingkeys
                        raindropio
                        sponsorblock
                        leechblock-ng
                        web-archives
                        istilldontcareaboutcookies
                        youtube-recommended-videos # Unhook, under its AMO slug
                        localcdn
                        wappalyzer
                        zotero-connector # fetched from zotero.org, not AMO
                    ];
                };

                # The rest of the engine list is Zen's built-in set, which needs
                # no declaration. Only the default is a real choice.
                search = {
                    force = true;
                    default = "google";
                };

                # force: Zen replaces the symlink with a real file on every
                # launch. Without it home-manager writes a .hm-backup each
                # switch and the second switch dies on the existing backup.
                containersForce = true;
                containers = containersShared;

                # spacesForce stays false, so this seeds missing spaces and
                # never deletes ones made in the UI. UUIDs match the live
                # session. On a profile that predates Zen's braced UUIDs, the
                # legacy Default and Uni spaces can duplicate; fresh profiles
                # are fine.
                #
                # No theme here on purpose. Declaring a space always writes
                # gradientColors, and the writer merges with jq `*`, which
                # replaces arrays rather than merging them. Since theme.colors
                # has no null escape (spaces.nix maps null to []), every switch
                # would blank the gradient regardless. Spaces come up flat and
                # any gradient set in the UI is lost on the next switch.
                spacesForce = false;
                spaces = {
                    "Default" = {
                        id = "d8419046-1d5e-41d8-b8e3-039bb7dda85a";
                        position = 1000;
                        icon = zenIcon "flame";
                        container = 1;
                    };
                    "Uni" = {
                        id = "417a5341-33e6-448f-b1b3-454e64fc6af2";
                        position = 2000;
                        icon = zenIcon "school";
                        container = 2;
                    };
                    "Diplomka" = {
                        id = "394a8b0e-cd90-4118-9dac-b3ccdbedded0";
                        position = 3000;
                        icon = zenIcon "planet";
                        container = 3;
                    };
                    "Work" = {
                        id = "d1e3e35e-41f9-4271-87c8-7b1e3af3feec";
                        position = 4000;
                        icon = zenIcon "heart";
                        container = 7;
                    };
                };

                mods = modsShared;

                keyboardShortcutsVersion = 20; # zen.keyboard.shortcuts.version
                keyboardShortcuts = keyboardShortcutsShared;
            };

            # Socials, video and scrolling, kept away from work.
            Chill = {
                id = 1;

                settings = {
                    "zen.urlbar.behavior" = "float";
                    "zen.welcome-screen.seen" = true;
                    "zen.glance.enabled" = false;
                    "signon.rememberSignons" = false;
                    "browser.translations.neverTranslateLanguages" = "cs";
                    "browser.tabs.inTitlebar" = -1;
                };

                userChrome = userChromeShared;

                extensions = {
                    force = true;
                    packages = with firefox-addons; [
                        ublock-origin
                        bitwarden
                        surfingkeys
                        raindropio
                        leechblock-ng
                        localcdn
                        youtube-recommended-videos # Unhook
                        control-panel-for-twitter
                    ];
                };

                containersForce = true;
                containers = containersShared;

                spacesForce = false;
                spaces."Space" = {
                    id = "908aded7-e6f5-47f9-be01-02059695dd21";
                    position = 1000;
                };

                mods = modsShared;

                keyboardShortcutsVersion = 20;
                keyboardShortcuts = keyboardShortcutsShared;
            };

            # PWAs. Zen has no web-app mode, so the chromeless window comes from
            # compact mode: on at startup, both bars hidden, no hover reveal.
            WebApp = {
                id = 2;

                settings = {
                    "zen.welcome-screen.seen" = true;
                    "signon.rememberSignons" = false;
                    "zen.view.compact.enable-at-startup" = true;
                    "zen.view.compact.hide-tabbar" = true;
                    "zen.view.compact.hide-toolbar" = true;
                    "zen.view.compact.show-sidebar-and-toolbar-on-hover" = false;
                };

                extensions = {
                    force = true;
                    packages = with firefox-addons; [
                        bitwarden
                        surfingkeys
                    ];
                };

                keyboardShortcutsVersion = 20;
                keyboardShortcuts = keyboardShortcutsShared;
            };
        };
    };

    # Morgen, as a PWA in the WebApp profile rather than the Electron desktop
    # app. Morgen ships Electron 37 and calls disableHardwareAcceleration(),
    # and its own --ozone-platform=wayland fails, so the packaged app renders
    # in software on XWayland. Zen draws the same web app GPU-accelerated.
    #
    # --name lands after the zen-beta wrapper's own --name=zen-beta and wins,
    # so the window gets app_id "morgen" for niri rules. MOZ_APP_REMOTINGNAME
    # keeps it a separate instance from the daily-driver profile.
    # ponytail: no icon -- the only packaged one is inside the 200 MB morgen
    # derivation, and pulling that in just for a PNG defeats the point.
    xdg.desktopEntries.morgen = {
        name = "Morgen";
        genericName = "Calendar and Tasks";
        exec = "env MOZ_APP_REMOTINGNAME=morgen zen-beta -P WebApp --name=morgen --new-window https://web.morgen.so";
        categories = ["Office" "Calendar"];
        startupNotify = true;
    };
}
