//
//  AppDelegate.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa
import Foundation

@NSApplicationMain
@objc
class AppDelegate: NSObject, NSApplicationDelegate {
  let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
  let popover = NSPopover()
  var eventMonitor: EventMonitor?

  var workspace: NSWorkspace?

  let conn = _CGSDefaultConnection()

  fileprivate func configureObservers() {
    workspace = NSWorkspace.shared
    workspace?.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.updateActiveSpaces),
      name: NSWorkspace.activeSpaceDidChangeNotification,
      object: workspace
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(AppDelegate.updateActiveSpaces),
      name: NSApplication.didChangeScreenParametersNotification,
      object: nil
    )
  }

  // Watches the file to determine if the spaces update (new one added or deleted)
  fileprivate func configureSpaceMonitor() {
    let fullPath = (Utils.spacesPath as NSString).expandingTildeInPath
    let queue = DispatchQueue.global(qos: .default)
    let fildes = open(fullPath.cString(using: String.Encoding.utf8)!, O_EVTONLY)
    if fildes == -1 {
      NSLog("Failed to open file: \(Utils.spacesPath)")
      return
    }

    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fildes, eventMask: DispatchSource.FileSystemEvent.delete, queue: queue)

    source.setEventHandler { () -> Void in
      let flags = source.data.rawValue
      if (flags & DispatchSource.FileSystemEvent.delete.rawValue != 0) {
        source.cancel()
        self.updateActiveSpaces()
        self.configureSpaceMonitor()
      }
    }

    source.setCancelHandler { () -> Void in
      close(fildes)
    }

    source.resume()
  }

  // Runs when a space is moved or switched, which confirms that the current list is in the right order
  @objc func updateActiveSpaces() {
    let info = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]

    // Only update the layout/window if it's changed
    if (info as NSArray) != (Utils.monitors as NSArray) {
      Utils.monitors = info

      DispatchQueue.main.async {
        if (self.popover.isShown) {
          (self.popover.contentViewController as? ViewController)?.refreshViews()
        }
      }
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if let button = statusItem.button {
      button.image = NSImage(named:NSImage.Name("StatusBarIcon"))
      button.target = self
      button.action = #selector(AppDelegate.statusItemClicked(_:))
    }

    // Add it as a login item
    Utils.addPathToLoginItemsIfNecessary(path: Bundle.main.bundlePath, name: "SpacesRenamer")

    popover.contentViewController = ViewController.freshController()

    // Close on clicks in other apps, rather than with NSPopover's transient behavior: on macOS 27 the
    // menu bar runs in MenuBarAgent, so a click on the status item also arrives here, before the
    // status item sees it. Leave those to the status item.
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      if let strongSelf = self {
        let onStatusItem = strongSelf.statusItem.button?.window?.frame.contains(NSEvent.mouseLocation) ?? false
        if (strongSelf.popover.isShown && !onStatusItem) {
          strongSelf.closePopover(sender: event)
        }
      }
    }

    configureObservers()
    configureSpaceMonitor()
    Utils.importLegacyNames()
    updateActiveSpaces()
    PluginLoader.shared.start()
  }

  // Left click without Command; Command-dragging rearranges the menu bar
  @objc func statusItemClicked(_ sender: Any?) {
    if NSApp.currentEvent?.modifierFlags.contains(.command) == true {
      return
    }
    togglePopover(sender)
  }

  @objc func togglePopover(_ sender: Any?) {
    if popover.isShown {
      closePopover(sender: sender)
    } else {
      showPopover(sender: sender)
    }
  }

  func showPopover(sender: Any?) {
    guard let button = statusItem.button else { return }
    NSApp.activate(ignoringOtherApps: true)
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    if let window = popover.contentViewController?.view.window {
      // Stay open while switching spaces, and hide for Mission Control
      window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
      // So the current space's name field takes typing
      window.makeKey()
    }
    eventMonitor?.start()
  }

  @objc func closePopover(sender: Any?) {
    popover.close()
    eventMonitor?.stop()
  }
}
