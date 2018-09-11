//
//  Extensions.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 9/10/18.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Foundation
import Cocoa

extension NSScrollView {
    func scrollToView(view: NSView) {
        if let origin = view.superview {
            let childStartPoint = origin.convert(view.frame.origin, to: self)

            let scrollability = self.hasHorizontalScroller
            self.hasHorizontalScroller = false

            self.documentView?.scrollToVisible(CGRect(x: childStartPoint.x, y: 0, width: view.frame.width, height: self.frame.height))

            self.hasHorizontalScroller = scrollability
        }
    }
}
