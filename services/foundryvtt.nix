# Extra info: https://www.falconprogrammer.co.uk/blog/2023/02/foundryvtt-10-291/
{
  pkgs,
  lib,
  inputs,
  domainUtils,
  username,
  ...
}: let
  # Target mount point path inside Foundry's standard data structure
  mountPoint = "/var/lib/foundryvtt/Data/assets/external_assets";
  sourceDir = "/home/${username}/foundry_assets";
in {
  systemd.tmpfiles.rules = [
    # Create the landing zone in user's home if missing (Owned by user)
    "d ${sourceDir} 0755 ${username} users - -"
    # Create the internal target directory skeleton inside Foundry (Owned by foundryvtt)
    "d /var/lib/foundryvtt/Data/assets 0750 foundryvtt foundryvtt - -"
    "d ${mountPoint} 0750 foundryvtt foundryvtt - -"
  ];

  fileSystems."${mountPoint}" = {
    device = sourceDir;
    options = ["bind" "ro"]; # 'ro' keeps it safely read-only for Foundry
    depends = ["/home"]; # Fixed: Changed from dependsOn to depends
  };

  services.foundryvtt = {
    enable = true;
    hostName = "drakkenheim.deraedt.dev";
    proxySSL = true;
    proxyPort = 443;
    port = 8412;

    package = (inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_14.overrideAttrs {
      version = "14.360";
    }).override {nodejs = pkgs.unstable.nodejs_24;};

    minifyStaticFiles = true;
  };

  systemd.services."foundryvtt" = {
    partOf = ["games.target"];
    wantedBy = ["games.target"];
    after = ["network.target" "local-fs.target"];
    requires = ["local-fs.target"];

    serviceConfig = {
      MemoryMax = "2.5G";
      MemoryHigh = "2G";
      SystemCallFilter = lib.mkAfter ["@chown"];
    };
  };

  services.caddy.virtualHosts.${domainUtils.domain "drakkenheim"} = {
    extraConfig = ''
      reverse_proxy http://localhost:8412

      encode {
        zstd
        gzip
        minimum_length 1024
      }
    '';
  };

  systemd.services.ddb-proxy = {
    description = "DDB Proxy for Foundry VTT";
    after = ["network.target"];
    wantedBy = [];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.custom.ddb-proxy}/bin/ddb-proxy";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
    };

    environment = {
      PORT = "9313";
    };
  };

  services.caddy.virtualHosts.${domainUtils.domain "ddb-proxy"} = {
    extraConfig = ''
      reverse_proxy http://localhost:9313

      encode {
        zstd
        gzip
        minimum_length 1024
      }
    '';
  };
}
