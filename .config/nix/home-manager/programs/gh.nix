{ config, lib, ... }:

let
  # Via the gh CLI rather than programs.gh.extensions: nixpkgs trails upstream,
  # and these pre-1.0 tools change behaviour between minors.
  ghExtensions = [
    "github/gh-stack"
    "github/gh-actions-lock"
  ];
in
{
  programs.gh = {
    enable = true;

    settings = {
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

  # --force because a plain install exits 0 when already installed, so
  # `install || upgrade` never upgrades. /usr/bin is on PATH for codesign, which
  # gh uses to re-sign arm64 binaries. An install that failed after the download
  # leaves a directory without manifest.yml, which gh then treats as a git
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
