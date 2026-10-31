{ config, lib, ... }:

let
  # gh extensions kept latest on every rebuild, mirroring how mise tools are
  # refreshed. nixpkgs carries both, but trails upstream releases, and these
  # are pre-1.0 tools that change behaviour between minors, so install them
  # via the gh CLI rather than programs.gh.extensions.
  ghExtensions = [
    "github/gh-stack"
    "github/gh-actions-lock"
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
  #
  # gh re-signs downloaded arm64 binaries with /usr/bin/codesign, which the
  # activation PATH lacks. An install that fails after the download leaves the
  # binary without manifest.yml, and gh then takes the directory for a git
  # extension it can never upgrade, so such a leftover is removed first.
  home.activation.ghExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH:/usr/bin"
    extDir="''${XDG_DATA_HOME:-$HOME/.local/share}/gh/extensions"
    ${lib.concatMapStringsSep "\n" (ext: ''
      echo "Installing ${ext} extension..."
      dir="$extDir/${baseNameOf ext}"
      if [ -d "$dir" ] && [ ! -e "$dir/manifest.yml" ] && [ ! -e "$dir/.git" ]; then
        rm -r "$dir"
      fi
      gh extension install --force ${ext} \
        || echo "warning: ${ext} extension install skipped (offline or no access?)" >&2
    '') ghExtensions}
  '';
}
