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

//        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.mouseMoved.rawValue)
//        guard let eventTap = CGEvent.tapCreate(tap: .cgAnnotatedSessionEventTap,
//                                               place: .headInsertEventTap,
//                                               options: .listenOnly,
//                                               eventsOfInterest: CGEventMask(eventMask),
//                                               callback: { (proxy, type, event, userInfo) in
//                                                print(event)
//                                                //        let obj = Unmanaged<EventTap>.fromOpaque(userInfo!).takeUnretainedValue()
//                                                //        obj.callback(event, proxy)
//                                                return nil // Unmanaged.passRetained(event)
//        },
//                                               userInfo: nil) else {
//                                                print("failed to create event tap")
//                                                exit(1)
//        }
//
//        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
//        CGEvent.tapEnable(tap: eventTap, enable: true)
//        CFRunLoopRun()
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
