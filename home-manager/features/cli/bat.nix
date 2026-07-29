{pkgs, ...}: {
  # `cat` with syntax highlighting, line numbers and a git gutter. Pipes
  # through less automatically when the file doesn't fit the screen.
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      # Show the filename header but drop bat's default line numbers and
      # side border — keeps output copy-pasteable straight out of the terminal.
      style = "header,changes";
    };
    extraPackages = with pkgs.bat-extras; [
      batman # `batman <cmd>` — man pages through bat
      batdiff # `batdiff` — git diff of the working tree through bat
      batgrep # `batgrep <pat>` — ripgrep results with surrounding context
    ];
  };
}
