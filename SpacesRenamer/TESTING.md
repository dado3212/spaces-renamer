## Rebuild

1. Quit Spaces Renamer, then run the SpacesRenamer scheme in Xcode 27 (⌘R). Its "Build Plugin" phase builds the plugin and embeds it in the app.
2. If you didn't change the version, load the new plugin the way the app does, so WindowManager restarts once:
   ```
   L=$(ls -t ~/Library/Application\ Support/com.apple.windowmanager/SpacesRenamer/spaces-renamer-*.dylib | head -1); [ -f "$L" ] && launchctl setenv DYLD_INSERT_LIBRARIES "$L"; launchctl kickstart -k gui/$(id -u)/com.apple.WindowManager.agent; sleep 1; launchctl unsetenv DYLD_INSERT_LIBRARIES
   ```
   The newest staged file is the one the app just wrote. Keep it one line so the variable is always cleared. A plain `kickstart` also works, but WindowManager comes back without the plugin and the app restarts it again a couple of seconds later, closing Mission Control if it's open.

Don't delete anything in `~/Library/Application Support/com.apple.windowmanager/SpacesRenamer` until you log out: apps launched while the plugin was loading need those files.

## Checklist

- Reduce transparency
- Increased contrast
- Emoji in desktop names
- Just whitespace in desktop names
- No name in desktop name
- Make sure it works with some that are unnamed
- Fullscreen apps
- Multiple monitors
- Reorganize named screens
