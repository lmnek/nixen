{ pkgs, ... }:

let
    # Wrap Slack to hint Ozone at the right platform (fixes Wayland rendering)
    slack = pkgs.symlinkJoin {
        name = "slack";
        paths = [ pkgs.slack ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/slack --add-flags "--ozone-platform-hint=auto"
        '';
    };
in
{
    home.packages = [ slack ];
}
