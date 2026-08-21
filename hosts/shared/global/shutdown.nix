{
  # Shutdown/reboot stalls for up to two minutes on "A stop job is running for
  # User Manager for UID 1000". Nothing is wrong with the user manager itself:
  # some session process ignores SIGTERM (browsers, electron apps, a blocked
  # sshfs/fprintd call, a stale i3 helper), and systemd waits out the full stop
  # timeout before resorting to SIGKILL. The upstream defaults are tuned for
  # servers, where killing a database mid-write is worse than waiting:
  #
  #   DefaultTimeoutStopSec        = 90s   (every unit, system and user manager)
  #   user@.service TimeoutStopSec = 120s  ("User Manager for UID ..." itself)
  #
  # On a desktop the trade-off runs the other way, so cap all three. Nothing
  # here fixes the process that hangs; it just stops the whole machine from
  # waiting on it.
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  systemd.user.extraConfig = "DefaultTimeoutStopSec=10s";

  # The wait on user@.service is *on top of* the per-unit waits above, and
  # DefaultTimeoutStopSec does not apply to units that set TimeoutStopSec
  # themselves — the upstream unit does — so it needs its own cap. This lands
  # as a drop-in over systemd's own user@.service.
  systemd.services."user@".serviceConfig.TimeoutStopSec = "15s";
}
