//
//  CenteredClipView.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 9/8/18.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa

// Source: https://stackoverflow.com/a/28154936/3951475
class CenteredClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {
            if (rect.size.width > containerView.frame.size.width) {
                rect.origin.x = (containerView.frame.width - rect.width) / 2
            }

            if (rect.size.height > containerView.frame.size.height) {
                rect.origin.y = (containerView.frame.height - rect.height) / 2
            }
        }

        return rect
    }
}
