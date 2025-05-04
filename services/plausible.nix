{
  self,
  config,
  domainUtils,
  PII,
  lib,
  ...
}: let
  listen_port = "9342";
  domain = domainUtils.domain "stats";
  baseurl = lib.concatStrings ["https://" domain];
in {
  age.secrets = {
    "plausible/password".file = "${self}/secrets/plausible/passwordfile.age";
    "plausible/secretkey".file = "${self}/secrets/plausible/secretkeyfile.age";
  };

  services.plausible = {
    enable = true;
    adminUser = {
      name = PII.plausible.admin;
      email = PII.email;
      passwordFile = config.age.secrets."plausible/password".path;
      activate = false;
    };
    server = {
      baseUrl = baseurl;
      secretKeybaseFile = config.age.secrets."plausible/secretkey".path;
      port = lib.strings.toInt listen_port;
    };
  };

  services.caddy.virtualHosts.${domain} = {
    extraConfig = ''
      reverse_proxy http://localhost:${listen_port}

      header {
        Access-Control-Allow-Origin ${domainUtils.domain "https://garden"}
        Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization"
        Access-Control-Allow-Credentials true

        # Efficient handling of preflight OPTIONS requests
        @options {
          method OPTIONS
        }
        handle @options {
          respond 204
        }
      }
    '';
  };
}
