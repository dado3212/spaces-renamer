//
//  CustomPopover.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 4/1/18.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa

class CustomPopover: NSPopover {
    func showPopover(sender: AnyObject?, button: NSButton) {
        self.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
    }

    func closePopover(sender: AnyObject?) {
        self.performClose(sender)
    }

    override func performClose(_ sender: Any?) {
        super.performClose(sender)
        (NSApplication.shared.delegate as! AppDelegate).statusItem.button?.isHighlighted = false
    }

    func togglePopover(sender: AnyObject?, button: NSButton) {
        if self.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender, button: button)
        }
    }
}
