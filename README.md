# NixOS Configuration

This repository contains the NixOS configuration for a Hetzner server setup. 
It includes various services and configurations managed through Nix flakes.

## System Overview
- **NixOS Version**: 22.05

## Key Components

1. **Flake Structure**
2. **Disk Configuration**
   - Uses `disko` for disk partitioning and LVM setup
   - Actually never tried I think.

3. **Network Configuration**
   - Hostname: from PII.json or "nixserver"
   - SSH access enabled, with a RSA keyfile.

4. [**Secrets & PII**](secrets/README.md)
    - Uses [Age](https://github.com/FiloSottile/age), especially [agenix](https://github.com/ryantm/agenix)
    - Uses [GIT-Agecrypt](https://github.com/vlaci/git-agecrypt) for PII.

4. **User Configuration**
   - Main user: Username in *PII.json* (with sudo access)
   - Additional user: github (with sudo access, consider removing wheel group)

5. [**Services**](services/README.md)
   - Podman
   - Caddy (as reverse proxy)
   - [Restic](services/RESTIC.md) (for backups)
   - Opensource tools
      - [Actual](https://actualbudget.org/)
      - [Livebook](https://livebook.dev/)
      - [Glance](https://github.com/glanceapp/glance) (homepage dashboard)
      - [Calibre-web](https://github.com/janeczku/calibre-web)
      - [Commafeed](https://github.com/Athou/commafeed)
      - [Quartz](https://github.com/jackyzha0/quartz) (Notes)
      - [Mealie](https://github.com/mealie-recipes/mealie) (recipes)
      - [Memos](https://github.com/usememos/memos) (personal twitter)
      - [Readdeck](https://readeck.org/en/) ([codeberg](https://codeberg.org/readeck/readeck)) (A bookmark tool)
   - Custom services:
     - OSRS Automator (Discord bot)
     
6. **Home Manager**
   - Manages user environment for the *main user*
   - Installs and configures various CLI tools and applications

7. **Development Environment**
   - Git configuration
   - Various development tools (bat, curl, httpie, etc.)

8. **Backup Configuration**
   - Uses Restic for backups
   - Backs up specific paths for each service

## Important Files

- `flake.nix`: Main configuration entry point
- `configuration.nix`: Core NixOS configuration
- `hetzner.nix`: Hetzner-specific configuration
- `disk-config.nix`: Disk partitioning setup
- `home.nix`: Home Manager configuration
- `services/default.nix`: Service configurations
- `services/<service-name>.nix`: Individual service configurations

## Usage
### Deployment

To deploy this configuration to a new NixOS system:

```bash
just wipe
```

This command will wipe the existing configuration and deploy the new one. It doesn't even have to be running NixOS.

### Rebuilding

To rebuild the NixOS configuration:

```bash
just rebuild
```

For a rebuild without using the cache:

```bash
just rebuild-no-cache
```

### Connecting to the Server

To connect to the server via SSH:

```bash
just connect
```

## Adding New Services

To add a new service:

1. Add the service configuration files in `services/`
2. Import the new service in `services/default.nix`
3. Update the `flake.nix` if necessary

## Maintenance

- Regularly update the flake inputs
- Monitor disk usage and adjust partitions if needed
- Review and rotate SSH keys periodically
- Check and update backup configurations

## TODOS
- [ ] Create a module out of services
- [ ] ! ROTATE GHP KEY
