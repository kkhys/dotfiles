{ config, lib, ... }:

let
  # gh extensions kept latest on every rebuild, mirroring how mise tools are
  # refreshed. nixpkgs carries gh-stack, but trails upstream releases, and it
  # is a pre-1.0 tool that changes behaviour between minors, so install it via
  # the gh CLI rather than programs.gh.extensions.
  ghExtensions = [
    "github/gh-stack"
  ];
in
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

  # `gh extension install` exits 0 when the extension is already installed, so
  # an `install || upgrade` chain never upgrades. --force upgrades an installed
  # extension in place and does nothing when it is already up to date.
  home.activation.ghExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    ${lib.concatMapStringsSep "\n" (ext: ''
      echo "Installing ${ext} extension..."
      gh extension install --force ${ext} \
        || echo "warning: ${ext} extension install skipped (offline or no access?)" >&2
    '') ghExtensions}
  '';
}
