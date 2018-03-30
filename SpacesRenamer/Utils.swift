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

//    static func saveDictionaryToPath(dictionary: NSDictionary, path: String) {
//
//    }
//    NSFileManager* fileManager = [[NSFileManager alloc] init];
//    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
//    NSArray* urlPaths = [fileManager URLsForDirectory:NSApplicationSupportDirectory
//    inDomains:NSUserDomainMask];
//
//    NSURL* appDirectory = [[urlPaths objectAtIndex:0] URLByAppendingPathComponent:bundleID isDirectory:YES];
//
//    //TODO: handle the error
//    if (![fileManager fileExistsAtPath:[appDirectory path]]) {
//    [fileManager createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:nil];
//    }
}
