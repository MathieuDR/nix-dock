let
  hetzner = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJa3iDiDQm3uziiFbdxxkGwAlocuR8ri4nol3/MpjRzb";
  local = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDd2P9hIkXQWtkEvOIP5g+vDhDQCkypRfOOBw+x6SVe19LIenmA7zn0b8943oUuf9X85Wv1p3X4uDDXsUyddQTS6ereADETUZmKrGPhXCwCardfXP8cT956FUpjKGSIL5ZDHYGf7vs1hUDaGpv+QdwIirMF+4HZd/vlmctudwgym6E8pGdCOeA+bJ8v89PX7VtXbsVKO/bNrZ3HUoTPN5ZjbS1718IvfMkIQdo0onzAtvgW8j67oXfLjXMuRLghRE9PyFKdIOwCSAdqe7kef4Nvzoj5HvJwEF1dU96AMFarr+aCRah2sMOZkZ1chwrg3DukTwPdiklMP3OufsTjnUTV/4PBW9h7YX8ME0aWn3rW7EucXM8jwVK5J6/J+biDi5avS/DGpA9TAB3qS38wPQZAOwjqrQw8wOO7oOvhr4RtyEg738Vu7K/kj+z2w/q46AGAs2H1G3mBkc3xxb1VTqpqpEbosECpLkS/RqgKpTmMXAvdEC9e972E5+WmPQqqzNbll+A0qzIkd1KEqxA9KDzPyipyh6Zj+9JtTggGgjWnOwLprMHjVzIv68twR1tJK/jxAyv7FnlOmS8VOyW07pl1J1iLyOmM3NE/Y6SCzhrX8M3Scpq2qGsS3eHPPg0KLVwjpXTuPfew39kFUZaI0O+9sbKgzdfEVYTavByC1sutYQ== personalEmail";
  all_recipients = [hetzner local];
in {
  # Restic
  "restic/env.age".publicKeys = all_recipients;
  "restic/repo.age".publicKeys = all_recipients;
  "restic/password.age".publicKeys = all_recipients;

  # Livebook
  "livebook/env.age".publicKeys = all_recipients;

  # Common
  "common/ghp.age".publicKeys = all_recipients;

  # Automator
  "osrs-automator/appsettings.override.json.age".publicKeys = all_recipients;

  # recipes
  "recipes/env.age".publicKeys = all_recipients;

  # readdeck
  "readdeck/token.age".publicKeys = all_recipients;

  # commafeed
  "commafeed/token.age".publicKeys = all_recipients;

  #plausible
  "plausible/passwordfile.age".publicKeys = all_recipients;
  "plausible/secretkeyfile.age".publicKeys = all_recipients;
}
