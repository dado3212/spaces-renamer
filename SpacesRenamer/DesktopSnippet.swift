//
//  DesktopSnippet.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/16/17.
//  Copyright © 2017 cvz. All rights reserved.
//

import Cocoa

class DesktopSnippet: NSView {

    @IBOutlet var label: NSTextField!
    @IBOutlet var textField: NSTextField!

    class func instanceFromNib() -> DesktopSnippet {
        var topLevelObjects : NSArray?
        if Bundle.main.loadNibNamed(NSNib.Name(rawValue: "DesktopSnippet"), owner: self, topLevelObjects: &topLevelObjects) {
            return (topLevelObjects!.first(where: { $0 is DesktopSnippet }) as? DesktopSnippet)!
        }
        return DesktopSnippet()
    }
}
