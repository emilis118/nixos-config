{pkgs, ...}: {
  home.packages = [pkgs.remmina];

  # saved remmina profiles get their own tab in rofi (see rofi.nix)
  rofiModes.remote = true;

  # Migrated from the profiles saved in remmina's own GUI store
  # (~/.local/share/remmina/*.remmina on work_pc): server and username
  # aren't secret, so they're declared here; the password for each username
  # goes in secrets/passwords.yaml under "rdp-<username>" (`pw edit`) - e.g.
  # "rdp-cryolab" covers every connection below that logs in as cryolab.
  # Once a username's password is in the store, the .remmina files using it
  # can be deleted - rofi-remmina hides them in favor of these anyway.
  remmina.connections = [
    {
      name = "adrian_win_lab";
      server = "pcte276946.cern.ch";
      username = "cryolab";
    }
    {
      name = "DAQ_laptop";
      server = "lapte234119.cern.ch";
      username = "cryolab";
    }
    {
      name = "filips_lab";
      server = "lapte276972.cern.ch";
      username = "hfmcryolab";
    }
    {
      name = "filips_workstation";
      server = "pccag4556.cern.ch";
      username = "fsoukup";
    }
    {
      name = "lab_win_personal";
      server = "pcte276977.cern.ch";
      username = "eulejeva";
    }
    {
      name = "my_lab";
      server = "PXICRYOLAB05";
      username = "cryolab";
    }
    {
      name = "my_win_lab";
      server = "pcte276977.cern.ch";
      username = "cryolab";
    }
    {
      name = "windows";
      server = "pcte250723";
      username = "eulejeva";
    }
  ];
}
