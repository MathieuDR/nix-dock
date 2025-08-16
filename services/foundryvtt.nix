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
    proxyPort = 8412;
    package = inputs.foundryvtt.packages.${pkgs.system}.foundry_vtt_13.overrideAddrs {
      version = "13.347";
    };
    minifyStaticFiles = true;
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
}
