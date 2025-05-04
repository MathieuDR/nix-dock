{
  self,
  config,
  ...
}: let
  env_folder = "osrs-automator";
  env_file = "${env_folder}/env";
  db_dir = "/srv/osrs-automator/data";
  appsettings = "${env_folder}/appsettings.json";
in {
  age.secrets = {
    "common/ghp".file = "${self}/secrets/common/ghp.age";
    "osrs-automator/appsettings.override.json".file = "${self}/secrets/osrs-automator/appsettings.override.json.age";
  };

  virtualisation.oci-containers.containers.osrs-automator = {
    image = "ghcr.io/mathieudr/osrs-automator:latest";
    autoStart = true;

    environmentFiles = [
      "/etc/${env_file}"
    ];

    volumes = [
      "${db_dir}:/app/data"
      "/etc/${appsettings}:/app/appsettings.json"
      "${config.age.secrets."osrs-automator/appsettings.override.json".path}:/app/appsettings.production.json"
    ];

    # Auth
    login = {
      username = "MathieuDR";
      registry = "https://ghcr.io";
      passwordFile = config.age.secrets."common/ghp".path;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${db_dir} 0755 root root -"
  ];

  services.restic.backups.b2.paths = [
    db_dir
    "/etc/${appsettings}"
  ];

  environment.etc = {
    ${env_file} = {
      enable = true;
      mode = "0440";
      source = ./automator.env;
    };

    ${appsettings} = {
      enable = true;
      mode = "0440";
      source = ./appsettings.json;
    };
  };
}
