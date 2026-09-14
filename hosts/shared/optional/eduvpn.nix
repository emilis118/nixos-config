{pkgs, ...}: {
  # eduVPN, for CERN's server: https://eduvpn.cern.ch/ — it is listed in the
  # client's "Institute Access" list, so searching "CERN" there is enough, no
  # URL to type. Subscribe to the eduVPN service in the CERN resources portal
  # first (https://resources.web.cern.ch), otherwise the CERN SSO login
  # succeeds and then hands the client no profile.
  #
  # This is the mirror image of the NordLynx tunnel in shared/global/nordvpn.nix:
  # that one is a full tunnel *out*, and cern-lab.nix's /mnt/lab sshfs mount
  # stops resolving while it is up. eduVPN is a full tunnel *in*, so /mnt/lab
  # and the DFS WebDAV share work from anywhere — which is the point of having
  # it. The two are still mutually exclusive; only one full tunnel at a time.
  #
  # Nothing here is automatic and there is no unit to manage: `eduvpn-gui`
  # (also a launcher entry, so mod+d finds it) or `eduvpn-cli` drives
  # NetworkManager directly, so switching profiles never needs a rebuild.
  environment.systemPackages = [pkgs.eduvpn-client];

  # The client materialises the tunnel as a NetworkManager connection.
  # WireGuard support is built into NM, but an OpenVPN profile is imported
  # through NM's VPN plugin interface — without this the client dies with
  # "Expected one openvpn VPN plugins, got: 0". eduVPN picks the protocol per
  # profile, so both paths have to work.
  networking.networkmanager.plugins = [pkgs.networkmanager-openvpn];

  # A full tunnel means replies arrive on the wg/tun interface while the route
  # back to the peer still points at wlan, and strict reverse-path filtering
  # (the NixOS default) drops them — the tunnel comes up and then carries no
  # traffic. "loose" only asks that a route back exists on *some* interface.
  networking.firewall.checkReversePath = "loose";

  # Note on where the OAuth token lands: the client prefers a Secret Service
  # (libsecret) and falls back to its own InsecureFileKeyring, which is a
  # plaintext JSON file at ~/.config/eduvpn/keys. Nothing in this session
  # provides a Secret Service, so the fallback is what you get — a CERN
  # credential good for months, in the clear, on a disk with no LUKS. Closing
  # that means
  #   services.gnome.gnome-keyring.enable = true;
  #   security.pam.services.sddm.enableGnomeKeyring = true;
  # and living with an unlock prompt on every boot: optional/i3.nix autologins
  # emilis, so PAM never sees a password to unlock the keyring with.
}
