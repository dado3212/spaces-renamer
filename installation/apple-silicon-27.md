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
3. Download SpacesRenamer 2.0 from the [releases page](https://github.com/dado3212/spaces-renamer/releases), move it to /Applications, and open it. It adds itself to your Login Items; check "System Settings" > "General" > "Login Items" and add it manually if necessary.
4. When the app starts it loads its plugin, which briefly restarts Mission Control and Stage Manager. Open the 'Spaces Renamer' icon in the top bar, name your spaces, and click 'Update Names'.

The app needs to keep running: if WindowManager restarts, the app loads the plugin into it again.

Having trouble? See [Debugging Common Issues](../README.md#debugging-common-issues).
