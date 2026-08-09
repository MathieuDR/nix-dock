{domainUtils, ...}: {
  # CouchDB
  # networking.firewall.interfaces.wg0.allowedTCPPorts = [5984];
  services.caddy.virtualHosts.${domainUtils.domain "livesync"} = {
    extraConfig = ''
      encode {
        zstd
        gzip
        minimum_length 1024
      }

      reverse_proxy 10.100.0.2:5984
    '';
  };
}
