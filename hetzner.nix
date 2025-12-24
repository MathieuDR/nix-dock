{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services = {
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    journald.extraConfig = ''
      SystemMaxUse=300M
      SystemMaxFileSize=50M
      MaxRetentionSec=1week
      MaxFileSec=1day
      RuntimeMaxUse=100M
    '';
  };

  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };

  # Make system.slice protected (keeps critical system services alive)
  systemd.slices.system = {
    sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "80%";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ./secrets/id_rsa.pub)
  ];
}
