{ pkgs, config, lib, ... }:

let
  blackWallpaper = pkgs.runCommand "black-wallpaper" { } ''
    mkdir -p $out
    ${pkgs.imagemagick}/bin/magick -size 5120x2880 xc:black png:$out/black.png
  '';

  # Spotlight results are limited to these menu categories; the rest are hidden.
  spotlightShown = [ "APPLICATIONS" "SYSTEM_PREFS" ];
  spotlightHidden = [
    "MENU_EXPRESSION" "CONTACT" "MENU_CONVERSION" "MENU_DEFINITION"
    "DOCUMENTS" "EVENT_TODO" "DIRECTORIES" "FONTS" "IMAGES" "MESSAGES"
    "MOVIES" "MUSIC" "MENU_OTHER" "PDF" "PRESENTATIONS"
    "MENU_SPOTLIGHT_SUGGESTIONS" "SPREADSHEETS" "TIPS" "BOOKMARKS"
  ];
  spotlightItem = enabled: name:
    "'{ enabled = ${if enabled then "1" else "0"}; name = \"${name}\"; }'";
  spotlightItems = lib.concatStringsSep " " (
    map (spotlightItem true) spotlightShown ++ map (spotlightItem false) spotlightHidden
  );
in
{
  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = true;
    blockAllIncoming = false;
    enableStealthMode = true;
  };

  system.defaults = {
    dock = {
      autohide = false;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;

      persistent-apps = [
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "/Applications/Google Chrome.app"
        "/System/Applications/Utilities/Terminal.app"
        "/Applications/Emacs.app"
        "/Applications/Spotify.app"
        "/System/Applications/System Settings.app"
      ];

      persistent-others = [
        { folder = { path = "/Users/aleph/Downloads"; displayas = "folder"; showas = "grid"; }; }
        { folder = { path = "/Applications"; displayas = "folder"; showas = "grid"; }; }
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "icnv";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      FXEnableExtensionChangeWarning = false;
      FXDefaultSearchScope = "SCcf";
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      AppleShowAllExtensions = true;
      AppleKeyboardUIMode = 3;
      AppleICUForce24HourTime = true;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    WindowManager = {
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
    };

    screencapture = {
      location = "~/Screenshots";
      type = "png";
    };

    menuExtraClock.Show24Hour = true;

    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      "com.apple.finder" = {
        DesktopViewSettings.IconViewSettings.arrangeBy = "grid";
        StandardViewSettings.IconViewSettings.arrangeBy = "grid";
        FK_StandardViewSettings.IconViewSettings.arrangeBy = "grid";
      };
    };
  };

  # Black wallpaper and Spotlight scoping have no declarative option; apply them
  # in the primary user's GUI session after activation. Both are best-effort.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    uid=$(id -u ${config.system.primaryUser})
    asuser() { launchctl asuser "$uid" sudo -u ${config.system.primaryUser} "$@"; }

    asuser /usr/bin/osascript -e \
      'tell application "System Events" to tell every desktop to set picture to "${blackWallpaper}/black.png"' || true

    asuser defaults -currentHost write com.apple.Spotlight orderedItems -array ${spotlightItems} || true
    asuser killall Spotlight || true

    # Finder sidebar: keep exactly one "Projects" favorite; drop the old "Projekty".
    asuser ${pkgs.mysides}/bin/mysides remove Projekty >/dev/null 2>&1 || true
    if ! asuser ${pkgs.mysides}/bin/mysides list 2>/dev/null | grep -q 'file:///Users/${config.system.primaryUser}/Projects'; then
      asuser ${pkgs.mysides}/bin/mysides add Projects "file:///Users/${config.system.primaryUser}/Projects/" || true
    fi

    # Terminal.app: keep Option as a normal modifier on the default profile so it
    # composes special characters (e.g. Czech accents) instead of sending Meta. No
    # declarative option exists — writing the whole "Window Settings" dict via
    # CustomUserPreferences would wipe other profiles.
    termProfile=$(asuser defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
    [ -n "$termProfile" ] || termProfile="Basic"
    termPlist="/Users/${config.system.primaryUser}/Library/Preferences/com.apple.Terminal.plist"
    asuser /usr/libexec/PlistBuddy -c "Add :'Window Settings':'$termProfile':useOptionAsMetaKey bool false" "$termPlist" 2>/dev/null \
      || asuser /usr/libexec/PlistBuddy -c "Set :'Window Settings':'$termProfile':useOptionAsMetaKey false" "$termPlist" || true
  '';
}
