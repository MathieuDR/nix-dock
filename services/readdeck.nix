{domainUtils, ...}: let
  data_dir = "/srv/readeck/data";
  port = "9040";
in {
  virtualisation.oci-containers.containers.readeck = {
    image = "codeberg.org/readeck/readeck:latest";
    autoStart = true;

    volumes = [
      "${data_dir}:/readeck"
    ];

    ports = [
      "${port}:8000"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${data_dir} 0774 root root"
  ];

  services.restic.backups.b2.paths = [
    data_dir
  ];

  services.caddy.virtualHosts.${domainUtils.domain "readlater"} = {
    extraConfig = ''
      reverse_proxy http://localhost:${port}
      encode {
        zstd
        gzip
        minimum_length 1024
      }
    '';
  };
}
