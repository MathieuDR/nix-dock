{domainUtils, ...}: let
  data_dir = "/srv/commafeed/data";
  port = "9233";
in {
  virtualisation.oci-containers.containers.commafeed = {
    image = "athou/commafeed:latest-h2";
    autoStart = true;

    volumes = [
      "${data_dir}:/commafeed/data"
    ];

    ports = [
      "${port}:8082"
    ];

    extraOptions = [
      "-m=256m"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${data_dir} 0774 root root"
  ];

  services.restic.backups.b2.paths = [
    data_dir
  ];

  services.caddy.virtualHosts.${domainUtils.domain "feed"} = {
    extraConfig = ''
      reverse_proxy http://localhost:${port}
      encode {
        zstd
        gzip
        minimum_length 1024
      }

      header {
        Access-Control-Allow-Origin ${domainUtils.domain "https://glance"}
        Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization"
        Access-Control-Allow-Credentials true

        # Efficient handling of preflight OPTIONS requests
        @options {
          method OPTIONS
        }
        handle @options {
          respond 204
        }
      }
    '';
  };
}
