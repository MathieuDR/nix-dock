{lib, ...}: {
  domain = import ./domain.nix {inherit lib;};
}
