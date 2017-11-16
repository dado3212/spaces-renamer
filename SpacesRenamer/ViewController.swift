//
//  ViewController.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2017 cvz. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var nameField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    

    func getCurrentSpace() -> String {
        var a = CurrentSpace()
        a.someMethod()


//        for i in 1...CFArrayGetCount(windows)-1 {
//            let windict = CFArrayGetValueAtIndex(windows, i)
//            if let dict = windict as! CFDictionary {
//                //let spacenum = CFDictionaryGetValue(windict as! CFDictionary, kCGWindowNumber)
//                let spacenum = CFDictionaryGetValue(dict, unsafeBitCast(kCGWindowNumber, to: UnsafeRawPointer.self))
//                print(spacenum)
//            }
//
//        }

//        for (i = 0, n = CFArrayGetCount(windows); i < n; i++) {
//            CFDictionaryRef windict = CFArrayGetValueAtIndex(windows, i);
//            CFNumberRef spacenum = CFDictionaryGetValue(windict, kCGWindowWorkspace);
//            if (spacenum) {
//                CFNumberGetValue(spacenum,  kCFNumberIntType, &space);
//                return space;
//            }
//        }
        return "";
    }

    @IBAction func pressChangeName(_ sender: Any) {
        // Get the current desktop...?
        guard let spacesDict = NSDictionary(contentsOfFile: Utils.spacesPath) else { return }
        let currentSpace = (spacesDict.value(forKeyPath: "SpacesDisplayConfiguration.Management Data.Monitors.Current Space.uuid") as! NSArray)[0] as! String
        print(currentSpace)
        print(getCurrentSpace())

        // Load from preferences the current mapping
        let preferencesDict = NSMutableDictionary(contentsOfFile: Utils.plistPath) ?? NSMutableDictionary()
        let currentMapping = (preferencesDict.value(forKey: "spaces_renaming") as? NSMutableDictionary) ?? NSMutableDictionary()

        // Update accordingly
        currentMapping.setValue(nameField.stringValue, forKey: currentSpace)
        print(currentMapping)
        preferencesDict.setValue(currentMapping, forKey: "spaces_renaming")

        // Resave
        preferencesDict.write(toFile: Utils.plistPath, atomically: true)
    }
}

extension ViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> ViewController {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "Popup")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Why cant i find QuotesViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}

