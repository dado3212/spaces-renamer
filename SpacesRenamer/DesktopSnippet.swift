//
//  DesktopSnippet.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/16/17.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa

class DesktopSnippet: NSView {

  @IBOutlet var label: NSTextField!
  @IBOutlet var textField: NSTextField!
  @IBOutlet var monitorImage: NSImageView!
  var isCurrent: Bool = false
  var monitorID = 0

  class func instanceFromNib() -> DesktopSnippet {
    var topLevelObjects : NSArray?
    if Bundle.main.loadNibNamed("DesktopSnippet", owner: self, topLevelObjects: &topLevelObjects) {
      let snippet = (topLevelObjects!.first(where: { $0 is DesktopSnippet }) as? DesktopSnippet)!
      // These names are short and don't benefit from spell-check / autocomplete /
      // text replacement, and turning them off avoids per-focus XPC chatter to
      // com.apple.TextInputUI / CursorUI that otherwise spams the log.
      snippet.textField.isAutomaticTextCompletionEnabled = false
      snippet.textField.allowsCharacterPickerTouchBarItem = false
      return snippet
    }
    return DesktopSnippet()
  }
}
