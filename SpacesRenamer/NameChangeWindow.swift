//
//  NameChangeWindow.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 4/1/18.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa

class NameChangeWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.title = "Spaces Renamer"
        self.isOpaque = false
        self.isMovable = false
        self.backgroundColor = NSColor(calibratedHue: 0, saturation: 0.0, brightness: 100, alpha: 0.95)
        // To make it auto-hide on F3
        self.collectionBehavior = [.transient, .ignoresCycle]
        self.level = .modalPanel

        // Adapted from https://stackoverflow.com/a/27613308/3951475 for rounded corners
        self.styleMask = [.resizable, .titled, .fullSizeContentView]
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.showsToolbarButton = false

        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
}
