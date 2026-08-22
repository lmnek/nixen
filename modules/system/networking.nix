# Networking. Note: hostName is set per-host in hosts/msi/default.nix.
{ ... }:

{
    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;

    # eduroam's DNS (192.168.1.120) is off-link, so GoodAccess's 0.0.0.0/1 route
    # makes it unreachable and nothing resolves. `name_servers` prepends these
    # ahead of anything DHCP or the VPN registers — unlike networking.nameservers,
    # which lands after. Ordering matters: an unclean tunnel death (eduroam roams
    # APs a lot) leaves a stale `nameserver 172.21.0.1` behind, which costs 10s
    # per lookup in front and nothing behind.
    #
    # Cost: VPN/campus-only names now NXDOMAIN. Nothing we need is internal —
    # 172.21.0.1 returns the same A record for metabase as 1.1.1.1 does. If that
    # changes, uncomment line 2 and rebuild (`sudo resolvconf -d tun0` undoes a
    # stale entry), or query it ad hoc with `doggo @172.21.0.1 <name>`.
    networking.resolvconf.extraConfig = ''
        name_servers='1.1.1.1 9.9.9.9'
        # interface_order='lo lo[0-9]* tun[0-9]* tap[0-9]*'
    '';

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;
}
