# Beszel agent reporting to the hub on firesprout over the WireGuard tunnel.
# Native service, like firesprout. nixos-25.05 predates the services.beszel module,
# so we import it from nixpkgs-unstable and take the package from the unstable overlay.
# Running native (not in a container) is what lets SERVICE_PATTERNS see host systemd
# units and lets the agent read /run/podman/podman.sock directly.
#
# WebSocket mode: the agent dials out to HUB_URL (firesprout at 10.100.0.2:8090), so
# nothing needs to reach this box. KEY (hub public key) + TOKEN come from the hub UI
# "Add System" step and live in /var/lib/beszel-agent.env (root-only, never in git):
#   KEY=ssh-ed25519 AAAA...
#   TOKEN=<token from the hub>
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/beszel-agent.nix"
  ];

  # The module adds the agent to the podman group only when this is on.
  virtualisation.podman.dockerSocket.enable = true;

  services.beszel.agent = {
    enable = true;
    package = pkgs.unstable.beszel;
    environmentFile = "/var/lib/beszel-agent.env"; # KEY= , TOKEN=
    environment = {
      HUB_URL = "http://10.100.0.2:8090";
      DISABLE_SSH = "true"; # WebSocket mode
      DOCKER_HOST = "unix:///run/podman/podman.sock";
      SERVICE_PATTERNS = "podman-*,caddy*,beszel*,foundryvtt*,glance*,wireguard*";
    };
  };
}
