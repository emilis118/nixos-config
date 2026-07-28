{
  # Reaching a machine that lives somewhere else: a shell over ssh, and the
  # graphical session over RDP.
  services.openssh = {
    enable = true;
    settings = {
      # Password logins on purpose: this is for a shared machine whose users
      # won't all have deposited a key here first. Keys still work and are
      # still better; see `secrets.sshKeys` if you want one managed.
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    # only 22, and only because the openssh module opens it for us
    openFirewall = true;
  };

  # KRDP — Plasma's RDP server. The package comes with plasma6 (see
  # optional/kde.nix); it is *not* a system service, each user switches it on
  # in System Settings -> Remote Desktop and sets a password there, so all
  # that's left for us is the port. Connect with any RDP client (remmina,
  # Windows' mstsc, ...) on <host>:3389.
  networking.firewall.allowedTCPPorts = [3389];

  # So the machine can be found as <hostname>.local instead of by whatever
  # address the lab's DHCP handed it today.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}
