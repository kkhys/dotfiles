{ config, ... }:

{
  system.stateVersion = 5;

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
  };

  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      AppleShowScrollBars = "Always";
      InitialKeyRepeat = 18;
      KeyRepeat = 1;
    };

    screencapture = {
      show-thumbnail = false;
    };
  };

  system.activationScripts.extraActivation.text = ''
    USERNAME="${config.hostSpec.username}"

    # nix-homebrew needs /opt/homebrew owned by its user. chown -R takes minutes
    # on a large install, so only run it when the root dir owner is wrong
    # (fresh machine, OS reinstall).
    if [[ ! -d /opt/homebrew ]]; then
      /bin/mkdir -p /opt/homebrew
    fi
    if [[ "$(/usr/bin/stat -f %Su /opt/homebrew)" != "$USERNAME" ]]; then
      echo "Fixing Homebrew directory permissions for $USERNAME..."
      /usr/sbin/chown -R "$USERNAME":admin /opt/homebrew 2>/dev/null || true
    fi

    if ! /usr/bin/xcrun -f clang >/dev/null 2>&1; then
      echo "Installing Xcode Command Line Tools..."
      touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      PROD=$(/usr/sbin/softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
      /usr/sbin/softwareupdate -i "$PROD" --verbose
      rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    fi

    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q oahd; then
      echo "Installing Rosetta 2..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    # gpg comes from the per-user Home Manager profile, which does not exist yet
    # on the very first activation, hence the -x guard.
    GPG="/etc/profiles/per-user/$USERNAME/bin/gpg"
    GPG_KEY="/Users/$USERNAME/.gnupg/agenix-key.asc"
    if [[ -x "$GPG" && ( -f "$GPG_KEY" || -L "$GPG_KEY" ) ]]; then
      echo "Importing GPG secret key..."
      sudo -u "$USERNAME" "$GPG" --import "$GPG_KEY" 2>/dev/null || true
    fi
  '';
}
