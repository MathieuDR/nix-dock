{inputs, ...}: {
  services.caddy.virtualHosts = {
    "weshould.be" = {
      extraConfig = ''
        encode {
          zstd
          gzip
          minimum_length 1024
        }

        header Cache-Control "public, max-age=7200"
        root * ${inputs.we-should-landing.packages.x86_64-linux.default}/share/web
        file_server

        try_files {path} /index.html
      '';
    };
  };
}
