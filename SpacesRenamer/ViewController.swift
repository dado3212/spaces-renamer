//
//  ViewController.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var updateButton: NSButton!

    var desktops: [String: NSTextField] = [String: NSTextField]()
    var constraints: [NSLayoutConstraint] = []
    var snippets: [DesktopSnippet] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    func teardownViews() {
        NSLayoutConstraint.deactivate(constraints)

        for view in snippets {
            view.removeFromSuperview()
        }

        constraints = []
        snippets = []
        desktops = [String: NSTextField]()
    }

    func setupViews() {
        // Load in a list of all of the spaces
        guard let spacesDict = NSDictionary(contentsOfFile: Utils.listOfSpacesPlist),
            let allMonitors = spacesDict.value(forKeyPath: "Monitors") as? NSArray else { return }

        // Keep reference to previous for constraint
        var prev: DesktopSnippet?

        // For each space, make a text field
        for j in 1...allMonitors.count {
            let allSpaces = (allMonitors[j-1] as? NSDictionary)?.value(forKey: "Spaces") as! NSArray

            for i in 1...allSpaces.count {
                let snippet = DesktopSnippet.instanceFromNib()
                snippet.label.stringValue = "Monitor \(j) - Desktop \(i)"
                self.view.addSubview(snippet)
                snippets.append(snippet)

                let uuid = (allSpaces[i-1] as! [AnyHashable: Any])["uuid"] as! String

                desktops[uuid] = snippet.textField

                var verticalConstraint: NSLayoutConstraint?
                let horizontalConstraint = NSLayoutConstraint(item: snippet, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0)

                if (prev == nil) {
                    verticalConstraint = NSLayoutConstraint(item: snippet, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0)
                } else {
                    verticalConstraint = NSLayoutConstraint(item: snippet, attribute: .top, relatedBy: .equal, toItem: prev, attribute: .bottom, multiplier: 1.0, constant: 0)
                }

                constraints.append(verticalConstraint!)
                constraints.append(horizontalConstraint)
                self.view.addConstraints([verticalConstraint!, horizontalConstraint])
                prev = snippet
            }
        }

        let verticalConstraint = NSLayoutConstraint(item: updateButton, attribute: .top, relatedBy: .equal, toItem: prev!, attribute: .bottom, multiplier: 1.0, constant: 10)
        constraints.append(verticalConstraint)

        self.view.addConstraints([verticalConstraint])
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        teardownViews()
        setupViews()

        var currentMapping = NSMutableDictionary()
        if let preferencesDict = NSMutableDictionary(contentsOfFile: Utils.customNamesPlist),
            let spacesRemaining = preferencesDict.value(forKey: "spaces_renaming") as? NSMutableDictionary {
            currentMapping = spacesRemaining
        }
        
        // Update with the current names
        for (uuid, textField) in desktops {
            if let newName = currentMapping.value(forKey: uuid) {
                textField.stringValue = newName as! String
            }
        }
    }

    @IBAction func quitMenuApp(_ sender: Any) {
        NSApp.terminate(nil)
    }

    @IBAction func pressChangeName(_ sender: Any) {
        // Load from preferences the current mapping
        let preferencesDict = NSMutableDictionary(contentsOfFile: Utils.customNamesPlist) ?? NSMutableDictionary()
        let currentMapping = (preferencesDict.value(forKey: "spaces_renaming") as? NSMutableDictionary) ?? NSMutableDictionary()

        // Update accordingly
        for (uuid, textField) in desktops {
            currentMapping.setValue(textField.stringValue, forKey: uuid)
        }

        preferencesDict.setValue(currentMapping, forKey: "spaces_renaming")

        // Resave
        preferencesDict.write(toFile: Utils.customNamesPlist, atomically: true)

        // Close the popup
        let delegate = NSApplication.shared.delegate as! AppDelegate
        delegate.closePopover(sender: delegate)
    }
}

extension ViewController {
    static func freshController() -> ViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "Popup")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Bugged")
        }
        return viewcontroller
    }
}

