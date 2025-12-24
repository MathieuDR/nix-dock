# Extra info: https://www.falconprogrammer.co.uk/blog/2023/02/foundryvtt-10-291/
{
  pkgs,
  inputs,
  domainUtils,
  ...
}: {
  services.foundryvtt = {
    enable = true;
    hostName = "drakkenheim.deraedt.dev";
    proxySSL = true;
    proxyPort = 443;
    port = 8412;

    package = inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_13.overrideAttrs {
      version = "13.347";
    };

    minifyStaticFiles = true;
  };

  systemd.services."foundryvtt" = {
    partOf = ["games.target"];
    wantedBy = ["games.target"];

    serviceConfig = {
      MemoryMax = "2.5G";
      MemoryHigh = "2G";
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
