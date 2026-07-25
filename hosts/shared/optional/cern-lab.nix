{pkgs, ...}: {
  # Shared by the two CERN machines (work_pc, work_laptop): the cryolab
  # sshfs share plus the DFS WebDAV client.
  programs.ssh.knownHosts = {
    "pxicryolab05.cern.ch" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNZ9R7xssGHbricQ5fUc3S0IkebV55tSrP+b8ZwOTWz";
    };
  };

  systemd.mounts = [
    {
      what = "cryolab@pxicryolab05.cern.ch:/home/cryolab";
      where = "/mnt/lab";
      type = "fuse.sshfs";
      options = "nodev,noatime,allow_other,reconnect,ServerAliveInterval=15,ConnectTimeout=5,IdentityFile=/home/emilis/.ssh/lab_pc";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      # No wantedBy here: only the automount unit is started at boot, so the
      # sshfs connection is attempted on first access instead of blocking boot.
      mountConfig.TimeoutSec = 15;
    }
  ];

  systemd.automounts = [
    {
      where = "/mnt/lab";
      wantedBy = ["multi-user.target"];
    }
  ];

  programs.fuse.userAllowOther = true;
  environment.systemPackages = [pkgs.sshfs];

  # CERN DFS is mounted on demand through gvfs (the davs:// bookmark in
  # home-manager/features/cern-dfs.nix), not as a fileSystems entry — that
  # would need credentials at boot.
  services.davfs2.enable = true;
}
