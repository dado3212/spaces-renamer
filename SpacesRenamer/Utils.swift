//
//  Utils.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.

import Foundation

class Utils {
  static let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
  static let spacesPath = Utils.libraryPath.appending("/Preferences/com.apple.spaces.plist")
  // Where Spaces Renamer 1.x saved names
  static let legacyNamesPlist = Utils.libraryPath.appending("/Containers/\(Bundle.main.bundleIdentifier!)/com.alexbeals.spacesrenamer.plist")
  
  static let escapeKey: UInt16 = 0x35

  // The names and the layout live in WindowManager's domain, which the plugin can read from
  // WindowManager's sandbox. Setting them notifies the plugin.
  static let store = UserDefaults(suiteName: "com.apple.WindowManager")!

  // Space UUID to name
  static var names: [String: String] {
    get {
      return store.dictionary(forKey: "SpacesRenamerNames") as? [String: String] ?? [:]
    }
    set {
      store.set(newValue, forKey: "SpacesRenamerNames")
      notifyPlugin()
    }
  }

  // The displays and their spaces, from CGSCopyManagedDisplaySpaces
  static var monitors: [NSDictionary] {
    get {
      return store.array(forKey: "SpacesRenamerMonitors") as? [NSDictionary] ?? []
    }
    set {
      store.set(newValue, forKey: "SpacesRenamerMonitors")
      // True when "Displays have separate Spaces" is off, so desktops are numbered across displays.
      store.set(UserDefaults(suiteName: "com.apple.spaces")?.bool(forKey: "spans-displays") ?? false, forKey: "SpacesRenamerSpansDisplays")
      notifyPlugin()
    }
  }

  private static func notifyPlugin() {
    store.synchronize()
    notify_post("com.alexbeals.spacesrenamer.names-changed")
  }

  static func importLegacyNames() {
    guard store.object(forKey: "SpacesRenamerNames") == nil,
      let legacy = NSDictionary(contentsOfFile: legacyNamesPlist)?["spaces_renaming"] as? [String: String] else { return }
    names = legacy
  }
  
  static func addPathToLoginItems(_ path: String) {
    let scriptPath = Bundle.main.path(forResource: "AddToLogin", ofType: "scpt")
    
    if (scriptPath != nil) {
      let process = Process()
      process.launchPath = "/usr/bin/osascript"
      process.arguments = [scriptPath!, path]
      process.launch()
      process.waitUntilExit()
    }
  }
  
  static func addPathToLoginItemsIfNecessary(path: String, name: String) {
    let scriptPath = Bundle.main.path(forResource: "GetLoginItems", ofType: "scpt")
    
    if (scriptPath != nil) {
      let process = Process()
      process.launchPath = "/usr/bin/osascript"
      process.arguments = [scriptPath!, path]
      
      let outpipe = Pipe()
      process.standardOutput = outpipe
      
      process.launch()
      
      var output : [String] = []
      
      let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
      if var string = String(data: outdata, encoding: .utf8) {
        string = string.trimmingCharacters(in: .newlines)
        output = string.components(separatedBy: "\n")
      }
      
      process.waitUntilExit()
      
      let loginItems = output[0].components(separatedBy: ", ")
      if !loginItems.contains(name) {
        addPathToLoginItems(path)
      }
    }
  }
  
  static func removeAppFromLoginItems() {
    let scriptPath = Bundle.main.path(forResource: "RemoveFromLogin", ofType: "scpt")
    
    if (scriptPath != nil) {
      let process = Process()
      process.launchPath = "/usr/bin/osascript"
      process.arguments = [scriptPath!, "SpacesRenamer"]
      process.launch()
      process.waitUntilExit()
    }
  }
}
