{
  secrets,
  username,
  hostname,
  pkgs,
  inputs,
  config,
  ...
}: {
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_GB.UTF-8";

  systemd.tmpfiles.rules = [
    "d /home/${username}/.config 0755 ${username} users"
  ];

  imports = [
    ./modules
    ./services
    ./bootstrap-flake.nix
  ];

  networking.hostName = "${hostname}";
  environment.enableAllTerminfo = true;
  security.sudo.wheelNeedsPassword = false;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./secrets/id_rsa.pub)
    ];
  };

  # Used for github actions
  users.users.github = {
    isNormalUser = true;
    #TODO: We probably want to __NOT__ have them as a wheel user.
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./secrets/github_actions_garden.pub)
    ];
  };

  home-manager.users.${username} = {
    imports = [
      ./home.nix
    ];
  };

  system.stateVersion = "22.05";
  environment.systemPackages = [pkgs.rsync];

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };

  nix = {
    settings = {
      cores = 1;
      max-jobs = 1;

      trusted-users = [username];

      accept-flake-config = true;
      auto-optimise-store = true;
    };

    registry = {
      nixpkgs = {
        flake = inputs.nixpkgs;
      };
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs.outPath}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    package = pkgs.nixVersions.stable;
    extraOptions = ''experimental-features = nix-command flakes'';

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
  };
}
