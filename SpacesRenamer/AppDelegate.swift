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
    let popover = CustomPopover()
    var popoverWindow = NSWindow()
    var eventMonitor: EventMonitor?

    var workspace: NSWorkspace?

    var spacesActive: Bool = false
    var holdingKey: Bool = false

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

        print("Well damn")

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.leftMouseDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                               place: .tailAppendEventTap,
                                               options: .listenOnly,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: { (proxy, type: CGEventType, event: CGEvent, userInfo) in
                                                if let info = userInfo {
                                                    let mySelf = Unmanaged<AppDelegate>.fromOpaque(info).takeUnretainedValue()

                                                    if (getpid() != event.getIntegerValueField(.eventTargetUnixProcessID)) {
                                                        mySelf.closePopover(sender: mySelf)
                                                    }

//                                                    if (mySelf.spacesActive && type == CGEventType.leftMouseDown) {
//                                                        mySelf.spacesActive = false
//                                                    }

                                                    // Listen for F3 press and release
                                                    if let other = NSEvent(cgEvent: event), event.flags.contains(.maskSecondaryFn) && other.keyCode == 160 { // F3

                                                        // If pressed
                                                        if (type == CGEventType.keyDown) {
                                                            if (other.isARepeat) {
                                                                mySelf.holdingKey = true
                                                            } else {
                                                                mySelf.holdingKey = false
                                                                mySelf.spacesActive = !mySelf.spacesActive
                                                            }
                                                        } else if (type == CGEventType.keyUp) {
                                                            // if it's holding, then MAYBE
                                                            if (mySelf.holdingKey) {
                                                                mySelf.spacesActive = false
                                                            }
                                                            mySelf.holdingKey = false
                                                        }

                                                        // If it's active, and it's shown, then close it and mark that it was open
                                                        if (mySelf.spacesActive && mySelf.popover.isShown) {
                                                            mySelf.closePopover(sender: mySelf)
                                                        }
                                                    }
                                                }

                                                return nil
        },
                                               userInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())) else {
            print("failed to create event tap")
            let alert = NSAlert()
                                                alert.addButton(withTitle: "Open Security & Privacy Preferences")
                                                alert.messageText = "SpacesRenamer needs permission for automatic closing"
                                                alert.informativeText = "Enable FunctionFlip in Security & Privacy preferences -> Privacy -> Accessibility, in System Preferences.  Then restart FunctionFlip."
                                                alert.alertStyle = .warning
                                                alert.runModal()
                                                NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Security.prefPane")
            exit(1)
        }

        print(eventTap)

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }

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

    @objc func updateActiveSpaces() {
        let info = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]
        let spacesDict = NSMutableDictionary()
        spacesDict.setValue(info, forKey: "Monitors")
        spacesDict.write(toFile: Utils.listOfSpacesPlist, atomically: true)

        if (popover.isShown) {
            closePopover(sender: nil)
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        print("Resigned")
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

        popoverWindow = NSWindow(contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY), styleMask: [.closable], backing: .buffered, defer: false)
        popoverWindow.title = "New Window"
        popoverWindow.isOpaque = false
        popoverWindow.center()
        popoverWindow.isMovableByWindowBackground = true
        popoverWindow.backgroundColor = NSColor(calibratedHue: 0, saturation: 0.0, brightness: 100, alpha: 0.95)
        popoverWindow.collectionBehavior = [.transient, .ignoresCycle]
        popoverWindow.hidesOnDeactivate = true
        popoverWindow.level = .modalPanel
        popoverWindow.contentViewController = ViewController.freshController()
        popoverWindow.makeKeyAndOrderFront(nil)

        popover.contentViewController = ViewController.freshController()
        // popover.behavior = .transient
        popover.contentViewController?.view.window?.collectionBehavior = [.transient, .ignoresCycle]
        popover.contentViewController?.view.window?.collectionBehavior = [.transient, .ignoresCycle]


        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self {
                if (strongSelf.popover.isShown) {
                    strongSelf.closePopover(sender: event)
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
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        eventMonitor?.start()
        self.statusItem.button?.isHighlighted = true
        if let button = statusItem.button {
            button.window?.collectionBehavior = [.transient, .ignoresCycle]
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            print(popover.contentSize)
            print(popover.contentViewController?.view.window?.collectionBehavior)
        }
    }

    @objc func closePopover(sender: Any?) {
        popover.performClose(sender)
        self.statusItem.button?.isHighlighted = false
        eventMonitor?.stop()
    }
}
