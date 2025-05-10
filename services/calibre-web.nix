{domainUtils, ...}: let
  web_data_dir = "calibre-web";
  library = "/var/lib/calibre-library";
in {
  services.calibre-web = {
    enable = true;

    dataDir = web_data_dir;
    listen = {
      port = 8883;
      ip = "127.0.0.1";
    };

    options = {
      enableBookUploading = false;
      calibreLibrary = library;
    };
  };

  services.restic.backups.b2.paths = [
    "/var/lib/${web_data_dir}"
    library
  ];

  services.caddy.virtualHosts.${domainUtils.domain "books"} = {
    extraConfig = ''
      reverse_proxy http://localhost:8883
      encode {
        zstd
        gzip
        minimum_length 1024
      }
    '';
  };
}
