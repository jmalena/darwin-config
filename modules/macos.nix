{ pkgs, config, lib, ... }:

let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  # Finder favorites and app preferences live in the user's login session; run there.
  asuser = ''launchctl asuser "$(id -u -- ${user})" sudo --user=${user} --'';
  mysides = "${asuser} ${pkgs.mysides}/bin/mysides";
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

    # Terminal.app: Option composes special characters (Czech layout: Option+ř -> ~)
    # instead of sending Meta. There's no declarative option, and writing the whole
    # "Window Settings" dict would wipe other profiles, so patch only the default
    # profile. Go through `defaults`: a running Terminal rewrites the plist file from
    # memory on quit, undoing direct edits. A never-customized profile has no entry
    # to patch, and the absent key already means false.
    termProfile=$(${asuser} defaults read com.apple.Terminal 'Default Window Settings' 2>/dev/null || echo Basic)
    termProfileXml=$(${asuser} defaults export com.apple.Terminal - 2>/dev/null \
      | plutil -extract "Window Settings.$termProfile" xml1 -o - - 2>/dev/null \
      | plutil -replace useOptionAsMetaKey -bool false -o - - 2>/dev/null || true)
    [ -n "$termProfileXml" ] && ${asuser} defaults write com.apple.Terminal 'Window Settings' \
      -dict-add "$termProfile" "$termProfileXml" || true
  '';
}
