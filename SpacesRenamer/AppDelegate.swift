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
    var nameChangeWindow: NameChangeWindow = NameChangeWindow()
    let hiddenPopover = NSPopover()
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
        let spacesDict = NSMutableDictionary()
        spacesDict.setValue(info, forKey: "Monitors")
        spacesDict.write(toFile: Utils.listOfSpacesPlist, atomically: true)

        if (nameChangeWindow.isVisible) {
            nameChangeWindow.refresh()
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarIcon"))
        }

        // Listen for left click
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if event.window == self?.statusItem.button?.window {
                self?.togglePopover(self?.statusItem.button)
                return nil
            }

            return event
        }

        // Create the bundle folder if it doesn't exist
        do {
            try FileManager.default.createDirectory(atPath: Utils.libraryPath.appending("/Containers/\(Bundle.main.bundleIdentifier!)"), withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Not really sure.")
        }

        nameChangeWindow.contentViewController = ViewController.freshController()
        hiddenPopover.contentViewController = ViewController.freshController()
        hiddenPopover.animates = false

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self {
                if (strongSelf.nameChangeWindow.isVisible) {
                    strongSelf.closeNameChangeWindow(sender: event)
                }
            }
        }

        configureObservers()
        configureSpaceMonitor()
        updateActiveSpaces()

        if !FileManager.default.fileExists(atPath: Utils.listOfSpacesPlist) {
            guard let spacesDict = NSDictionary(contentsOfFile: Utils.spacesPath) else { return }
            let allSpaces = (spacesDict.value(forKeyPath: "SpacesDisplayConfiguration.Management Data.Monitors") as! NSArray)

            let listOfSpacesDict = NSMutableDictionary()
            listOfSpacesDict.setValue(allSpaces, forKey: "Monitors")

            listOfSpacesDict.write(toFile: Utils.listOfSpacesPlist, atomically: true)
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if nameChangeWindow.isVisible {
            closeNameChangeWindow(sender: sender)
        } else {
            showNameChangeWindow(sender: sender)
        }
    }

    func showNameChangeWindow(sender: Any?) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        eventMonitor?.start()
        self.statusItem.button?.isHighlighted = true
        if let button = statusItem.button {
            // Use the hidden popover to get the dimensions, and then immediately hide it
            hiddenPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            if let frame = hiddenPopover.contentViewController?.view.window?.frame {
                nameChangeWindow.setFrame(frame, display: true)
            }
            hiddenPopover.close()

            nameChangeWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func closeNameChangeWindow(sender: Any?) {
        nameChangeWindow.setIsVisible(false)
        DispatchQueue.main.async {
            self.statusItem.button?.isHighlighted = false
        }
        eventMonitor?.stop()
    }
}
