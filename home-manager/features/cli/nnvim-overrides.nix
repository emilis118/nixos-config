# Local overrides applied on top of nixy's nvf modules
# (appended to the module list in the nixy-nvim overlay in flake.nix).
#
# Copilot's default suggestion keys use Alt (<M->), which clashes with
# i3's $mod = Mod1; move them to the Win/Super key (<D-> in nvim notation).
{lib, ...}: {
  # nixy still uses the deprecated `prettierd` formatter name; nvf renamed it.
  vim.languages.markdown.format.type = lib.mkForce ["prettier"];

  vim.assistant.copilot.mappings = {
    suggestion = {
      accept = "<D-l>";
      prev = "<D-[>";
      next = "<D-]>";
    };
    panel.open = "<D-CR>";
  };
}
