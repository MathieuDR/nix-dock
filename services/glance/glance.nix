{
  self,
  pkgs,
  lib,
  config,
  PII,
  domainUtils,
  ...
}: let
  settingsFormat = pkgs.formats.yaml {};
  secretsMap = {
    "__READDECK_TOKEN__" = config.age.secrets."readdeck/token".path;
    "__COMMAFEED_TOKEN__" = config.age.secrets."commafeed/token".path;
  };

  mkReadLaterWidget = (import ./widgets/readdeck.nix {inherit pkgs lib PII;}).mkReadLaterWidget;
  mkCommaFeedWidget = (import ./widgets/commafeed.nix {inherit pkgs lib PII;}).mkCommaFeedWidget;

  assets_store = builtins.path {
    path = ./assets;
    name = "glance-assets";
  };

  assets_dir = "/srv/glance/assets";
in {
  age.secrets = {
    "commafeed/token" = {
      file = "${self}/secrets/commafeed/token.age";
      group = config.users.groups.keys.name;
      mode = "0440";
    };
    "readdeck/token" = {
      file = "${self}/secrets/readdeck/token.age";
      group = config.users.groups.keys.name;
      mode = "0440";
    };
  };

  system.activationScripts.copyGlanceAssets = ''
    cp -r ${assets_store}/* ${assets_dir}/

    # Set permissions to 0440 (read-only for user and group)
    find ${assets_dir} -type f -exec chmod 0440 {} \;

    # Ensure directory permissions are appropriate (traversable but not writable)
    find ${assets_dir} -type d -exec chmod 0550 {} \;

    # Set ownership for all files
    chown -R root:${config.users.groups.keys.name} ${assets_dir}
  '';

  systemd.tmpfiles.rules = [
    "d ${assets_dir} 0755 root ${config.users.groups.keys.name} -"
  ];

  services.glance = {
    enable = true;
    package = pkgs.unstable.glance;
    settings = {
      server = {
        port = 5779;
        "assets-path" = assets_dir;
      };
      theme = {
        "background-color" = "240 21 15";
        "contrast-multiplier" = 1.2;
        "primary-color" = "267 84 81";
        "positive-color" = "115 54 76";
        "negative-color" = "343 81 75";
      };
      branding = {
        "custom-footer" = "Reading by choice, not by algorithm.";
        "logo-text" = "yS";
      };
      document = {
        head = ''
          <script src="/assets/configuration.js"></script>
          <script src="/assets/commafeed.js"></script>
        '';
      };
      pages = [
        {
          name = "Home";
          width = "wide";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                }
                {
                  type = "split-column";
                  widgets = [
                    {
                      type = "group";
                      widgets = [
                        (mkReadLaterWidget {
                          title = "Read later";
                        })
                        (mkReadLaterWidget {
                          title = "Tech stuff";
                          query = "limit=10&is_archived=false&read_status=unread&read_status=reading&labels=tech";
                        })
                        (mkReadLaterWidget {
                          title = "Archived";
                          query = "limit=10&is_archived=true";
                        })
                      ];
                    }
                    {
                      type = "group";
                      widgets = [
                        (mkCommaFeedWidget {
                          title = "Tech feed";
                        })
                        (mkCommaFeedWidget {
                          title = "News feed";
                          categoryId = "8";
                        })
                      ];
                    }
                  ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "calendar";
                }
                {
                  location = lib.strings.concatStrings [PII.location.city ", " PII.location.country];
                  type = "weather";
                }
                {
                  type = "bookmarks";
                  groups = [
                    {
                      title = "Comms";
                      links = [
                        {
                          title = "Whatsapp";
                          icon = "si:whatsapp";
                          url = "https://web.whatsapp.com";
                        }
                        {
                          title = "Gmail";
                          icon = "si:gmail";
                          url = "https://mail.google.com/";
                        }
                        {
                          title = "Tuta";
                          icon = "si:tuta";
                          url = "https://app.tuta.com/";
                        }
                      ];
                    }
                    {
                      title = "Dev";
                      links = [
                        {
                          title = "Github";
                          icon = "si:github";
                          url = "https://www.github.com/";
                        }
                        {
                          title = "Linear";
                          icon = "si:linear";
                          url = PII.glance.linear;
                        }
                        {
                          title = "Nix Search";
                          icon = "si:nixos";
                          url = "https://search.nixos.org/packages";
                        }
                      ];
                    }
                    {
                      title = "Read";
                      links = [
                        {
                          title = "CommaFeed";
                          icon = "si:rss";
                          url = domainUtils.domain "https://feed";
                        }
                        {
                          title = "Ground News";
                          icon = "mdi:earth";
                          url = "https://www.ground.news";
                        }
                      ];
                    }
                    {
                      title = "Garden";
                      links = [
                        {
                          title = "~/.garden";
                          icon = "si:leaflet";
                          url = domainUtils.domain "https://mathieu";
                        }
                        {
                          title = "Insights";
                          icon = "auto-invert sh:goatcounter-light";
                          url = domainUtils.domain "https://insights";
                        }
                      ];
                    }
                    {
                      title = "Apps";
                      links = [
                        {
                          title = "Immich";
                          icon = "si:immich";
                          url = domainUtils.domain "https://pics.home";
                        }
                        {
                          title = "Paperless";
                          icon = "si:paperlessngx";
                          url = domainUtils.domain "https://docs.home";
                        }
                        {
                          title = "Actual";
                          icon = "si:actualbudget";
                          url = domainUtils.domain "https://actual.home";
                        }
                        {
                          title = "Recipes";
                          icon = "si:mealie";
                          url = domainUtils.domain "https://recipes.home";
                        }
                      ];
                    }
                    {
                      title = "Infra";
                      links = [
                        {
                          title = "Status";
                          icon = "auto-invert sh:gatus-light";
                          url = domainUtils.domain "https://status.home";
                        }
                        {
                          title = "Metrics";
                          icon = "auto-invert sh:beszel-light";
                          url = domainUtils.domain "https://metrics.home";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };

  systemd.services.glance = {
    serviceConfig = {
      ExecStart = lib.mkForce "${
        pkgs.writeShellScriptBin "glance-wrapper" ''
          BASE_CONFIG="${settingsFormat.generate "glance-base.yaml" config.services.glance.settings}"

          FINAL_CONFIG=$(mktemp)
          cp "$BASE_CONFIG" "$FINAL_CONFIG"

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              placeholder: secretPath: ''sed -i "s|${placeholder}|$(cat ${secretPath})|g" "$FINAL_CONFIG"''
            )
            secretsMap
          )}

          exec ${lib.getExe config.services.glance.package} --config "$FINAL_CONFIG"
        ''
      }/bin/glance-wrapper";

      SupplementaryGroups = [config.users.groups.keys.name];
    };
  };

  services.caddy.virtualHosts.${domainUtils.domain "glance"} = {
    extraConfig = ''
      reverse_proxy http://localhost:5779
    '';
  };
}
