{domainUtils, ...}: let
  data_dir = "/srv/actual/data";
in {
  virtualisation.oci-containers.containers.actual = {
    image = "actualbudget/actual-server:latest";
    autoStart = true;

    volumes = [
      "${data_dir}:/data"
    ];

    ports = [
      "5006:5006"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${data_dir} 0664 root root"
  ];

  services.restic.backups.b2.paths = [
    data_dir
  ];

  services.caddy.virtualHosts.${domainUtils.domain "actual"} = {
    extraConfig = ''
      encode gzip zstd
      reverse_proxy http://localhost:5006
    '';
  };
}
