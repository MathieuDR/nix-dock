{
  self,
  config,
  domainUtils,
  ...
}: let
  data_dir = "/srv/livebook/data";
in {
  age.secrets = {
    "livebook/env".file = "${self}/secrets/livebook/env.age";
  };

  virtualisation.oci-containers.containers.livebook = {
    image = "ghcr.io/livebook-dev/livebook";
    autoStart = true;

    volumes = [
      "${data_dir}:/data"
    ];

    environmentFiles = [
      config.age.secrets."livebook/env".path
    ];

    ports = [
      "9090:8080"
      "9091:8081"
    ];
  };

  systemd.services."podman-livebook" = {
    partOf = ["service-tools.target"];
    wantedBy = ["service-tools.target"];
  };

  systemd.tmpfiles.rules = [
    "d ${data_dir} 0664 root root"
  ];

  #TODO: Can we pass the name (b2) somehow?
  services.restic.backups.b2.paths = [
    data_dir
  ];

  services.caddy.virtualHosts.${domainUtils.domain "livebook"} = {
    extraConfig = ''
      reverse_proxy http://localhost:9090
    '';
  };
}
