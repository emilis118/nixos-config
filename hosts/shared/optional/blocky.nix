{
  pkgs,
  lib,
  ...
}: let
  # Domains blocked only while do-not-disturb is on (see
  # home-manager/features/dnd.nix). Kept separate from `productivity`, which
  # is blocked around the clock.
  socialDomains = [
    "www.instagram.com"
    "instagram.com"
    "www.tiktok.com"
    "tiktok.com"
    "www.reddit.com"
    "reddit.com"
    "old.reddit.com"
    "www.x.com"
    "x.com"
    "twitter.com"
    "www.twitter.com"
    "www.snapchat.com"
    "web.snapchat.com"
    "www.linkedin.com"
    "linkedin.com"
    "news.ycombinator.com"
    "www.twitch.tv"
    "twitch.tv"
    "9gag.com"
    "www.9gag.com"
  ];
in {
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53; # Port for incoming DNS Queries.
      # REST API, loopback only. `dnd` drives the social group through this.
      ports.http = "127.0.0.1:4000";
      upstreams.groups.default = [
        "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
      ];
      # For initially solving DoH/DoT Requests when no system Resolver is available.
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = ["1.1.1.1" "1.0.0.1"];
      };
      #Enable Blocking of certian domains.
      blocking = {
        # renamed from blackLists in blocky 0.24; the old name still works
        # but `blocky validate` fails the config over it
        denylists = {
          #Adblocking
          ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
          #Another filter for blocking adult sites
          adult = ["https://blocklistproject.github.io/Lists/porn.txt"];
          #You can add additional categories
          productivity = ["|\nwww.youtube.com\nwww.facebook.com\nwww.sarg.lt"];
          # only in effect during do-not-disturb; switched off again below
          social = ["|\n${lib.concatStringsSep "\n" socialDomains}"];
        };
        #Configure what block categories are used
        clientGroupsBlock = {
          default = ["ads" "adult" "productivity" "social"];
        };
      };
    };
  };

  # blocky has no "start this group switched off" setting, so the social group
  # is listed above (making it available) and turned off right after blocky
  # comes up. `dnd on` turns it back on, `dnd off` runs the same disable call.
  systemd.services.blocky-social-off = {
    description = "Leave blocky's social group disabled until do-not-disturb turns it on";
    after = ["blocky.service"];
    wants = ["blocky.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # blocky's own client, so the API path/port stay blocky's problem.
      # It needs a moment after the unit reports started.
      for _ in $(seq 30); do
        ${pkgs.blocky}/bin/blocky blocking disable --groups social && exit 0
        sleep 1
      done
      echo "blocky API never answered; social group left blocking" >&2
    '';
  };

  networking.nameservers = ["127.0.0.1"];
}
