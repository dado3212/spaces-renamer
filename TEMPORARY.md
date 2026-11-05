# Signing (temporary notes)

## Where things stand

- Test builds are ad-hoc signed (`CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=`), and the Makefile ad-hoc signs the plugin.
- 1.x releases were signed with "Apple Development: Alex Beals (CR8GYU3W9Z)", team K2WR3HLA57, and not notarized. Gatekeeper rejects them, so users had to allow the app once.
- The macOS 27 Mac has no signing certificates.

## Building on the macOS 15.6 laptop

Not as is. The app and the plugin target macOS 27, which needs the macOS 27 SDK from Xcode 27, and Xcode 27.1 requires macOS 26.6 or later. The Xcodes that run on 15.6 reject a 27.0 deployment target.

Lowering the targets to build there isn't a good idea either: the plugin's arm64e slice would come from an older toolchain, and the arm64e ABI is a preview that isn't promised to stay compatible. If WindowManager on 27 refuses the slice, it crashes at launch while the plugin loads.

## Signing and notarizing on the laptop

Signing and notarizing don't depend on the macOS version, so build on the macOS 27 Mac and sign on the laptop.

1. On the macOS 27 Mac, build and zip:
   ```
   DEVELOPER_DIR=/Applications/Xcode_27.1.0_27A9275_fb.app/Contents/Developer xcodebuild -project spaces-renamer.xcodeproj -scheme SpacesRenamer -configuration Release -derivedDataPath build/release CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= clean build
   ditto -c -k --keepParent build/release/Build/Products/Release/SpacesRenamer.app build/SpacesRenamer-unsigned.zip
   ```
2. On the laptop, unzip it, get the exact certificate name from `security find-identity -v -p codesigning`, and store notary credentials once with `xcrun notarytool store-credentials spaces-renamer` (an app-specific password works).
3. Sign the plugin first, since signing the app seals the plugin's signature, then the app with the hardened runtime, then notarize and staple:
   ```
   APP=SpacesRenamer.app
   ID="Developer ID Application: Alex Beals (K2WR3HLA57)"
   codesign --force --timestamp --sign "$ID" "$APP/Contents/Resources/spaces-renamer.dylib"
   codesign --force --timestamp --options runtime --entitlements SpacesRenamer.entitlements --sign "$ID" "$APP"
   codesign --verify --strict --verbose=2 "$APP"
   ditto -c -k --keepParent "$APP" notarize.zip
   xcrun notarytool submit notarize.zip --keychain-profile spaces-renamer --wait
   xcrun stapler staple "$APP"
   ditto -c -k --keepParent "$APP" spaces-renamer-2.0.0.zip
   ```

The hardened runtime (`--options runtime`) probably needs `com.apple.security.automation.apple-events` in `SpacesRenamer/SpacesRenamer.entitlements` and an `NSAppleEventsUsageDescription` in `Info.plist`: the login-item scripts send Apple Events to System Events through `osascript`.

Alternatively, export the Developer ID certificate from the laptop and import it on the macOS 27 Mac, and do everything there.

## To check before publishing a notarized build

- Whether the notary service accepts the plugin's arm64e slice. WindowManager is arm64e, so dropping the slice isn't an option.
- Whether the plugin still loads into WindowManager when signed with Developer ID instead of ad-hoc. It should with SIP disabled: install the notarized app on the macOS 27 Mac and check that `HostPID` in `defaults read com.apple.WindowManager SpacesRenamerWindowManagerPlugin` matches `pgrep -x WindowManager`.
- Whether the app still adds itself to Login Items under the hardened runtime.

## Without notarization

Publish the ad-hoc build, or one signed with Apple Development like 1.x. Users allow it once: move it to /Applications, open it, then "Open Anyway" in System Settings > Privacy & Security, or run `xattr -dr com.apple.quarantine /Applications/SpacesRenamer.app`.

## Every release

Bump `MARKETING_VERSION` whenever the plugin changes. The staged plugin is named by version, so with the same version users keep the old plugin until WindowManager next restarts.
