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

    static func ownerOfPID(_ pid: Int64) -> String {
        let windowInfosRef = CGWindowListCopyWindowInfo(.optionOnScreenOnly, CGWindowID(0))
        guard var windows = windowInfosRef as? NSArray else { return "" }
        windows = windows.filter({ return ($0 as? NSDictionary)?.object(forKey: "kCGWindowOwnerPID") as! Int64 == pid }) as NSArray
        print(windows)
        return (windows.firstObject as? NSDictionary)?.object(forKey: "kCGWindowOwnerName") as! String
    }
}
