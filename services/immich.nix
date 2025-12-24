{
  self,
  config,
  domainUtils,
  ...
}: let
  mediaDirectory = "/srv/immich";
in {
  # age.secrets = {
  #   "immich/env".file = "${self}/secrets/immich/env.age";
  # };

  systemd.tmpfiles.rules = [
    "d ${mediaDirectory} 0700 ${config.services.immich.user} ${config.services.immich.group}"
  ];

  services.immich = {
    enable = false;
    # secretsFile = config.age.secrets."immich/env".path;
    environment = {
      TZ = "Europe/Brussels";
    };
    database.enableVectors = false;
    machine-learning.enable = false;
    settings.server.externalDomain = "https://${domainUtils.domain "pics"}";
  };

  #TODO: Make better backups
  # https://wiki.nixos.org/wiki/Immich
  # https://docs.immich.app/administration/backup-and-restore
  services.restic.backups.b2.paths = [
    mediaDirectory
  ];

  # services.caddy.virtualHosts.${domainUtils.domain "pics"} = {
  #   extraConfig = ''
  #     reverse_proxy http://localhost:${toString config.services.immich.port}
  #     encode {
  #       zstd
  #       gzip
  #       minimum_length 1024
  #     }
  #   '';
  # };
}
