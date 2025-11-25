{
  pkgs,
  username,
  nix-index-database,
  inputs,
  PII,
  ...
}: let
  unstable-packages = with pkgs.unstable; [
    bat
    bottom
    curl
    dust
    fd
    fx
    git
    htop
    yq
    killall
    mosh
    procs
    sd
    tree
    unzip
    vim
    wget
    zip
    httpie
  ];

  stable-packages = with pkgs; [
  ];
in {
  imports = [
    nix-index-database.hmModules.nix-index
  ];

  home.stateVersion = "22.11";

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

    sessionVariables.EDITOR = "nvim";
  };

  home.packages =
    stable-packages
    ++ unstable-packages
    ++ [
      (inputs.yvim.packages.x86_64-linux.default)
    ];

  programs = {
    home-manager.enable = true;
    nix-index.enable = true;
    nix-index-database.comma.enable = true;

    fzf.enable = true;
    broot.enable = true;
    gh.enable = true;
    jq.enable = true;
    ripgrep.enable = true;

    zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
      enableBashIntegration = true;
    };

    lsd = {
      enable = true;
      enableBashIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      settings = builtins.fromJSON (builtins.readFile ./dotfiles/.ysomic.omp.json);
    };

    git = {
      enable = true;
      package = pkgs.unstable.git;
      delta.enable = true;
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };
      userEmail = PII.git.userEmail;
      userName = "MathieuDR";
      extraConfig = {
        push = {
          default = "current";
          autoSetupRemote = true;
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
    };

    bash = {
      enable = true;
      historySize = 2500;
    };
  };
}
