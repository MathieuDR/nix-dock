{PII, ...}: {
  services.caddy = {
    enable = true;
    email = PII.caddyEmail;
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
