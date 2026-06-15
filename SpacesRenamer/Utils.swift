//
//  Utils.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.

import Foundation
import ServiceManagement

class Utils {
  static let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
  static let customNamesPlist = Utils.libraryPath.appending("/Containers/\(Bundle.main.bundleIdentifier!)/com.alexbeals.spacesrenamer.plist")
  static let listOfSpacesPlist = Utils.libraryPath.appending("/Containers/\(Bundle.main.bundleIdentifier!)/com.alexbeals.spacesrenamer.currentspaces.plist")
  static let spacesPath = Utils.libraryPath.appending("/Preferences/com.apple.spaces.plist")

  static let escapeKey: UInt16 = 0x35

  private static let hasRegisteredLoginItemKey = "hasRegisteredLoginItem"

  // Register the app as a login item once. If the user later disables it
  // manually we leave it alone — the one-shot key prevents re-enabling it.
  static func registerLoginItemIfNeeded() {
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: hasRegisteredLoginItemKey) {
      return
    }

    let service = SMAppService.mainApp
    if service.status != .enabled {
      do {
        try service.register()
      } catch {
        NSLog("Failed to register login item: \(error)")
        return
      }
    }
    defaults.set(true, forKey: hasRegisteredLoginItemKey)
  }
}
