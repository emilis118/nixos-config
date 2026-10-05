# Local overrides applied on top of nixy's nvf modules
# (appended to the module list in the nixy-nvim overlay in flake.nix).
#
# Copilot's default suggestion keys use Alt (<M->), which clashes with
# i3's $mod = Mod1; move them to the Win/Super key (<D-> in nvim notation).
{lib, ...}: {
  # nixy still uses the deprecated `prettierd` formatter name; nvf renamed it.
  vim.languages.markdown.format.type = lib.mkForce ["prettier"];

  # nixy enables svelte, which makes nvf add its prettier-plugin-svelte to the
  # prettier preset. That package builds with pnpm_10, which nixpkgs marks
  # insecure (CVE-2026-55487 and friends), so evaluation fails. Nothing here is
  # written in Svelte — drop the plugin and keep astro's (built with pnpm_11).
  vim.formatter.conform-nvim.presets.prettier.plugins = lib.mkForce ["astro"];

  vim.assistant.copilot.mappings = {
    suggestion = {
      accept = "<D-l>";
      prev = "<D-[>";
      next = "<D-]>";
    };
    panel.open = "<D-CR>";
  };
}
