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

    static func missionControlIsActive() -> Bool {
        var result: Bool = false
        // let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption(kCGWindowListOptionOnScreenOnly), CGWindowID(0)) // CGWindowID(0) is equal to kCGNullWindowID
        let windowInfosRef = CGWindowListCopyWindowInfo(.optionOnScreenOnly, CGWindowID(0))
        guard var windows = windowInfosRef as? NSArray else { return false }
        windows = windows.filter({ return ($0 as? NSDictionary)?.object(forKey: "kCGWindowOwnerName") as! String == "Dock" }) as NSArray
        print(windows)
        for entry in windows {
            // print(entry)
//            if (entry.objectForKey("kCGWindowOwnerName") as! String) == "Dock"
//            {
//                var bounds: NSDictionary = entry.objectForKey("kCGWindowBounds") as! NSDictionary
//                if (bounds.objectForKey("Y") as! NSNumber) == -1
//                {
//                    result = true
//                }
//            }
        }
        return result
    }
}
