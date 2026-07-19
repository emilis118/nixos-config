{...}: {
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        # mail checks + dunst notifications
        "mail.biff.show_alert" = true;
        "mail.chrome.window.title.prefix" = "";
      };
    };
  };

  # CERN Outlook — the "outlook.office365.com" flavor sets the IMAP/SMTP
  # servers and OAuth2 auth; the one-time login happens in Thunderbird's
  # embedded browser on first launch.
  accounts.email.accounts.cern = {
    primary = true;
    address = "emilis.ulejevas@cern.ch";
    userName = "emilis.ulejevas@cern.ch";
    realName = "Emilis Ulejevas";
    flavor = "outlook.office365.com";
    thunderbird.enable = true;
  };
}
