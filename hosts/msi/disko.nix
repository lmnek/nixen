# disko.nix
{
    disko.devices = {
        disk = {
            main = {
                type = "disk";
                # Find by:  ls -la /dev/disk/by-id/
                device = "/dev/disk/by-id/nvme-Micron_2500_MTFDKBA1T0QGN_2541539F9289";
                content = {
                    type = "gpt";
                    partitions = {
                        ESP = {
                            priority = 1;
                            name = "ESP";
                            start = "1M";
                            end = "512M"; # roomy for multiple kernels
                            type = "EF00";
                            content = {
                                type = "filesystem";
                                format = "vfat";
                                mountpoint = "/boot";
                                mountOptions = [ "umask=0077" ];
                            };
                        };
                        root = {
                            size = "100%";
                            content = {
                                type = "btrfs";
                                extraArgs = [ "-f" ]; # force-overwrite any existing fs
                                subvolumes = {
                                    "/root" = {
                                        mountpoint = "/";
                                        mountOptions = [ "compress=zstd" ];
                                    };
                                    "/home" = {
                                        mountpoint = "/home";
                                        mountOptions = [ "compress=zstd" ];
                                    };
                                    "/nix" = {
                                        mountpoint = "/nix";
                                        mountOptions = [
                                            "compress=zstd"
                                            "noatime"
                                        ];
                                    };
                                    "/swap" = {
                                        mountpoint = "/.swapvol";
                                        swap.swapfile.size = "36G"; # >= RAM for hibernate
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };
}
