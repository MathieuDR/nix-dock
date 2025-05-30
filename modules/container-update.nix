{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.containerUpdate;
  containers = config.virtualisation.oci-containers.containers;
  makeUpdateScript = name: containerConfig:
    pkgs.writeShellScriptBin "update-${name}" ''
      set -euo pipefail

      SERVICE_NAME="podman-${name}.service"
      IMAGE="${containerConfig.image}"

      echo "🔄 Updating container: ${name}"
      echo "📦 Current image: $IMAGE"

      # Check if service exists and is running
      if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "⚠️  Service $SERVICE_NAME is not running"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "❌ Update cancelled"
          exit 1
        fi
      fi

      echo "⬇️  Pulling latest image..."
      if ! ${pkgs.podman}/bin/podman pull "$IMAGE"; then
        echo "❌ Failed to pull image $IMAGE"
        exit 1
      fi

      echo "🔄 Restarting service..."
      systemctl restart "$SERVICE_NAME"

      # Wait a moment and check if service started successfully
      sleep 2
      if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "✅ Successfully updated and restarted ${name}"
      else
        echo "❌ Service failed to start after update"
        echo "📋 Service status:"
        systemctl status "$SERVICE_NAME" --no-pager -l
        exit 1
      fi

      echo "🧹 Cleaning up old images..."
      ${pkgs.podman}/bin/podman image prune -f

      echo "🎉 Update completed for ${name}"
    '';

  # Create a status script to check all containers
  makeStatusScript = pkgs.writeShellScriptBin "container-status" ''
    set -euo pipefail

    echo "📊 Container Status Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-20s %-15s %-15s %s\n" "SERVICE" "STATUS" "IMAGE AGE" "IMAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    ${concatStringsSep "\n" (mapAttrsToList (name: containerConfig: ''
        SERVICE_NAME="podman-${name}.service"
        IMAGE="${containerConfig.image}"

        if systemctl is-active --quiet "$SERVICE_NAME"; then
          STATUS="✅ running"
        elif systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
          STATUS="⚠️  stopped"
        else
          STATUS="❌ disabled"
        fi

        # Get image creation date
        IMAGE_DATE=$(${pkgs.podman}/bin/podman image inspect "$IMAGE" --format "{{.Created}}" 2>/dev/null) || IMAGE_DATE=""

        if [ -n "$IMAGE_DATE" ]; then
          # Clean up the date format - remove the extra timezone info
          # Convert "2025-03-03 01:20:41.36377766 +0000 UTC" to "2025-03-03 01:20:41 +0000"
          CLEAN_DATE=$(echo "$IMAGE_DATE" | sed 's/\.[0-9]* +[0-9]* UTC/ +0000/')

          IMAGE_EPOCH=$(${pkgs.coreutils}/bin/date -d "$CLEAN_DATE" +%s 2>/dev/null) || IMAGE_EPOCH=0

          if [ "$IMAGE_EPOCH" -gt 0 ]; then
            NOW_EPOCH=$(${pkgs.coreutils}/bin/date +%s)
            DIFF=$((NOW_EPOCH - IMAGE_EPOCH))
            if [ $DIFF -lt 86400 ]; then
              AGE_STR="< 1 day"
            elif [ $DIFF -lt 604800 ]; then
              AGE_STR="$((DIFF / 86400)) days"
            else
              AGE_STR="$((DIFF / 604800)) weeks"
            fi
          else
            AGE_STR="parse error"
          fi
        else
          AGE_STR="not found"
        fi

        printf "%-20s %-15s %-15s %s\n" "${name}" "$STATUS" "$AGE_STR" "$IMAGE"
      '')
      containers)}
  '';
in {
  options.services.containerUpdate = {
    enable = mkEnableOption "container update utilities";
  };

  config = mkIf cfg.enable {
    # Add individual update scripts and status script to system packages
    environment.systemPackages = (
      (mapAttrsToList makeUpdateScript containers)
      ++ [
        makeStatusScript
      ]
    );
  };
}
