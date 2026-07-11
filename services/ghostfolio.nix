{
  self,
  pkgs,
  config,
  domainUtils,
  ...
}: let
  home = "/srv/ghostfolio";
  db_data = "${home}/db";
  port = "3333";
  network = "ghostfolio-net";
  envFile = config.age.secrets."ghostfolio/env".path;
in {
  age.secrets = {
    "ghostfolio/env".file = "${self}/secrets/ghostfolio/env.age";
  };

  # Postgres + Redis are reachable only over this private network, by name.
  systemd.services."create-${network}" = {
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.podman}/bin/podman network exists ${network} \
        || ${pkgs.podman}/bin/podman network create ${network}
    '';
  };

  virtualisation.oci-containers.containers = {
    ghostfolio-db = {
      image = "docker.io/library/postgres:15-alpine";
      autoStart = true;
      volumes = ["${db_data}:/var/lib/postgresql/data"];
      environmentFiles = [envFile];
      extraOptions = [
        "--network=${network}"
        "--memory=256m"
        "--health-cmd=pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"
        "--health-interval=10s"
      ];
    };

    ghostfolio-redis = {
      image = "docker.io/library/redis:7-alpine";
      autoStart = true;
      # Redis needs the password as an arg; pull it from the env file at runtime.
      cmd = ["sh" "-c" "exec redis-server --requirepass \"$REDIS_PASSWORD\""];
      environmentFiles = [envFile];
      extraOptions = [
        "--network=${network}"
        "--memory=64m"
      ];
    };

    ghostfolio = {
      image = "docker.io/ghostfolio/ghostfolio:latest";
      autoStart = true;
      dependsOn = ["ghostfolio-db" "ghostfolio-redis"];
      environmentFiles = [envFile];
      ports = ["127.0.0.1:${port}:${port}"];
      extraOptions = [
        "--network=${network}"
        "--memory=512m"
      ];
    };
  };

  # Ensure the network exists before any container starts.
  systemd.services."podman-ghostfolio-db" = {
    after = ["create-${network}.service"];
    requires = ["create-${network}.service"];
    partOf = ["service-tools.target"];
    wantedBy = ["service-tools.target"];
  };
  systemd.services."podman-ghostfolio-redis" = {
    after = ["create-${network}.service"];
    requires = ["create-${network}.service"];
    partOf = ["service-tools.target"];
    wantedBy = ["service-tools.target"];
  };
  systemd.services."podman-ghostfolio" = {
    after = ["create-${network}.service"];
    requires = ["create-${network}.service"];
    partOf = ["service-tools.target"];
    wantedBy = ["service-tools.target"];
  };

  systemd.tmpfiles.rules = [
    "d ${home} 0755 root root"
    "d ${db_data} 0700 root root"
  ];

  services.restic.backups.b2.paths = [db_data];

  services.caddy.virtualHosts.${domainUtils.domain "invest"} = {
    extraConfig = ''
      encode gzip zstd
      reverse_proxy http://localhost:${port}
    '';
  };
}
