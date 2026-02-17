{
  self,
  config,
  domainUtils,
  ...
}: let
  listen_port = "9134";
in {
  age.secrets = {
    "common/ghp".file = "${self}/secrets/common/ghp.age";
  };

  virtualisation.oci-containers.containers.mechavolt = {
    image = "ghcr.io/mathieudr/mechavolt:latest";
    autoStart = true;

    ports = [
      "${listen_port}:3000"
    ];

    # Auth
    login = {
      username = "MathieuDR";
      registry = "https://ghcr.io";
      passwordFile = config.age.secrets."common/ghp".path;
    };
  };

  services.caddy.virtualHosts = {
    ${domainUtils.domain "kenny"} = {
      extraConfig = ''
        reverse_proxy http://localhost:${listen_port} {
          @404 status 404
          handle_response @404 {
          	rewrite * /404.html
          	reverse_proxy http://localhost:${listen_port}
          }
        }

        encode {
          zstd
          gzip
          minimum_length 1024
        }

        # Cache static assets
        @static_files {
          path /static/* /images/* /css/* /js/*
        }

        handle @static_files {
          header Cache-Control "public, max-age=31536000, immutable"
        }
      '';
    };
  };
}
