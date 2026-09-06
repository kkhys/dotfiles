{ config, lib, ... }:

{
  programs.gh = {
    enable = true;

    settings = {
      # Every other tool here has telemetry off; gh alone defaults to on.
      telemetry = "disabled";

      aliases = {
        co = "pr checkout";
        il = "issue list";
        iv = "issue view --web";
        op = "repo view --web";
        pc = "pr create --web";
        pl = "pr list";
        pv = "pr view --web";
        rl = "run list";
        rw = "run watch";
      };
    };

    gitCredentialHelper = {
      enable = false;
    };
  };

  # Keep the gh-stack (GitHub Stacked PRs) extension up to date on every
  # rebuild, mirroring how mise tools are refreshed. gh-stack
  # is not in nixpkgs (private preview), so install it via the gh CLI rather
  # than programs.gh.extensions.
  home.activation.ghStackExtension = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    echo "Installing gh-stack extension..."
    gh extension install github/gh-stack 2>/dev/null \
      || gh extension upgrade gh-stack 2>/dev/null \
      || echo "warning: gh-stack extension install skipped (offline or no access?)" >&2
  '';
}
