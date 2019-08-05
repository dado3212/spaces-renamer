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

// Helper extension for 10.10 support
extension NSTextField {
  convenience init(labelWithStringCustom string: String) {
    if #available(macOS 10.12, *) {
      self.init(labelWithString: string)
    } else {
      self.init()
      self.isEditable = false
      self.isSelectable = false
      self.textColor = .labelColor
      self.backgroundColor = .controlColor
      self.drawsBackground = false
      self.isBezeled = false
      self.alignment = .natural
      self.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: self.controlSize))
      self.lineBreakMode = .byClipping
      self.cell?.isScrollable = true
      self.cell?.wraps = false
      self.stringValue = string
    }
  }
}
