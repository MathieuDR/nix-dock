# Auto-generated using compose2nix v0.3.1.
{
  pkgs,
  lib,
  self,
  ...
}: {
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [53];

  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."stats-plausible" = {
    image = "ghcr.io/plausible/community-edition:v3.0.1";
    environment = {
      "BASE_URL" = "";
      "SECRET_KEY_BASE" = "";
      "TMPDIR" = "/var/lib/plausible/tmp";
    };
    volumes = [
      "stats_plausible-data:/var/lib/plausible:rw"
    ];
    cmd = ["sh" "-c" "/entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"];
    dependsOn = [
      "stats-plausible_db"
      "stats-plausible_events_db"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=plausible"
      "--network=stats_default"
    ];
  };

  systemd.services."podman-stats-plausible" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-stats_default.service"
      "podman-volume-stats_plausible-data.service"
    ];
    requires = [
      "podman-network-stats_default.service"
      "podman-volume-stats_plausible-data.service"
    ];
    partOf = [
      "podman-compose-stats-root.target"
    ];
    wantedBy = [
      "podman-compose-stats-root.target"
    ];
  };

  virtualisation.oci-containers.containers."stats-plausible_db" = {
    image = "postgres:16-alpine";
    environment = {
      "POSTGRES_PASSWORD" = "postgres";
    };
    volumes = [
      "stats_db-data:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=pg_isready -U postgres"
      "--health-start-period=2m30s"
      "--network-alias=plausible_db"
      "--network=stats_default"
    ];
  };

  systemd.services."podman-stats-plausible_db" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-stats_default.service"
      "podman-volume-stats_db-data.service"
    ];
    requires = [
      "podman-network-stats_default.service"
      "podman-volume-stats_db-data.service"
    ];
    partOf = [
      "podman-compose-stats-root.target"
    ];
    wantedBy = [
      "podman-compose-stats-root.target"
    ];
  };

  virtualisation.oci-containers.containers."stats-plausible_events_db" = {
    image = "clickhouse/clickhouse-server:24.12-alpine";
    environment = {
      "CLICKHOUSE_SKIP_USER_SETUP" = "1";
    };
    volumes = [
      "${self}/services/plausible/clickhouse/ipv4-only.xml:/etc/clickhouse-server/config.d/ipv4-only.xml:ro"
      "${self}/services/plausible/clickhouse/logs.xml:/etc/clickhouse-server/config.d/logs.xml:ro"
      "${self}/services/plausible/clickhouse/low-resources.xml:/etc/clickhouse-server/config.d/low-resources.xml:ro"
      "stats_event-data:/var/lib/clickhouse:rw"
      "stats_event-logs:/var/log/clickhouse-server:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=plausible_events_db"
      "--network=stats_default"
    ];
  };

  systemd.services."podman-stats-plausible_events_db" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-stats_default.service"
      "podman-volume-stats_event-data.service"
      "podman-volume-stats_event-logs.service"
    ];
    requires = [
      "podman-network-stats_default.service"
      "podman-volume-stats_event-data.service"
      "podman-volume-stats_event-logs.service"
    ];
    partOf = [
      "podman-compose-stats-root.target"
    ];
    wantedBy = [
      "podman-compose-stats-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-stats_default" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f stats_default";
    };
    script = ''
      podman network inspect stats_default || podman network create stats_default
    '';
    partOf = ["podman-compose-stats-root.target"];
    wantedBy = ["podman-compose-stats-root.target"];
  };

  # Volumes
  systemd.services."podman-volume-stats_db-data" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect stats_db-data || podman volume create stats_db-data
    '';
    partOf = ["podman-compose-stats-root.target"];
    wantedBy = ["podman-compose-stats-root.target"];
  };
  systemd.services."podman-volume-stats_event-data" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect stats_event-data || podman volume create stats_event-data
    '';
    partOf = ["podman-compose-stats-root.target"];
    wantedBy = ["podman-compose-stats-root.target"];
  };
  systemd.services."podman-volume-stats_event-logs" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect stats_event-logs || podman volume create stats_event-logs
    '';
    partOf = ["podman-compose-stats-root.target"];
    wantedBy = ["podman-compose-stats-root.target"];
  };
  systemd.services."podman-volume-stats_plausible-data" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect stats_plausible-data || podman volume create stats_plausible-data
    '';
    partOf = ["podman-compose-stats-root.target"];
    wantedBy = ["podman-compose-stats-root.target"];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-stats-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = ["multi-user.target"];
  };
}
