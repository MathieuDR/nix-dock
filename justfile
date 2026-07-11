# Define the default recipe to list available commands
default:
  @just --list

# Wipes nixos, and puts new config on it. Also wipes the know host lines (line 4)
# wipe:
# 	sed -i '4d' ~/.ssh/known_hosts
# 	sed -i '4d' ~/.ssh/known_hosts
# 	nix run github:nix-community/nixos-anywhere -- --flake .#nixos root@${SERVER_IP}

# Local Rebuild nixos, no wipy
rebuild-local:
	nixos-rebuild switch --flake .#nixos

# Rebuilds nixos, doesn't wipe
rebuild:
	nixos-rebuild switch --flake .#nixos --target-host root@${SERVER_IP}

# Rebuilds nixos, doesn't wipe, with no cache
rebuild-no-cache:
	nixos-rebuild switch --flake .#nixos --target-host root@${SERVER_IP} --option eval-cache false

# Rebuilds nixos, doesn't wipe, with a trace
rebuild-trace:
	nixos-rebuild switch --flake .#nixos --target-host root@${SERVER_IP} --show-trace

# Rebuilds nixos, doesn't wipe, with no cache
rebuild-trace-no-cache:
	nixos-rebuild switch --flake .#nixos --target-host root@${SERVER_IP} --option eval-cache false --show-trace

sftp:
	sftp ${SERVER_USERNAME}@${SERVER_IP}

connect:
	ssh ${SERVER_USERNAME}@${SERVER_IP}

connect-root:
	ssh root@${SERVER_IP}

sync-calibre:
  rsync -avz --delete --exclude='*/data/' --chown=calibre-web:calibre-web --chmod=D2775,F664 "${LOCAL_CALIBRE}" "root@${SERVER_IP}:/var/lib/calibre-library/"

sync-foundry action="dry":
  @if [ "{{action}}" = "dry" ]; then \
      echo "===================================================="; \
      echo "🔍 DRY RUN: Out-of-date locally (Needs PUSH to Remote)"; \
      echo "===================================================="; \
      rsync -avzun --chmod=D755,F644 "${LOCAL_FOUNDRY_ASSETS}/" "${SERVER_USERNAME}@${SERVER_IP}:~/foundry_assets/"; \
      echo ""; \
      echo "===================================================="; \
      echo "🔍 DRY RUN: Out-of-date remotely (Needs PULL to Local)"; \
      echo "===================================================="; \
      rsync -avzun "${SERVER_USERNAME}@${SERVER_IP}:~/foundry_assets/" "${LOCAL_FOUNDRY_ASSETS}/"; \
  elif [ "{{action}}" = "push" ]; then \
      echo "Pushing local to remote..."; \
      rsync -avz --progress --chmod=D755,F644 "${LOCAL_FOUNDRY_ASSETS}/" "${SERVER_USERNAME}@${SERVER_IP}:~/foundry_assets/"; \
  elif [ "{{action}}" = "pull" ]; then \
      echo "Pulling remote to local..."; \
      rsync -avz --progress "${SERVER_USERNAME}@${SERVER_IP}:~/foundry_assets/" "${LOCAL_FOUNDRY_ASSETS}/"; \
  elif [ "{{action}}" = "bi" ]; then \
      echo "🔄 Performing two-way update (keeping newer)..."; \
      echo "-> Pushing newer local files..."; \
      rsync -avzu --progress --chmod=D755,F644 "${LOCAL_FOUNDRY_ASSETS}/" "${SERVER_USERNAME}@${SERVER_IP}:~/foundry_assets/"; \
      echo "-> Pulling newer remote files..."; \
      rsync -avzu --progress "${SERVER_USERNAME}@${SERVER_IP}:~/foundry_assets/" "${LOCAL_FOUNDRY_ASSETS}/"; \
  else \
      echo "❌ Invalid action. Use 'dry', 'push', 'pull', or leave blank for 'bi'."; \
      exit 1; \
  fi
