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
      location = "~/Desktop/screenshots";
      show-thumbnail = false;
    };
  };

  # ============================================================================
  # Activation Scripts
  # ============================================================================
  system.activationScripts.extraActivation.text = ''
    echo "=== extraActivation: Starting ==="

    # Homebrew directory creation and permission fix
    BREW_USER="${config.hostSpec.username}"
    echo "BREW_USER=$BREW_USER"

    if [[ -n "$BREW_USER" ]]; then
      # ARM Homebrew
      if [[ ! -d "/opt/homebrew" ]]; then
        echo "Creating Homebrew directory for $BREW_USER..."
        /bin/mkdir -p /opt/homebrew
      fi
      echo "Fixing Homebrew directory permissions for $BREW_USER..."
      /usr/sbin/chown -R "$BREW_USER":admin /opt/homebrew 2>/dev/null || true

      # Intel Homebrew (Rosetta)
      if [[ -d "/usr/local/Homebrew" ]]; then
        echo "Fixing Intel Homebrew directory permissions for $BREW_USER..."
        /usr/sbin/chown -R "$BREW_USER":admin /usr/local/Homebrew 2>/dev/null || true
        /usr/sbin/chown -R "$BREW_USER":admin /usr/local/bin 2>/dev/null || true
      fi
    else
      echo "WARNING: BREW_USER is not set (config.hostSpec.username is empty)"
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

    # Import GPG secret key (managed by agenix)
    GPG_KEY="/Users/${config.hostSpec.username}/.gnupg/agenix-key.asc"
    if [[ -f "$GPG_KEY" || -L "$GPG_KEY" ]]; then
      echo "Importing GPG secret key..."
      sudo -u "${config.hostSpec.username}" /usr/local/bin/gpg --import "$GPG_KEY" 2>/dev/null || \
      sudo -u "${config.hostSpec.username}" /opt/homebrew/bin/gpg --import "$GPG_KEY" 2>/dev/null || true
    fi

    echo "=== extraActivation: Done ==="
  '';
}
