{
  pkgs,
  self,
  config,
  ...
}: {
  age.secrets = {
    "codeberg/runner".file = "${self}/secrets/codeberg/runner.age";
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "hetzner-vps";
      url = "https://codeberg.org";

      tokenFile = config.age.secrets."codeberg/runner".path;

      labels = [
        "ubuntu-latest:docker://node:16-bullseye"
        "ubuntu-22.04:docker://node:16-bullseye"
        "native:host"
      ];
    };
  };
}
