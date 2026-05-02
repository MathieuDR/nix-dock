{
  domainUtils,
  self,
  config,
  ...
}: let
  data_dir = "/srv/shlink";
  shlink_port = 8080;
  domain = domainUtils.domain "l";
  reroute = domainUtils.domain "mathieu";
in {
  age.secrets."shlink/key".file = "${self}/secrets/shlink/key.age";

  virtualisation.oci-containers.containers.shlink = {
    image = "ghcr.io/shlinkio/shlink:stable";
    autoStart = true;

    volumes = [
      "${data_dir}:/etc/shlink/data"
    ];

    environment = {
      DEFAULT_DOMAIN = domain;
      IS_HTTPS_ENABLED = "true";
      # Migh fuck up in migrations.
      DB_DRIVER = "sqlite";
      ANONYMIZE_REMOTE_ADDR = "true";
      SKIP_INITIAL_GEOLITE_DOWNLOAD = "true";
      DEFAULT_BASE_URL_REDIRECT = "https://${reroute}";
      DEFAULT_INVALID_SHORT_URL_REDIRECT = "https://${reroute}";
      INITIAL_API_KEY_FILE = config.age.secrets."shlink/key".path;
    };

    ports = [
      "127.0.0.1:${toString shlink_port}:8080"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${data_dir} 0755 1001 1001"
  ];

  services.restic.backups.b2.paths = [
    data_dir
  ];

  services.caddy.virtualHosts.${domain} = {
    extraConfig = ''
      encode gzip zstd
      reverse_proxy http://localhost:${toString shlink_port}
    '';
  };
}
