{ lib, config, ... }:

{
  system.stateVersion = 5;

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
    interactiveShellInit = lib.mkForce "";
  };

  # see: https://nix-darwin.github.io/nix-darwin/manual/index.html

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

    # nix-homebrew expects /opt/homebrew to exist and be owned by its user.
    # Only chown when the root dir owner is wrong: -R over the whole prefix
    # takes minutes on a large install, and wholesale wrong ownership (fresh
    # machine, OS reinstall) is the only case this needs to repair.
    if [[ ! -d /opt/homebrew ]]; then
      /bin/mkdir -p /opt/homebrew
    fi
    if [[ "$(/usr/bin/stat -f %Su /opt/homebrew)" != "$USERNAME" ]]; then
      echo "Fixing Homebrew directory permissions for $USERNAME..."
      /usr/sbin/chown -R "$USERNAME":admin /opt/homebrew 2>/dev/null || true
    fi

    # Intel Homebrew (Rosetta)
    if [[ -d /usr/local/Homebrew && "$(/usr/bin/stat -f %Su /usr/local/Homebrew)" != "$USERNAME" ]]; then
      echo "Fixing Intel Homebrew directory permissions for $USERNAME..."
      /usr/sbin/chown -R "$USERNAME":admin /usr/local/Homebrew 2>/dev/null || true
      /usr/sbin/chown -R "$USERNAME":admin /usr/local/bin 2>/dev/null || true
    fi

    # Xcode Command Line Tools check and installation
    if ! /usr/bin/xcrun -f clang >/dev/null 2>&1; then
      echo "Installing Xcode Command Line Tools..."
      touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      PROD=$(/usr/sbin/softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
      /usr/sbin/softwareupdate -i "$PROD" --verbose
      rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    fi

    # Rosetta 2 installation (Apple Silicon)
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q oahd; then
      echo "Installing Rosetta 2..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    # Import the agenix-decrypted GPG key. gpg comes from the per-user Home
    # Manager profile, not Homebrew; the -x guard covers the very first
    # activation, when that profile does not exist yet.
    GPG="/etc/profiles/per-user/$USERNAME/bin/gpg"
    GPG_KEY="/Users/$USERNAME/.gnupg/agenix-key.asc"
    if [[ -x "$GPG" && ( -f "$GPG_KEY" || -L "$GPG_KEY" ) ]]; then
      echo "Importing GPG secret key..."
      sudo -u "$USERNAME" "$GPG" --import "$GPG_KEY" 2>/dev/null || true
    fi
  '';
}
