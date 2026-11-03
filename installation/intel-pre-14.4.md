# Installation: Intel Mac, macOS 14.3 or earlier

[← Back to README](../README.md)

> [!TIP]
> If this doesn't work for you, try the [macOS 14.4 to 15.5 instructions](macos-14.4-to-15.5.md) instead, which use a newer MacForge and also work on Intel Macs.

1. Download [MacForge](https://www.macenhance.com/macforge?macforge://github.com/w0lfschild/macplugins/raw/master/com.alexbeals.SpacesRenamer), the newest incarnation of mySIMBL.
   - If it's not compatible, you can download the [latest mySIMBL version](https://github.com/w0lfschild/mySIMBL/releases/latest).
2. Make sure that it's installed, including disabling SIP (use the command `csrutil disable` in Recovery mode by [following this tutorial](https://www.imore.com/how-turn-system-integrity-protection-macos)). There are additional commands for macOS Catalina, with details under the 'System' tab of MacForge. After it's installed you can partially re-enable SIP using `csrutil enable --without debug --without fs`. If you fully enable SIP, Spaces Renamer won't work.
3. Download [Spaces Renamer](https://github.com/dado3212/spaces-renamer/raw/master/build/spaces-renamer.zip).
4. Unzip the downloaded .zip file.
5. Open `spaces-renamer.bundle` with `MacForge.app`, or simply drag and drop it in to install it.
6. Run `killall -9 Dock` in Terminal to restart the Dock application.
7. Run the application 'SpacesRenamer'. Accept the option to move it to /Applications. It should be automatically added to your Login Items, but you can check to confirm by going to "System Preferences" > "Users & Groups" > "Login Items" and adding it manually if necessary.
8. Open the 'Spaces Renamer' icon in the top bar and click 'Update Names' (doesn't matter what's in there). Otherwise the top bar may not appear!

Having trouble? See [Debugging Common Issues](../README.md#debugging-common-issues).
