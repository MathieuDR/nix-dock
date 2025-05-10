{
  config,
  domainUtils,
  lib,
  self,
  ...
}: let
  listen_port = "9342";
  domain = domainUtils.domain "insights";
in {
  age.secrets = {
    "plausible/env".file = "${self}/secrets/plausible/env.age";
  };

  virtualisation.oci-containers.containers."stats-plausible" = {
    # Overwriting generated files
    environment = lib.mkForce {
      "TMPDIR" = "/var/lib/plausible/tmp";
    };

    environmentFiles = [
      config.age.secrets."plausible/env".path
    ];

    ports = [
      "${listen_port}:8000"
    ];
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

  imports = [
    ./compose.nix
  ];
}
