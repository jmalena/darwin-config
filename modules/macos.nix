{ pkgs, config, lib, ... }:

let
  blackWallpaper = pkgs.runCommand "black-wallpaper" { } ''
    mkdir -p $out
    ${pkgs.imagemagick}/bin/magick -size 5120x2880 xc:black png:$out/black.png
  '';
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
        "/Applications/Safari.app"
        "/System/Applications/Utilities/Terminal.app"
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

    asuser defaults -currentHost write com.apple.Spotlight orderedItems -array \
      '{ enabled = 1; name = "APPLICATIONS"; }' \
      '{ enabled = 1; name = "SYSTEM_PREFS"; }' \
      '{ enabled = 0; name = "MENU_EXPRESSION"; }' \
      '{ enabled = 0; name = "CONTACT"; }' \
      '{ enabled = 0; name = "MENU_CONVERSION"; }' \
      '{ enabled = 0; name = "MENU_DEFINITION"; }' \
      '{ enabled = 0; name = "DOCUMENTS"; }' \
      '{ enabled = 0; name = "EVENT_TODO"; }' \
      '{ enabled = 0; name = "DIRECTORIES"; }' \
      '{ enabled = 0; name = "FONTS"; }' \
      '{ enabled = 0; name = "IMAGES"; }' \
      '{ enabled = 0; name = "MESSAGES"; }' \
      '{ enabled = 0; name = "MOVIES"; }' \
      '{ enabled = 0; name = "MUSIC"; }' \
      '{ enabled = 0; name = "MENU_OTHER"; }' \
      '{ enabled = 0; name = "PDF"; }' \
      '{ enabled = 0; name = "PRESENTATIONS"; }' \
      '{ enabled = 0; name = "MENU_SPOTLIGHT_SUGGESTIONS"; }' \
      '{ enabled = 0; name = "SPREADSHEETS"; }' \
      '{ enabled = 0; name = "TIPS"; }' \
      '{ enabled = 0; name = "BOOKMARKS"; }' || true
    asuser killall Spotlight || true
  '';
}
