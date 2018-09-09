//
//  Utils.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.

import Foundation

class Utils {
    static let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
    static let customNamesPlist = Utils.libraryPath.appending("/Containers/\(Bundle.main.bundleIdentifier!)/com.alexbeals.spacesrenamer.plist")
    static let listOfSpacesPlist = Utils.libraryPath.appending("/Containers/\(Bundle.main.bundleIdentifier!)/com.alexbeals.spacesrenamer.currentspaces.plist")
    static let spacesPath = Utils.libraryPath.appending("/Preferences/com.apple.spaces.plist")

    static let escapeKey: UInt16 = 0x35

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
