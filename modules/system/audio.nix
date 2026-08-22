# Audio: PipeWire + realtime priority for Bitwig.
# The bitwig-studio package itself lives with the other apps in
# modules/home/default.nix.
{ ... }:

{
    security.rtkit.enable = true;

    services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        # No jack.enable: Bitwig 6 has a native PipeWire host API (and its ALSA
        # backend can't open this SOF SoundWire card at all). Add it if some
        # other JACK-only app shows up.
    };

    # rtkit alone isn't enough for Bitwig: its engine sets SCHED_FIFO directly,
    # so without an rtprio rlimit it logs "Cannot use realtime priority" and
    # the sink collects xruns. pam_limits applies these at login.
    users.users.lmnk.extraGroups = [ "audio" ];
    security.pam.loginLimits = [
        {
            domain = "@audio";
            item = "rtprio";
            type = "-";
            value = "95";
        }
        {
            domain = "@audio";
            item = "memlock";
            type = "-";
            value = "unlimited";
        }
    ];
}
