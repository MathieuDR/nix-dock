{inputs, ...}: {
  services.caddy.virtualHosts = {
    "weshould.be" = {
      serverAliases = ["www.weshould.be" "weshould.be"];
      extraConfig = ''
        encode {
          zstd
          gzip
          minimum_length 1024
        }

        header Cache-Control "public, max-age=7200"
        root * ${inputs.we-should-be.packages.x86_64-linux.default}/share/web
        try_files {path} /index.html
        file_server
      '';
    };
  };
}
