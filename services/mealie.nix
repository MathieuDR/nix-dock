{
  self,
  config,
  domainUtils,
  ...
}: let
  home = "/srv/mealie";
  data = "${home}/data";
  port = "9099";
in {
  age.secrets = {
    "recipes/env".file = "${self}/secrets/recipes/env.age";
  };

  users.users.mealie = {
    isSystemUser = true;
    group = "mealie";
    home = home;
    uid = 993;
  };

  users.groups.mealie = {
    gid = 993;
  };

  virtualisation.oci-containers.containers.mealie = {
    image = "ghcr.io/mealie-recipes/mealie";
    autoStart = true;

    volumes = [
      "${data}:/app/data"
    ];

    environmentFiles = [
      config.age.secrets."recipes/env".path
    ];

    ports = [
      "${port}:9000"
    ];

    login = {
      username = "MathieuDR";
      registry = "https://ghcr.io";
      passwordFile = config.age.secrets."common/ghp".path;
    };
  };

  systemd.services."podman-mealie" = {
    partOf = ["service-tools.target"];
    wantedBy = ["service-tools.target"];
  };

  systemd.tmpfiles.rules = [
    "d ${data} 0775 mealie mealie"
  ];

  services.restic.backups.b2.paths = [
    data
  ];

  services.caddy.virtualHosts.${domainUtils.domain "recipes"} = {
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
