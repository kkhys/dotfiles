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

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    ".GlobalPreferences" = {
      "com.apple.mouse.scaling" = -1.0;
    };
    
    dock = {
      autohide = true;
      persistent-apps = [
        { app = "/Applications/Google Chrome.app"; }
        { app = "/Applications/Zed.app"; }
        { app = "/Applications/Ghostty.app"; }
        { app = "/Applications/Obsidian.app"; }
      ];
      show-recents = false;
      tilesize = 40;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCev";
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
      ShowExternalHardDrivesOnDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = false;
      AppleInterfaceStyle = "Dark";
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleShowScrollBars = "Always";
      AppleTemperatureUnit = "Celsius";
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
    };
    
    screencapture = {
      location = "~/Desktop/screenshots";
      show-thumbnail = false;
    };
    
    menuExtraClock = {
      FlashDateSeparators = false;
      IsAnalog = false;
      Show24Hour = true;
      ShowAMPM = false;
      ShowDate = 0;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowSeconds = true;
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

    echo "=== extraActivation: Done ==="
  '';
}
