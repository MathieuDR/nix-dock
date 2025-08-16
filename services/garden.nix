{
  self,
  config,
  lib,
  domainUtils,
  PII,
  ...
}: let
  listen_port = "9133";
in {
  age.secrets = {
    "common/ghp".file = "${self}/secrets/common/ghp.age";
  };

  virtualisation.oci-containers.containers.garden = {
    image = "ghcr.io/mathieudr/obsidian-garden:latest";
    autoStart = true;

    ports = [
      "${listen_port}:8080"
    ];

    # Auth
    login = {
      username = "MathieuDR";
      registry = "https://ghcr.io";
      passwordFile = config.age.secrets."common/ghp".path;
    };
  };

  systemd.services."podman-garden" = {
    partOf = ["projects.target"];
    wantedBy = ["projects.target"];
  };

  services.caddy.virtualHosts = {
    ${domainUtils.domain "mathieu"} = {
      extraConfig = ''
        reverse_proxy http://localhost:${listen_port}

        encode {
          zstd
          gzip
          minimum_length 1024
        }

        @font_files {
          path /static/fonts/*
        }

        handle @font_files {
          header Cache-Control "public, max-age=31536000, immutable"
        }
      '';
    };

    ${lib.concatStringsSep ", " [(domainUtils.domain "www") (domainUtils.domain "garden") PII.domain]} = {
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-${domainUtils.domain "mathieu"}.log
      '';

      extraConfig = ''
        redir ${domainUtils.domain "https://mathieu"}{uri} permanent
      '';
    };
  };
}
