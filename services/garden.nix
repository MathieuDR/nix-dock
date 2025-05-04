{
  config,
  domainUtils,
  PII,
  ...
}: let
  listen_port = "9133";
in {
  age.secrets = {
    "common/ghp".file = ../secrets/common/ghp.age;
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

  services.caddy.virtualHosts.${domainUtils.domain "garden"} = {
    extraConfig = ''
      reverse_proxy http://localhost:${listen_port}
    '';
  };
}
