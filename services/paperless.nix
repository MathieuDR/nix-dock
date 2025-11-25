{
  self,
  config,
  domainUtils,
  lib,
  ...
}: let
  home = "/srv/paperless";
  data = "${home}/data";
  media = "${home}/media";
  port = "29818";
  tikaPort = "29820";
  gotenbergPort = "29819";
  subDomain = "docs";
in {
  age.secrets = {
    "paperless/env".file = "${self}/secrets/paperless/env.age";
  };

  users.users.paperless = {
    isSystemUser = true;
    group = "paperless";
    home = home;
    uid = 992;
  };

  users.groups.paperless = {
    gid = 992;
  };

  systemd.tmpfiles.rules = [
    "d ${home} 0775 paperless paperless"
    "d ${data} 0775 paperless paperless"
    "d ${media} 0775 paperless paperless"
  ];

  services.restic.backups.b2.paths = [
    media
    "${data}/db.sqlite3"
    "${data}/celerybeat-schedule.db"
    "${data}/index"
    "${data}/nixos-paperless-secret-key"
    "${data}/superuser-state"
  ];

  # Gotenberg for Office document conversion
  virtualisation.oci-containers.containers.gotenberg = {
    image = "gotenberg/gotenberg:8";
    autoStart = true;
    ports = ["${gotenbergPort}:3000"];
    extraOptions = [
      "--user=${toString config.users.users.paperless.uid}:${toString config.users.groups.paperless.gid}"
    ];
  };

  # Tika for Office document parsing
  virtualisation.oci-containers.containers.tika = {
    image = "apache/tika:latest";
    autoStart = true;
    ports = ["${tikaPort}:9998"];
    extraOptions = [
      "--user=${toString config.users.users.paperless.uid}:${toString config.users.groups.paperless.gid}"
    ];
  };

  services.paperless = {
    enable = true;
    environmentFile = config.age.secrets."paperless/env".path;
    consumptionDirIsPublic = true;
    port = builtins.fromJSON port;
    address = "127.0.0.1";
    dataDir = data;
    mediaDir = media;
    user = "paperless";

    settings = {
      # === SECURITY SETTINGS FOR PUBLIC WEB ===
      PAPERLESS_URL = "https://${domainUtils.domain subDomain}";
      PAPERLESS_ALLOWED_HOSTS = domainUtils.domain subDomain;
      PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://${domainUtils.domain subDomain}";
      PAPERLESS_CORS_ALLOWED_HOSTS = "https://${domainUtils.domain subDomain}";

      # Reverse proxy configuration
      PAPERLESS_USE_X_FORWARD_HOST = true;
      PAPERLESS_USE_X_FORWARD_PORT = true;
      PAPERLESS_TRUSTED_PROXIES = "127.0.0.1";
      PAPERLESS_PROXY_SSL_HEADER = ''["HTTP_X_FORWARDED_PROTO", "https"]'';

      # === OCR SETTINGS ===
      PAPERLESS_OCR_PAGES = 1;
      PAPERLESS_OCR_LANGUAGE = "nld+deu+eng";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
        invalidate_digital_signatures = true;
      };

      # === OFFICE DOCUMENT SUPPORT ===
      PAPERLESS_TIKA_ENABLED = true;
      PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:${tikaPort}";
      PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:${gotenbergPort}";

      # === OPTIONAL: BARCODE SUPPORT ===
      # PAPERLESS_CONSUMER_ENABLE_BARCODES = true;
      # PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
      # PAPERLESS_CONSUMER_BARCODE_MAX_PAGES = 1;
    };
  };

  systemd.services.paperless-web.wantedBy = lib.mkForce [];
  systemd.services.paperless-scheduler.wantedBy = lib.mkForce [];
  systemd.services.paperless-consumer.wantedBy = lib.mkForce [];
  systemd.services.paperless-task-queue.wantedBy = lib.mkForce [];

  services.caddy.virtualHosts.${domainUtils.domain subDomain} = {
    extraConfig = ''
      reverse_proxy http://localhost:${port}
      encode {
        zstd
        gzip
        minimum_length 1024
      }

      # Security headers
      header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
      }

      # Increase timeout for large file uploads
      @uploads {
        path /api/documents/post_document*
      }
      reverse_proxy @uploads http://localhost:${port} {
        transport http {
          read_timeout 300s
          write_timeout 300s
        }
      }
    '';
  };
}
