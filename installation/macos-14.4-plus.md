# Installation: macOS 14.4 or later (Apple Silicon or Intel)

[← Back to README](../README.md)

> [!NOTE]
> This relies on an unofficial build of MacForge (1.2.2 (4)), so there may be compatibility issues with other plugins.

1. Fully uninstall any current versions of MacForge. This means making sure that MacForgeHelper is quit, the application is deleted, and the Trash is emptied.
2. Run some commands to clean up some of the lingering folders. **❗️THIS WILL DELETE ANY INSTALLED PLUGINS❗️**
   ```
   sudo launchctl unload /Library/LaunchDaemons/com.macenhance.MacForge.Injector.plist
   sudo rm -rf "/Library/Application Support/MacEnhance"
   sudo rm /Library/LaunchDaemons/com.macenhance.MacForge.Injector.plist
   sudo rm /Library/PrivilegedHelperTools/com.macenhance.MacForge.Injector
   ```
3. Download this zip file: [spaces-renamer.zip](https://github.com/user-attachments/files/20972723/spaces-renamer.zip). It contains the SpacesRenamer app, `spaces-renamer.bundle`, and MacForge 1.2.2 (4).
4. Open SpacesRenamer. Accept the option to move it to /Applications. It should be automatically added to your Login Items, but you can check to confirm by going to "System Settings" > "General" > "Login Items" and adding it manually if necessary.
5. Open MacForge, which will copy itself to /Applications. Go through all the install instructions and permissions around `csrutil` by disabling SIP (use the command `csrutil disable` in Recovery mode by [following this tutorial](https://www.imore.com/how-turn-system-integrity-protection-macos)). After it's installed you can partially re-enable SIP using `csrutil enable --without debug --without fs --without nvram --without kext` (thanks to @serkanozkul [here](https://github.com/dado3212/spaces-renamer/issues/75#issuecomment-1493355618)). If you fully enable SIP, Spaces Renamer won't work.
6. Copy `spaces-renamer.bundle` to `/Library/Application Support/MacEnhance/Plugins` and run `killall -9 Dock`.
7. Open the 'Spaces Renamer' icon in the top bar and click 'Update Names' (doesn't matter what's in there). Otherwise the top bar may not appear!

Having trouble? See [Debugging Common Issues](../README.md#debugging-common-issues).
