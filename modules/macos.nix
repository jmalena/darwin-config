{ pkgs, config, lib, ... }:

let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  # Finder favorites live in the user's login session, so run mysides there.
  mysides = ''launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- ${pkgs.mysides}/bin/mysides'';
in
{
  programs.zsh.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  system.defaults = {
    dock = {
      autohide = false;
      mru-spaces = false;
      show-recents = false;
      tilesize = 65;

      persistent-apps = [
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "/Applications/Google Chrome.app"
        "/System/Applications/Utilities/Terminal.app"
        "/Applications/Emacs.app"
        "/Applications/Claude.app"
        "/Applications/Figma.app"
        "/Applications/Spotify.app"
        "/System/Applications/System Settings.app"
      ];

      persistent-others = [
        { folder = { path = "${home}/Downloads"; arrangement = "date-modified"; displayas = "folder"; showas = "grid"; }; }
        { folder = { path = "/Applications"; displayas = "folder"; showas = "grid"; }; }
      ];
    };

    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
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
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    if ! ${mysides} list 2>/dev/null | grep -qF 'file://${home}/Projects'; then
      ${mysides} add Projects 'file://${home}/Projects/' || true
    fi
  '';
}
