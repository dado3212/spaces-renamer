Disable SIP with `csrutil disable`. The M1 steps for this are different from Intel, you no longer use Command+R. See https://eshop.macsales.com/blog/74502-boot-an-m1-mac-into-recovery-mode/.

Confirm once you're rebooted that it's turned off with `csrutil status`.

Download the latest MacForge Beta. I used this link: https://github.com/MacEnhance/appcast/raw/master/Beta/MacForge/MacForge.1.2.0B1.zip. It came from the pinned message in the MacForge Beta channel of the MacEnhance discord: https://discord.gg/rzbmJ62a.

<p align="center">
  <img src="macForgeDeveloperPopup.png" height="100" ><br>
  <i>When opening, this will popup</i>
</p>

Click OK and then "Apple Icon > System Preferences > Security and Privacy" > "General" tab and click "Open Anyway". Follow some of the steps (screenshots attached).

Forget to disable Library Validation.

```
sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true
```
