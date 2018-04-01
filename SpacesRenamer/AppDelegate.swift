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
    var eventMonitor: EventMonitor?

    var workspace: NSWorkspace?

    var spacesActive: Bool = false
    var holdingKey: Bool = false
    var wasOpen: Bool = false

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

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                               place: .tailAppendEventTap,
                                               options: .listenOnly,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: { (proxy, type: CGEventType, event: CGEvent, userInfo) in
                                                if (getpid() != event.getIntegerValueField(.eventTargetUnixProcessID)) {
                                                    (NSApplication.shared.delegate as! AppDelegate).closePopover(sender: nil)
                                                }

                                                // Listen for F3 press and release
                                                if let other = NSEvent(cgEvent: event), event.flags.contains(.maskSecondaryFn) && other.keyCode == 160 { // F3

                                                    // If pressed
                                                    if let info = userInfo {
                                                        let mySelf = Unmanaged<AppDelegate>.fromOpaque(info).takeUnretainedValue()
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

                                                        if (mySelf.wasOpen && !mySelf.spacesActive) {
                                                            mySelf.showPopover(sender: nil)
                                                        }
                                                        if (mySelf.spacesActive) {
                                                            mySelf.closePopover(sender: nil)
                                                        }
                                                        print(mySelf.spacesActive)
                                                    }

                                                    // (NSApplication.shared.delegate as! AppDelegate).closePopover(sender: nil)
                                                }

//                                                if flags.contains(.maskSecondaryFn) {
//                                                    msg += "function+"
//                                                }
//                                                if let other = NSEvent(cgEvent: event), let chars = other.characters {
//                                                    print(other)
//                                                    print(other.characters)
//                                                    print(other.keyCode)
//                                                    msg += chars
//                                                    print(msg)
//                                                }
                                                // print("Window: \(getpid()), Targeting: \(event.getIntegerValueField(.eventTargetUnixProcessID)) with type \(type.rawValue)")
                                                return nil
        },
                                               userInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())) else {
                                                print("failed to create event tap")
                                                exit(1)
        }

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

        popover.contentViewController = ViewController.freshController()

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
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
            self.statusItem.button?.isHighlighted = false
        } else {
            showPopover(sender: sender)
            self.statusItem.button?.isHighlighted = true
        }
    }

    func showPopover(sender: Any?) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        eventMonitor?.start()
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    @objc func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}
