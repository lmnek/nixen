# Default apps per file type (~/.config/mimeapps.list).
# Without these, xdg-open picks the first match in mimeinfo.cache -- i.e.
# package registration order. Nix owns the file now, so apps can no longer
# self-register URL schemes; add new x-scheme-handler entries here.
{ lib, ... }:

let
    # ponytail: mimeapps.list has no globs -- types must be listed out
    forEach = app: types: lib.genAttrs types (_: app);

    browser = "zen-beta.desktop";
    images = "nsxiv.desktop";
    media = "mpv.desktop";
    pdf = "org.pwmt.zathura.desktop";
in
{
    # xdg-open ignores Terminal=true and execs with no tty, hijacking the
    # caller's terminal (e.g. yazi's). Wrap terminal apps instead.
    xdg.desktopEntries = {
        nvim-term = {
            name = "Neovim (terminal)";
            exec = "ghostty -e nvim %F";
            terminal = false;
            noDisplay = true;
            mimeType = [ "text/plain" ];
        };
        yazi-term = {
            name = "Yazi (terminal)";
            exec = "ghostty -e yazi %F";
            terminal = false;
            noDisplay = true;
            mimeType = [ "inode/directory" ];
        };
    };

    xdg.mimeApps = {
        enable = true;
        defaultApplications =
            forEach browser [
                "text/html"
                "application/xhtml+xml"
                "x-scheme-handler/http"
                "x-scheme-handler/https"
            ]
            // forEach pdf [
                "application/pdf"
                "application/postscript"
            ]
            // forEach "org.kde.okular.desktop" [
                "application/epub+zip"
                "application/vnd.comicbook+zip"
            ]
            // forEach images [
                "image/png"
                "image/jpeg"
                "image/gif"
                "image/webp"
                "image/bmp"
                "image/tiff"
            ]
            // forEach "org.kde.gwenview.desktop" [
                "image/svg+xml" # nsxiv is imlib2 -> no svg
            ]
            // forEach media [
                "video/mp4"
                "video/x-matroska"
                "video/webm"
                "video/quicktime"
                "video/x-msvideo"
                "video/mpeg"
                "audio/mpeg"
                "audio/mp4"
                "audio/flac"
                "audio/ogg"
                "audio/opus"
                "audio/x-wav"
            ]
            // forEach "nvim-term.desktop" [
                "text/plain"
                "text/markdown"
                "text/csv"
                "application/json"
                "application/xml"
                "text/x-shellscript"
            ]
            // {
                "inode/directory" = "yazi-term.desktop";

                # were self-registered by the apps
                "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
                "x-scheme-handler/beeper" = "beepertexts.desktop";
                "x-scheme-handler/slack" = "slack.desktop";
                "x-scheme-handler/discord" = "vesktop.desktop";
            };
    };
}
