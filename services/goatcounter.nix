{domainUtils, ...}: let
  listen_port = "9334";
  domain = domainUtils.domain "insights";
  data_dir = "/var/lib/goatcounter";
in {
  systemd.tmpfiles.rules = [
    "d ${data_dir} 0774 1000 1000"
  ];

  virtualisation.oci-containers.containers.goatcounter = {
    image = "arp242/goatcounter:latest";
    autoStart = true;

    ports = [
      "${listen_port}:8080"
    ];

    volumes = [
      "${data_dir}:/home/goatcounter/goatcounter-data"
    ];

    cmd = ["serve" "-automigrate" "-listen=:8080" "-tls=none"];
  };

  systemd.services."podman-goatcounter" = {
    partOf = ["projects.target"];
    wantedBy = ["projects.target"];
  };

  services.caddy.virtualHosts.${domain} = {
    extraConfig = ''
      reverse_proxy http://localhost:${listen_port}

      encode {
        zstd
        gzip
        minimum_length 1024
      }
    '';
  };
}
