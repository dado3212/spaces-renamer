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
    var viewsToRemove: [NSView] = []

    var monitorPairings: [[NSScrollView: [DesktopSnippet]]] = []

    let widthInDesktops = 6

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    func teardownViews() {
        NSLayoutConstraint.deactivate(constraints)

        for pairings in monitorPairings {
            for (_, snippets) in pairings {
                for snippet in snippets {
                    snippet.removeFromSuperview()
                }
            }
        }

        for view in viewsToRemove {
            view.removeFromSuperview()
        }

        constraints = []
        monitorPairings = []
        desktops = [String: NSTextField]()
        viewsToRemove = []
    }

    func setupViews() {
        // Load in a list of all of the spaces
        guard let spacesDict = NSDictionary(contentsOfFile: Utils.listOfSpacesPlist),
            let allMonitors = spacesDict.value(forKeyPath: "Monitors") as? NSArray else { return }

        // Keep reference to previous for constraint
        var prev: NSView?
        var above: NSView?

        // Get the # of spaces in the maximum monitor
        let maxSpacesPerMonitor = allMonitors.reduce(Int.min, { max($0, (($1 as? NSDictionary)?.value(forKey: "Spaces") as! NSArray).count) })

        // For each monitor
        for j in 1...allMonitors.count {
            // Get the spaces for that monitor
            let allSpaces = (allMonitors[j-1] as? NSDictionary)?.value(forKey: "Spaces") as! NSArray

            // And the selected monitor
            let currentSpace = (allMonitors[j-1] as? NSDictionary)?.value(forKeyPath: "Current Space.uuid") as! String

            // If there is more than one monitor, make a label for it, and use it as the 'above' marker
            if (allMonitors.count > 1) {
                let monitorLabel = NSTextField(labelWithString: "Monitor \(j)")
                monitorLabel.font = NSFont(name: "HelveticaNeue-Bold", size: 14)
                monitorLabel.translatesAutoresizingMaskIntoConstraints = false

                var topConstraint: NSLayoutConstraint?
                if (above != nil) {
                    topConstraint = NSLayoutConstraint(item: monitorLabel, attribute: .top, relatedBy: .equal, toItem: above, attribute: .bottom, multiplier: 1.0, constant: 10)
                } else {
                    topConstraint = NSLayoutConstraint(item: monitorLabel, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 10)
                }

                let leftConstraint = NSLayoutConstraint(item: monitorLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 10)

                // Add to arrays so this can be undone later
                constraints.append(topConstraint!)
                constraints.append(leftConstraint)
                self.view.addSubview(monitorLabel)
                self.view.addConstraints([topConstraint!, leftConstraint])
                viewsToRemove.append(monitorLabel)

                above = monitorLabel
            }

            // Create a scrollview for the monitors
            let monitorScrollView = NSScrollView()
            monitorPairings.append([monitorScrollView: []])
            monitorScrollView.translatesAutoresizingMaskIntoConstraints = false
            monitorScrollView.verticalScrollElasticity = .none
            monitorScrollView.drawsBackground = false
            // Don't let it scroll if it's not necessary
            if (allSpaces.count <= widthInDesktops) {
                monitorScrollView.horizontalScrollElasticity = .none
            } else {
                monitorScrollView.hasHorizontalScroller = true
            }

            // Make the view that will hold all of the desktops
            let snippetView = NSView()
            snippetView.translatesAutoresizingMaskIntoConstraints = false
            snippetView.wantsLayer = true
            self.view.addSubview(monitorScrollView)

            // Remember to make it removable
            viewsToRemove.append(snippetView)
            viewsToRemove.append(monitorScrollView)

            // Attach the scrollview to the top left of the window
            var verticalConstraint: NSLayoutConstraint?
            if (above != nil) {
                verticalConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .top  , relatedBy: .equal, toItem: above, attribute: .bottom, multiplier: 1.0, constant: 10)
            } else {
                verticalConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .top  , relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 10)
            }
            var horizontalConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 10)

            constraints.append(verticalConstraint!)
            constraints.append(horizontalConstraint)
            self.view.addConstraints([verticalConstraint!, horizontalConstraint])

            prev = nil

            // For each space, make a text field
            for i in 1...allSpaces.count {
                let uuid = (allSpaces[i-1] as! [AnyHashable: Any])["uuid"] as! String

                let snippet = DesktopSnippet.instanceFromNib()
                if (uuid == currentSpace) {
                    snippet.monitorImage.image = NSImage(named: NSImage.Name("MonitorSelected"))
                    snippet.isCurrent = true
                }

                snippet.label.stringValue = "\(i)"
                snippet.textField.delegate = self
                snippetView.addSubview(snippet)
                monitorPairings[monitorPairings.count - 1][monitorScrollView]!.append(snippet)

                desktops[uuid] = snippet.textField

                // Attach the desktop to the left of the snippet beforehand
                var horizontalConstraint: NSLayoutConstraint?
                let verticalConstraint = NSLayoutConstraint(item: snippet, attribute: .top  , relatedBy: .equal, toItem: snippetView, attribute: .top, multiplier: 1.0, constant: 10)

                if (prev == nil) {
                    horizontalConstraint = NSLayoutConstraint(item: snippet, attribute: .leading, relatedBy: .equal, toItem: snippetView, attribute: .leading, multiplier: 1.0, constant: 10)
                } else {
                    horizontalConstraint = NSLayoutConstraint(item: snippet, attribute: .leading, relatedBy: .equal, toItem: prev, attribute: .trailing, multiplier: 1.0, constant: 10)
                }

                constraints.append(verticalConstraint)
                constraints.append(horizontalConstraint!)
                snippetView.addConstraints([verticalConstraint, horizontalConstraint!])
                prev = snippet
            }

            // Attach the bottom right snippet to the bottom right of the snippet view
            verticalConstraint = NSLayoutConstraint(item: snippetView, attribute: .trailing, relatedBy: .equal, toItem: prev, attribute: .trailing, multiplier: 1.0, constant: 10)
            horizontalConstraint = NSLayoutConstraint(item: snippetView, attribute: .bottom, relatedBy: .equal, toItem: prev, attribute: .bottom, multiplier: 1.0, constant: 10)

            constraints.append(verticalConstraint!)
            constraints.append(horizontalConstraint)
            snippetView.addConstraints([verticalConstraint!, horizontalConstraint])

            // Set the scrollView to be the snippetView (and centered)
            monitorScrollView.contentView = CenteredClipView()
            monitorScrollView.contentView.drawsBackground = false
            monitorScrollView.documentView = snippetView

            // Make sure they're the same height
            let equalHeight = NSLayoutConstraint(item: monitorScrollView, attribute: .height, relatedBy: .equal, toItem: snippetView, attribute: .height, multiplier: 1.0, constant: 0)
            constraints.append(equalHeight)
            self.view.addConstraint(equalHeight)

            // Set the scrollView to be the width of 6.5 monitors max, or just the normal width
            let widthConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(min(Double(widthInDesktops) + 0.5, Double(max(2, allSpaces.count))) * 140.0 + 10.0))
            constraints.append(widthConstraint)
            self.view.addConstraints([widthConstraint])

            prev = monitorScrollView
            above = monitorScrollView

            // If it's the largest one, then make sure that the overall screen is at least that large
            if (allSpaces.count == maxSpacesPerMonitor) {
                let horizontalLayout = NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: prev!, attribute: .trailing, multiplier: 1.0, constant: 10)
                constraints.append(horizontalLayout)
                self.view.addConstraints([horizontalLayout])
            }
        }

        // Move the update button to the bottom
        let verticalConstraint = NSLayoutConstraint(item: updateButton, attribute: .top, relatedBy: .equal, toItem: prev!, attribute: .bottom, multiplier: 1.0, constant: 10)
        constraints.append(verticalConstraint)

        self.view.addConstraints([verticalConstraint])
    }

    func refreshViews() {
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

    override func viewWillAppear() {
        super.viewWillAppear()

        refreshViews()
    }

    func selectCurrent() {
        var set = false
        for pairing in monitorPairings {
            for (monitor, snippets) in pairing {
                for snippet in snippets {
                    if snippet.isCurrent {
                        monitor.scrollToView(view: snippet)
                        if (!set) {
                            snippet.textField.becomeFirstResponder()
                            set = true
                        }
                    }
                }
            }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        selectCurrent()
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
        delegate.closeNameChangeWindow(sender: delegate)
    }
}

extension ViewController: NSTextFieldDelegate {
    override func cancelOperation(_ sender: Any?) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.closeNameChangeWindow(sender: nil)
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.pressChangeName(textView)
            return true
        }
        return false
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

