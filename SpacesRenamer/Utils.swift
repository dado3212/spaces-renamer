//
//  Utils.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.

import Foundation

class Utils {

    static let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
    static let plistPath = Utils.libraryPath.appending("/Preferences/com.alexbeals.spacesrenamer.plist")
    static let spacesPath = Utils.libraryPath.appending("/Preferences/com.apple.spaces.plist")
}
