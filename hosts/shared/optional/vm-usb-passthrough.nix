{...}: {
  # USB devices handed to VMs with quickemu's `usb_devices=(...)`. QEMU opens
  # /dev/bus/usb/BBB/DDD directly, and those nodes are root:root 0664, so
  # quickemu refuses to start ("USB permission changes are required") unless
  # they are chowned by hand — which is lost on every replug, since the device
  # number changes. `uaccess` gives the logged-in user an ACL on the node
  # instead, matched by vendor:product so it survives replugging.
  services.udev.extraRules = ''
    # External DVD drive (LG DVDRAM GT30N, shows up as sr0)
    SUBSYSTEM=="usb", ATTR{idVendor}=="13fd", ATTR{idProduct}=="0840", TAG+="uaccess"
    # Lexia car diagnostics: the J2534 interface ...
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5740", TAG+="uaccess"
    # ... and the USBKey dongle that came with it
    SUBSYSTEM=="usb", ATTR{idVendor}=="3689", ATTR{idProduct}=="8762", TAG+="uaccess"
  '';
}
