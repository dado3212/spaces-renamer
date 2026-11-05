## Rebuild

1. Quit Spaces Renamer, then run the SpacesRenamer scheme in Xcode 27 (⌘R). Its "Build Plugin" phase builds the plugin and embeds it in the app.
2. If you didn't change the version, restart WindowManager so the app loads the new plugin: `launchctl kickstart -k gui/$(id -u)/com.apple.WindowManager.agent`
3. Check that it loaded: `HostPID` in `defaults read com.apple.WindowManager SpacesRenamerWindowManagerPlugin` should match `pgrep -x WindowManager`.

Don't delete anything in `~/Library/Application Support/com.apple.windowmanager/SpacesRenamer` until you log out: apps launched while the plugin was loading need those files.

## Checklist

- Reduce transparency
- Increased contrast
- Emoji in desktop names
- Just whitespace in desktop names
- No name in desktop name
- Make sure it works with some that are unnamed
