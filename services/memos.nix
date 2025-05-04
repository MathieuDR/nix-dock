{domainUtils, ...}: let
  data_dir = "/srv/memos/data";
  logs_dir = "/srv/memos/logs";
in {
  virtualisation.oci-containers.containers.memos = {
    image = "neosmemo/memos";
    autoStart = true;

    volumes = [
      "${data_dir}:/var/opt/memos"
    ];

    ports = [
      "5230:5230"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${data_dir} 0774 root root"
    "d ${logs_dir} 0774 caddy caddy"
  ];

  #TODO: Can we pass the name (b2) somehow?
  services.restic.backups.b2.paths = [
    data_dir
  ];

  services.caddy.virtualHosts.${domainUtils.domain "memos"} = {
    extraConfig = ''
      reverse_proxy http://localhost:5230
      log {
        format console
        output file ${logs_dir}/log {
          roll_size 10mb
          roll_keep 20
          roll_keep_for 7d
        }
      }
      encode {
        zstd
        gzip
        minimum_length 1024
      }
    '';
  };
}
