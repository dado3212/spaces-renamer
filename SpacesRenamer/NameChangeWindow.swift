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
    self.collectionBehavior = [.transient, .ignoresCycle, .canJoinAllSpaces]
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

  // Close self on 'esc'
  override func keyDown(with event: NSEvent) {
    if (event.keyCode == Utils.escapeKey) {
      if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
        appDelegate.closeNameChangeWindow(sender: nil)
      }
    }
    super.keyDown(with: event)
  }

  func selectCurrent() {
    DispatchQueue.main.async {
      if let viewController = self.contentViewController as? ViewController {
        viewController.selectCurrent()
      }
    }
  }
  
  func refresh() {
    DispatchQueue.main.async {
      if let appDelegate = NSApplication.shared.delegate as? AppDelegate, let button = appDelegate.statusItem.button {
        // Use the hidden popover to get the dimensions, and then immediately hide it
        appDelegate.hiddenPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        if let frame = appDelegate.hiddenPopover.contentViewController?.view.window?.frame {
          appDelegate.nameChangeWindow.setFrame(frame, display: true)
        }
        appDelegate.hiddenPopover.close()

        if let viewController = appDelegate.nameChangeWindow.contentViewController as? ViewController {
          viewController.refreshViews()
        }

        appDelegate.nameChangeWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
  }
}
