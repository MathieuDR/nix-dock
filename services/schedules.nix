{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.dock.schedules;
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # Guard each unit so a subscription to an absent unit is skipped, not fatal.
  runOn = verb: units:
    pkgs.writeShellScript "schedule-${verb}" (lib.concatMapStringsSep "\n" (u: ''
        if ${systemctl} cat ${u} >/dev/null 2>&1; then
          ${systemctl} ${verb} ${u} || true
        else
          echo "skip: ${u} not present"
        fi
      '')
      units);

  hasPause = cfg.pauseDuringDnd != [];
  hasRestart = cfg.nightlyRestart != [];
in {
  options.dock.schedules = {
    pauseDuringDnd = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["podman-foo.service"];
      description = "systemd units to stop when a D&D session starts and start again afterwards.";
    };
    nightlyRestart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["podman-foo.service"];
      description = "systemd units to gracefully restart on the nightlyRestartAt schedule.";
    };

    # Schedule times (OnCalendar). Set once here or override from configuration.nix.
    dndPauseAt = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["Thu 20:00" "Fri 19:00"];
      description = "OnCalendar times at which pauseDuringDnd units are stopped.";
    };
    dndResumeAt = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["Fri 01:00" "Sat 01:00"];
      description = "OnCalendar times at which pauseDuringDnd units are started again.";
    };
    nightlyRestartAt = lib.mkOption {
      type = lib.types.str;
      default = "03:00";
      description = "OnCalendar time at which nightlyRestart units are restarted.";
    };
  };

  config = {
    systemd.services.dnd-pause = lib.mkIf hasPause {
      description = "Pause subscribed services during D&D sessions";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = runOn "stop" cfg.pauseDuringDnd;
      };
    };
    systemd.timers.dnd-pause = lib.mkIf hasPause {
      description = "Pause subscribed services at D&D session start";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.dndPauseAt;
        Persistent = false;
      };
    };

    systemd.services.dnd-resume = lib.mkIf hasPause {
      description = "Resume subscribed services after D&D sessions";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = runOn "start" cfg.pauseDuringDnd;
      };
    };
    systemd.timers.dnd-resume = lib.mkIf hasPause {
      description = "Resume subscribed services after D&D sessions";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.dndResumeAt;
        Persistent = true;
      };
    };

    systemd.services.nightly-restart = lib.mkIf hasRestart {
      description = "Nightly graceful restart of subscribed services";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = runOn "restart" cfg.nightlyRestart;
      };
    };
    systemd.timers.nightly-restart = lib.mkIf hasRestart {
      description = "Nightly restart of subscribed services";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.nightlyRestartAt;
        Persistent = false;
      };
    };
  };
}
