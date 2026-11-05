# Installation: Apple Silicon, macOS 27

[← Back to README](../README.md)

> [!NOTE]
> Spaces Renamer 2.0 doesn't use MacForge. The app loads its plugin into WindowManager, which draws the Spaces bar on macOS 27. If you used MacForge with an older version, uninstall it first (see [Uninstall](../README.md#macos-26-and-earlier)).

1. Disable System Integrity Protection: run `csrutil disable` in Recovery mode ([tutorial](https://www.imore.com/how-turn-system-integrity-protection-macos)). Partially re-enabling SIP isn't supported.
2. Enable the arm64e preview ABI, then restart:
   ```
   sudo nvram boot-args="-arm64e_preview_abi"
   ```
   This replaces any boot arguments you already have. Check with `nvram boot-args` first and include them if so.
3. Download this zip file: [spaces-renamer-2.0.0.zip](https://github.com/dado3212/spaces-renamer/releases/download/v2.0.0/spaces-renamer-2.0.0.zip). Move SpacesRenamer to /Applications and open it. When it asks to control System Events, click Allow so it can add itself to your Login Items. You can check by going to "System Settings" > "General" > "Login Items" and adding it manually if necessary.
4. When the app starts it loads its plugin, which briefly restarts Mission Control and Stage Manager. Open the 'Spaces Renamer' icon in the top bar, name your spaces, and click 'Update Names'.

The app needs to keep running: if WindowManager restarts, the app loads the plugin into it again.

Having trouble? See [Debugging Common Issues](../README.md#debugging-common-issues).
