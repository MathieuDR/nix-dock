# Beszel agent reporting to the hub on firesprout over the WireGuard tunnel.
# Run as a podman container: nixos-25.05 predates the services.beszel module, and
# this box already runs everything via oci-containers.
#
# WebSocket mode: the agent dials out to HUB_URL (firesprout at 10.100.0.2:8090).
# --network=host lets it reach the WG IP via the host's wg0. The docker-compat
# socket is mounted so it can report on the other podman containers.
#
# KEY (hub public key) + TOKEN come from the hub UI "Add System" step and live in
# /var/lib/beszel-agent.env (root-only, never in git):
#   KEY=ssh-ed25519 AAAA...
#   TOKEN=<token from the hub>
{...}: {
  virtualisation.podman.dockerSocket.enable = true; # exposes /run/docker.sock

  virtualisation.oci-containers.containers.beszel-agent = {
    image = "henrygd/beszel-agent:latest";
    autoStart = true;
    extraOptions = ["--network=host"];
    environment = {
      HUB_URL = "http://10.100.0.2:8090";
    };
    environmentFiles = ["/var/lib/beszel-agent.env"]; # KEY= , TOKEN=
    volumes = [
      "/run/docker.sock:/var/run/docker.sock:ro"
    ];
  };
}
