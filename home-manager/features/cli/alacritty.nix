{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 13.0;
        normal = {
          family = "JetBrains Mono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrains Mono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrains Mono Nerd Font";
          style = "Italic";
        };
      };
    };
  };
}
