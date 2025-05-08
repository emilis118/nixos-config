{pkgs, ...}: {
  home.packages = with pkgs; [
    ani-cli
    ani-skip
    mov-cli
  ];
}
