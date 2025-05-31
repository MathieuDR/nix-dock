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

      echo "Updating container: ${name}"
      echo "Current image: $IMAGE"

      # Get current image info before update
      CURRENT_ID=$(${pkgs.podman}/bin/podman image inspect "$IMAGE" --format "{{.Id}}" 2>/dev/null | head -c 12) || CURRENT_ID="unknown"
      CURRENT_FULL_DIGEST=$(${pkgs.podman}/bin/podman image inspect "$IMAGE" --format "{{index .RepoDigests 0}}" 2>/dev/null) || CURRENT_FULL_DIGEST="unknown"
      # Extract just the SHA256 part for cleaner rollback commands
      CURRENT_DIGEST=$(echo "$CURRENT_FULL_DIGEST" | sed 's/.*@//' 2>/dev/null) || CURRENT_DIGEST="unknown"

      echo "Current image ID: $CURRENT_ID"
      echo "Current digest: $CURRENT_FULL_DIGEST"

      if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "⚠️  Service $SERVICE_NAME is not running"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "❌ Update cancelled"
          exit 1
        fi
      fi

      echo "Pulling latest image..."
      if ! ${pkgs.podman}/bin/podman pull "$IMAGE"; then
        echo "❌ Failed to pull image $IMAGE"
        exit 1
      fi

      # Get new image info after pull
      NEW_ID=$(${pkgs.podman}/bin/podman image inspect "$IMAGE" --format "{{.Id}}" 2>/dev/null | head -c 12) || NEW_ID="unknown"
      NEW_FULL_DIGEST=$(${pkgs.podman}/bin/podman image inspect "$IMAGE" --format "{{index .RepoDigests 0}}" 2>/dev/null) || NEW_FULL_DIGEST="unknown"
      # Extract just the SHA256 part for cleaner rollback commands
      NEW_DIGEST=$(echo "$NEW_FULL_DIGEST" | sed 's/.*@//' 2>/dev/null) || NEW_DIGEST="unknown"

      if [ "$CURRENT_ID" = "$NEW_ID" ]; then
        echo "No update available - image is already current"
        echo "Current ID: $CURRENT_ID"
        exit 0
      fi

      echo "New image ID: $NEW_ID"
      echo "New digest: $NEW_FULL_DIGEST"

      # Log the update attempt before making changes
      ROLLBACK_LOG="/var/log/container-updates/${name}.log"
      mkdir -p "$(dirname "$ROLLBACK_LOG")"
      echo "$(date -Iseconds) UPDATE ${name}" >> "$ROLLBACK_LOG"
      echo "$(date -Iseconds) ID: $CURRENT_ID -> $NEW_ID" >> "$ROLLBACK_LOG"
      echo "$(date -Iseconds) DIGEST: $CURRENT_FULL_DIGEST -> $NEW_FULL_DIGEST" >> "$ROLLBACK_LOG"
      echo "$(date -Iseconds) PULLED IMAGE $NEW_ID" >> "$ROLLBACK_LOG"
      echo "$(date -Iseconds) ROLLBACK COMMAND: sudo rollback-${name} $CURRENT_DIGEST" >> "$ROLLBACK_LOG"

      echo "Restarting service..."
      systemctl restart "$SERVICE_NAME"

      # Wait a moment and check if service started successfully
      sleep 3
      if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "✅ Successfully updated ${name}"
        echo "   Old: $CURRENT_ID"
        echo "   New: $NEW_ID"
        echo "$(date -Iseconds) UPDATE SUCCESS ${name}" >> "$ROLLBACK_LOG"
      else
        echo "❌ Service failed to start after update"
        echo "Service status:"
        systemctl status "$SERVICE_NAME" --no-pager -l
        echo ""
        echo "To rollback:"
        echo "   rollback-${name} $CURRENT_DIGEST"
        echo ""
        echo "Update log: $ROLLBACK_LOG"
        echo "$(date -Iseconds) UPDATE FAILED ${name}" >> "$ROLLBACK_LOG"
        exit 1
      fi

      echo "Cleaning up old images..."
      ${pkgs.podman}/bin/podman image prune -f

      echo "✅ Update completed for ${name}"
    '';

  makeStatusScript = pkgs.writeShellScriptBin "container-status" ''
    set -euo pipefail

    echo "Container Status Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-20s %-15s %-15s %-12s %s\n" "SERVICE" "STATUS" "IMAGE AGE" "IMAGE ID" "IMAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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

        # Get image info
        IMAGE_INFO=$(${pkgs.podman}/bin/podman image inspect "$IMAGE" 2>/dev/null) || IMAGE_INFO=""

        if [ -n "$IMAGE_INFO" ]; then
          IMAGE_DATE=$(echo "$IMAGE_INFO" | ${pkgs.jq}/bin/jq -r '.[0].Created // ""' 2>/dev/null) || IMAGE_DATE=""
          IMAGE_ID=$(echo "$IMAGE_INFO" | ${pkgs.jq}/bin/jq -r '.[0].Id // ""' 2>/dev/null | head -c 12) || IMAGE_ID="unknown"
        else
          IMAGE_DATE=""
          IMAGE_ID="not found"
        fi

        if [ -n "$IMAGE_DATE" ]; then
          # Parse the date (handling the format from your example)
          IMAGE_EPOCH=$(${pkgs.coreutils}/bin/date -d "$IMAGE_DATE" +%s 2>/dev/null) || IMAGE_EPOCH=0

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

        printf "%-20s %-15s %-15s %-12s %s\n" "${name}" "$STATUS" "$AGE_STR" "$IMAGE_ID" "$IMAGE"
      '')
      containers)}
  '';

  makeRollbackScript = name: containerConfig:
    pkgs.writeShellScriptBin "rollback-${name}" ''
      set -euo pipefail

      if [ $# -ne 1 ]; then
        echo "Usage: rollback-${name} <sha256-digest>"
        echo "Example: rollback-${name} sha256:146dcf7daaee7a07ed3e07d5f8bd6dce2cadfd2993600035df1155cfecffxxxx"
        echo "   or: rollback-${name} {image}@sha256:146dcf7daaee7a07ed3e07d5f8bd6dce2cadfd2993600035df1155cfecffxxxx"
        exit 1
      fi

      SERVICE_NAME="podman-${name}.service"
      IMAGE="${containerConfig.image}"
      TARGET_DIGEST="$1"
      ROLLBACK_LOG="/var/log/container-updates/${name}.log"

      echo "Rolling back ${name} to digest: $TARGET_DIGEST"

      # Log the rollback attempt
      echo "$(date -Iseconds) ROLLBACK ${name} ($TARGET_DIGEST)" >> "$ROLLBACK_LOG"

      if [[ "$TARGET_DIGEST" == *"@sha256:"* ]]; then
        FULL_DIGEST="$TARGET_DIGEST"
      else
        FULL_DIGEST="$IMAGE@$TARGET_DIGEST"
      fi

      echo "Pulling: $FULL_DIGEST"

      if ! ${pkgs.podman}/bin/podman pull "$FULL_DIGEST"; then
        echo "❌ Failed to pull rollback image"
        echo "$(date -Iseconds) ROLLBACK PULL FAILED ${name} ($TARGET_DIGEST)" >> "$ROLLBACK_LOG"
        exit 1
      fi

      echo "$(date -Iseconds) ROLLBACK PULLED IMAGE $TARGET_DIGEST" >> "$ROLLBACK_LOG"

      # Tag it back to the original name
      ${pkgs.podman}/bin/podman tag "$FULL_DIGEST" "$IMAGE"

      echo "Restarting service..."
      systemctl restart "$SERVICE_NAME"

      sleep 2
      if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "✅ Successfully rolled back ${name}"
        echo "$(date -Iseconds) ROLLBACK SUCCESS ${name} ($TARGET_DIGEST)" >> "$ROLLBACK_LOG"
      else
        echo "❌ Service failed to start after rollback"
        systemctl status "$SERVICE_NAME" --no-pager -l
        echo "$(date -Iseconds) ROLLBACK FAILED ${name} ($TARGET_DIGEST)" >> "$ROLLBACK_LOG"
        exit 1
      fi
    '';
in {
  options.services.containerUpdate = {
    enable = mkEnableOption "container update utilities";
  };

  config = mkIf cfg.enable {
    # Create log directory
    systemd.tmpfiles.rules = [
      "d /var/log/container-updates 0755 root root -"
    ];

    environment.systemPackages = (
      (mapAttrsToList makeUpdateScript containers)
      ++ (mapAttrsToList makeRollbackScript containers)
      ++ [
        makeStatusScript
      ]
    );
  };
}
