# Keep the MSI keyboard backlight permanently on.
#
# Stock behaviour: the EC lights the keys on a keypress and auto-extinguishes
# after ~10s. On MSI Prestige laptops, EC register 0x2c selects the mode:
#   0x00 = always on, 0x08 = 10-second auto-off (the stock value).
# Verified on this box (E2622IMS): reg 0x2c read back 0x08. We flip it to 0x00.
#
# Done via the in-tree `ec_sys` debug interface rather than the out-of-tree
# msi-ec module: msi-ec doesn't list this firmware and breaks easily on the
# latest kernel, whereas this is a single byte to a stable register.
#
# ponytail: address/values come from the Prestige line, not an E2622 datasheet.
# If a BIOS update ever moves them, re-check `reg 0x2c` (skip=44) before trusting.
{ pkgs, ... }:
let
  kbdAlwaysOn = pkgs.writeShellScript "kbd-backlight-always-on" ''
    printf '\x00' | ${pkgs.coreutils}/bin/dd \
      of=/sys/kernel/debug/ec/ec0/io bs=1 seek=44 count=1 status=none
  '';
in
{
  boot.kernelModules = [ "ec_sys" ];
  boot.extraModprobeConfig = "options ec_sys write_support=1";

  systemd.services.kbd-backlight-always-on = {
    description = "Keep MSI keyboard backlight permanently on (EC reg 0x2c=0x00)";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = kbdAlwaysOn;
    };
  };

  # The EC resets the mode on resume, so re-apply on wake.
  powerManagement.resumeCommands = "${kbdAlwaysOn}";
}
