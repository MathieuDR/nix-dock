{
  pkgs,
  lib,
  PII,
  ...
}: let
  utils = import ../utils {inherit lib;};
  domainHelpers = {
    domain = subdomain: utils.domain.mkSubdomain PII.domain subdomain;
    domains = subdomains: utils.domain.mkSubdomains PII.domain subdomains;
  };

  cd_script = pkgs.writeShellApplication {
    name = "deploy_image";
    text = ''
      set -euo pipefail

      if [ $# -ne 3 ]; then
          echo "Usage: $0 <IMAGE URL> <IMAGE TAG> <SERVICE> <TOKEN>"
          echo "Example: $0 ghcr.io/MathieuDR/foo latest podman-foo gh..."
          exit 1
      fi

      IMAGE_URL=''${1,,}
      IMAGE_TAG=$2
      SERVICE=$3

      # Pull the latest image
      sudo podman pull "''${IMAGE_URL}:''${IMAGE_TAG}"

      # Restart the systemd service
      sudo systemctl restart "''${SERVICE}"

      # Prune old images
      sudo podman image prune -af

      echo "Pulled image with tag ''${IMAGE_TAG} to update ''${SERVICE}"
    '';
  };
in {
  _module.args = {
    customUtils = utils;
    domainUtils = domainHelpers;
  };

  imports = [
    ./glance
    ./plausible
    ./restic.nix
    ./caddy.nix
    ./livebook.nix
    ./garden.nix
    ./osrs-automator/automator.nix
    ./actual.nix
    ./mealie.nix
    ./calibre-web.nix
    ./memos.nix
    ./commafeed.nix
    ./readdeck.nix
    ./satisfactory.nix
  ];

  services.containerUpdate.enable = true;
  environment.systemPackages = [cd_script];
}
