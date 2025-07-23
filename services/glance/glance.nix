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
                      links = [
                        {
                          title = "Whatsapp";
                          icon = "si:whatsapp";
                          url = "https://web.whatsapp.com";
                        }
                        {
                          title = "Github";
                          icon = "si:github";
                          url = "https://www.github.com/";
                        }
                        {
                          title = "Tuta";
                          icon = "si:tuta";
                          url = "https://app.tuta.com/";
                        }
                        {
                          title = "Gmail";
                          icon = "si:gmail";
                          url = "https://mail.google.com/";
                        }
                        {
                          title = "Linear";
                          icon = "si:linear";
                          url = PII.glance.linear;
                        }
                        {
                          title = "CommaFeed";
                          icon = "si:rss";
                          url = domainUtils.domain "https://feed";
                        }
                        {
                          title = "Nix Search";
                          icon = "si:nixos";
                          url = "https://search.nixos.org/packages";
                        }
                        {
                          title = "Actual";
                          icon = "si:actualbudget";
                          url = "https://actual.deraedt.dev/";
                        }
                        {
                          title = "~/.garden";
                          icon = "si:leaflet";
                          url = domainUtils.domain "https://garden";
                        }
                        {
                          title = "Recipes";
                          icon = "si:mealie";
                          url = domainUtils.domain "https://recipes";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
        }

        {
          name = "Markets";
          width = "wide";
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "markets";
                  title = "Indices";
                  markets = [
                    {
                      symbol = "^GDAXI";
                      name = "DAX";
                    }
                    {
                      symbol = "^STOXX50E";
                      name = "EURO STOXX 50";
                    }
                    {
                      symbol = "EURUSD=X";
                      name = "EUR/USD";
                    }
                  ];
                }
                {
                  type = "markets";
                  title = "Crypto";
                  markets = [
                    {
                      symbol = "ETH-EUR";
                      name = "Ethereum";
                    }
                    {
                      symbol = "ADA-EUR";
                      name = "Cardano";
                    }
                    {
                      symbol = "SOL-EUR";
                      name = "Solana";
                    }
                    {
                      symbol = "XRP-EUR";
                      name = "XRP";
                    }
                    {
                      symbol = "LINK-EUR";
                      name = "Chainlink";
                    }
                    {
                      symbol = "DOT-EUR";
                      name = "Polkadot";
                    }
                    {
                      symbol = "MATIC-EUR";
                      name = "Polygon";
                    }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "split-column";
                  max-columns = 3;
                  widgets = [
                    {
                      type = "rss";
                      title = "European News";
                      collapse-after = 11;
                      feeds = [
                        {
                          url = "https://www.ft.com/news-feed?format=rss";
                          title = "Financial times";
                        }
                        {
                          url = "https://rss.nixnet.services/?action=display&bridge=DeutscheWelleBridge&feed=http%3A%2F%2Frss.dw.com%2Fatom%2Frss-en-bus&format=Atom";
                          title = "Deutsche Welle - Business";
                        }
                        {
                          url = "https://feeds.thelocal.com/rss/";
                          title = "The local";
                        }
                      ];
                    }

                    {
                      type = "rss";
                      title = "Global News";
                      collapse-after = 11;

                      feeds = [
                        {
                          url = "https://feeds.bloomberg.com/markets/news.rss";
                          title = "Bloomberg";
                        }
                        {
                          url = "https://feeds.content.dowjones.io/public/rss/RSSMarketsMain";
                          title = "Wall Street Journal";
                        }
                      ];
                    }

                    {
                      type = "rss";
                      title = "Market Insights";
                      collapse-after = 11;
                      feeds = [
                        {
                          url = "https://www.ecb.europa.eu/rss/press.html";
                          title = "ECB Press Releases";
                        }
                        {
                          url = "https://www.esma.europa.eu/rss.xml";
                          title = "European Securities and Markets Authority";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                # {
                #   type = "markets";
                #   title = "Insurances";
                #   markets = [
                #   ];
                # }
                {
                  type = "markets";
                  title = "funds";
                  markets = [
                    {
                      symbol = "0P0001M55Y.F";
                      name = "China New Economy Basis Dis";
                    }
                    {
                      symbol = "0P00019M2F.F";
                      name = "ABN AMRO";
                    }
                    {
                      symbol = "UQ2B.F";
                      name = "Allianz Global Investors Fund AGIF SIC";
                    }
                    {
                      symbol = "0P00019ILC.F";
                      name = "Eurozone S&M";
                    }
                    {
                      symbol = "SKIGLO.CO";
                      name = "SKAGEN Global A (dkk)";
                    }
                    {
                      symbol = "UQ2A.F";
                      name = "Allianz Global Inverstors Fund Europe Equity Growth A DIS";
                    }
                    {
                      symbol = "0P0001KN55.F";
                      name = "NORDEA1 S.European";
                    }
                    {
                      symbol = "0P00000N2T.F";
                      name = "Multifund Balanced";
                    }
                    {
                      symbol = "0P0001K5UT";
                      name = "SCHRODER INTERNAT. Select Fund";
                    }
                    {
                      symbol = "0P00012NDA.F";
                      name = "FLO V Storch-Multi OPP";
                    }
                    {
                      symbol = "0P0001LOCS.F";
                      name = "Premium Crescendo R DIS";
                    }
                    {
                      symbol = "0P00000NCK.F";
                      name = "BNP Paribas B Pension Sust Bal Classic";
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
