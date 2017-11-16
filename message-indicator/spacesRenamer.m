//
//  spaces-renamer.m
//  spaces-renamer
//
//  Created by Alex Beals
//  Copyright 2017 Alex Beals.
//

@import AppKit;
#import "ZKSwizzle.h"
#import <QuartzCore/QuartzCore.h>

#define plistPath [@"~/Library/Preferences/com.alexbeals.spacesrenamer.plist" stringByExpandingTildeInPath]
#define spacesPath [@"~/Library/Preferences/com.apple.spaces.plist" stringByExpandingTildeInPath]

@interface ECMaterialLayer : CALayer
@end

static void setTextLayer(CALayer *view, NSString *newString) {
    if (view.class == NSClassFromString(@"ECTextLayer")) {
        ((CATextLayer *)view).string = newString;
    } else {
        for (int i = 0; i < view.sublayers.count; i++) {
            setTextLayer(view.sublayers[i], newString);
        }
    }
}

static NSMutableArray *getNamesFromPlist() {
    NSDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:@"spaces_renaming"];
    NSDictionary *spaces = [NSDictionary dictionaryWithContentsOfFile:spacesPath];
    NSArray *listOfSpaces = [spaces valueForKeyPath:@"SpacesDisplayConfiguration.Management Data.Monitors.Spaces"][0];

    NSMutableArray *newNames = [NSMutableArray arrayWithCapacity:listOfSpaces.count];

    for (int i = 0; i < listOfSpaces.count; i++) {
        id name = [dict objectForKey:listOfSpaces[i][@"uuid"]];
        if (name != nil) {
            newNames[i] = name;
        } else {
            newNames[i] = @"";
        }
    }

    return newNames;
}

ZKSwizzleInterface(_CDECMaterialLayer, ECMaterialLayer, CALayer);
@implementation _CDECMaterialLayer

- (void)setBounds:(CGRect)arg1 {
    ZKOrig(void, arg1);

    // Almost surely the desktop switcher
    if (self.superlayer.class == NSClassFromString(@"CALayer") && self.sublayers.count == 4) {
        NSArray<CALayer *> *unexpandedViews = self.sublayers[3].sublayers[0].sublayers;
        NSArray<CALayer *> *expandedViews = self.sublayers[3].sublayers[1].sublayers;

        // Get all of the names
        NSMutableArray* names = getNamesFromPlist();
        // Change them if set
        for (int i = 0; i < names.count; i++) {
            if (names[i] != nil && ![names[i] isEqualToString:@""]) {
                setTextLayer(expandedViews[i], names[i]);
                setTextLayer(unexpandedViews[i], names[i]);
            }
        }
    }
}

@end
