# Beszel agent reporting to the hub on firesprout over the WireGuard tunnel.
# Run as a podman container: nixos-25.05 predates the services.beszel module, and
# this box already runs everything via oci-containers.
#
# WebSocket mode: the agent dials out to HUB_URL (firesprout at 10.100.0.2:8090),
# so nothing needs to reach this box. --network=host lets it use the host's wg0.
# The podman API socket is mounted so it can report on the other containers.
#
# KEY (hub public key) + TOKEN come from the hub UI "Add System" step and live in
# /var/lib/beszel-agent.env (root-only, never in git):
#   KEY=ssh-ed25519 AAAA...
#   TOKEN=<token from the hub>
{...}: {
  virtualisation.podman.dockerSocket.enable = true;

  # The socket only exists once podman.socket is listening; without this the
  # container can start first and the bind mount source is missing (statfs ENOENT).
  systemd.services.podman-beszel-agent = {
    after = ["podman.socket"];
    requires = ["podman.socket"];
  };

  virtualisation.oci-containers.containers.beszel-agent = {
    image = "henrygd/beszel-agent:latest";
    autoStart = true;
    extraOptions = ["--network=host"];
    environment = {
      HUB_URL = "http://10.100.0.2:8090";
      DOCKER_HOST = "unix:///run/podman/podman.sock";
      SERVICE_PATTERNS = "podman-*,caddy*,beszel*,foundryvtt*,glance*,wireguard*";
    };
    environmentFiles = ["/var/lib/beszel-agent.env"]; # KEY= , TOKEN=
    volumes = [
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];
  };
}
