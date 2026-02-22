{pkgs, ...}: let
  bootstrap-git-agecrypt = pkgs.writeShellApplication {
    name = "bootstrap-git-agecrypt";
    runtimeInputs = [pkgs.jq pkgs.git pkgs.git-agecrypt];
    text = ''
      REPO_DIR="/etc/nixdock"
      KEY_PATH="/etc/ssh/vps-git-agecrypt.key"

      cd "$REPO_DIR"

      # Check if key exists
      if [ ! -f "$KEY_PATH" ]; then
        echo "git-agecrypt key not found at $KEY_PATH, skipping"
        exit 0
      fi

       if jq empty secrets/PII.json > /dev/null 2>&1; then
        echo "git-agecrypt already configured and files decrypted, skipping"
        exit 0
      fi

      echo "Configuring git-agecrypt..."
      if ! git config --get-all git-agecrypt.config.identity | grep -q "$KEY_PATH"; then
        git-agecrypt config add -i "$KEY_PATH"
      fi

      git-agecrypt init

      rm secrets/PII.json secrets/.envrc_pii
      git checkout HEAD -- secrets/PII.json secrets/.envrc_pii

      echo "git-agecrypt bootstrap complete"
    '';
  };
in {
  environment.systemPackages = [bootstrap-git-agecrypt];
  systemd.services.bootstrap-flake = {
    description = "Bootstrap nixos flake from Github";
    wantedBy = ["multi-user.target"];
    unitConfig.ConditionPathExists = "!/etc/nixdock/.git";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git clone https://github.com/MathieuDR/nix-dock.git /etc/nixdock";
    };
  };
}
