# WireGuard tunnel anchor for firesprout (home server behind Vodafone CGNAT).
# This VPS has the public IP; firesprout dials in and holds the tunnel open. Once up, Caddy
# reverse-proxies drakkenheim.deraedt.dev over the tunnel to Foundry on firesprout.
# Private key at /etc/wireguard/wg0.key (on the box, never in git). See the firesprout repo's
# foundry-tunnel-plan.md.
{...}: {
  networking.firewall.allowedUDPPorts = [51820];

  networking.wireguard.interfaces.wg0 = {
    ips = ["10.100.0.1/24"];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/wg0.key";
    peers = [
      {
        # firesprout (home server)
        publicKey = "sgsK7fX2yKYO+DOxuzKPy0mKclO60/UuT0J8S5GZ+kE=";
        allowedIPs = ["10.100.0.2/32"];
        # no endpoint: firesprout dials in from behind CGNAT
      }
    ];
  };
}
