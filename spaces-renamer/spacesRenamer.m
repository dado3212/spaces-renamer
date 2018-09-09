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

static char OVERRIDDEN_STRING;
static char OVERRIDDEN_FRAME;
static char FRAME;

#define customNamesPlist [@"~/Library/Containers/com.alexbeals.spacesrenamer/com.alexbeals.spacesrenamer.plist" stringByExpandingTildeInPath]
#define listOfSpacesPlist [@"~/Library/Containers/com.alexbeals.spacesrenamer/com.alexbeals.spacesrenamer.currentspaces.plist" stringByExpandingTildeInPath]
#define spacesPath [@"~/Library/Preferences/com.apple.spaces.plist" stringByExpandingTildeInPath]

int monitorIndex = 0;

@interface ECMaterialLayer : CALayer
@end

static void assign(id a, void *key, id assigned) {
    objc_setAssociatedObject(a, key, assigned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void setTextLayer(CALayer *view, NSString *newString) {
    if (view.class == NSClassFromString(@"ECTextLayer")) {
        ((CATextLayer *)view).string = newString;
        assign(view, &OVERRIDDEN_STRING, newString);
        assign(view, &FRAME, [NSValue valueWithRect:view.frame]);
    } else {
        // The opacity is animated, but it's the same ONE, until you swipe off
        for (int i = 0; i < view.sublayers.count; i++) {
            setTextLayer(view.sublayers[i], newString);
        }
    }
}

// The highlighted space has 2 sublayers, while as a normal space only has 1
static int getSelected(NSArray<CALayer *> *views) {
    for (int i = 0; i < views.count; i++) {
        if (views[i].sublayers.count > 1) {
            return i;
        }
    }
    return -1;
}

/*
 1. Load the customNamesPlist for named spaces
 2. Load the listOfSpacesPlist to get the current list of spaces
 3. Crosslist and return the custom names for each plist, and whether it's selected
 */
static NSMutableArray *getNamesFromPlist() {
    NSDictionary *dictOfNames = [NSDictionary dictionaryWithContentsOfFile:customNamesPlist];
    if (!dictOfNames) {
        return [NSMutableArray arrayWithCapacity:0];
    }
    NSDictionary *dict = [dictOfNames valueForKey:@"spaces_renaming"];
    NSDictionary *spacesCustom = [NSDictionary dictionaryWithContentsOfFile:listOfSpacesPlist];
    if (!spacesCustom) {
        return [NSMutableArray arrayWithCapacity:0];
    }
    NSArray *listOfMonitors = [spacesCustom valueForKeyPath:@"Monitors"];

    NSMutableArray *newNames = [NSMutableArray arrayWithCapacity:listOfMonitors.count];

    for (int i = 0; i < listOfMonitors.count; i++) {
        NSArray *listOfSpaces = [listOfMonitors[i] valueForKeyPath:@"Spaces"];
        NSString *selected = [listOfMonitors[i] valueForKeyPath:@"Current Space.uuid"];

        NSMutableArray *monitorNames = [NSMutableArray arrayWithCapacity:listOfSpaces.count];
        for (int j = 0; j < listOfSpaces.count; j++) {
            NSString *uuid = listOfSpaces[j][@"uuid"];
            id name = [dict objectForKey:uuid];
            NSMutableDictionary *screenDict = [NSMutableDictionary dictionary];
            screenDict[@"selected"] = @([uuid isEqualToString:selected]);
            monitorNames[j] = screenDict;
            if (name != nil) {
                screenDict[@"name"] = name;
            } else {
                screenDict[@"name"] = @"";
            }
            monitorNames[j] = screenDict;
        }
        newNames[i] = monitorNames;
    }

    return newNames;
}

ZKSwizzleInterface(_SRCALayer, CALayer, CALayer);
@implementation _SRCALayer
- (void)setBounds:(CGRect)arg1 {

    id overridden = objc_getAssociatedObject(self, &OVERRIDDEN_FRAME);
    if ([overridden isEqualToString:@"text"]) {
        // ZKOrig(void, NSRectToCGRect([objc_getAssociatedObject(self, &FRAME) rectValue]));
        objc_removeAssociatedObjects(self);
        // ZKOrig(void, CGRectMake(0, 0, 67, 17));
        ZKOrig(void, arg1);
        return;
    } else if ([overridden isEqualToString:@"background"]) {
        ZKOrig(void, CGRectMake(30, 0, 88, 22));
        return;
    }

    if (
        self.sublayers.count == 2 &&
        self.sublayers[0].class == NSClassFromString(@"CALayer") &&
        self.sublayers[0].cornerRadius == 5.0 &&
        self.sublayers[1].class == NSClassFromString(@"ECTextLayer")
    ) {
        // This is the part of the background and the text when scrolling
        assign(self.sublayers[0], &OVERRIDDEN_FRAME, @"background");
        assign(self.sublayers[1], &OVERRIDDEN_FRAME, @"text");
    }

    ZKOrig(void, arg1);
}
@end

ZKSwizzleInterface(_SRECTextLayer, ECTextLayer, CATextLayer);
@implementation _SRECTextLayer
- (void)setBounds:(CGRect)arg1 {
    ZKOrig(void, arg1);

    @try {
        [self removeObserver:self forKeyPath:@"propertiesChanged" context:nil];
    } @catch(id anException) {}
    [self addObserver:self
                       forKeyPath:@"propertiesChanged"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
}

-(void)dealloc {
    @try {
        [self removeObserver:self forKeyPath:@"propertiesChanged" context:nil];
    } @catch(id anException) {}
    ZKOrig(void);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    id overridden = objc_getAssociatedObject(self, &OVERRIDDEN_STRING);
    if ([overridden isKindOfClass:[NSString class]] && ![self.string isEqualToString:overridden]) {
        self.string = overridden;
    }
}

- (id)propertiesChanged {
    return nil;
}

+(NSSet *)keyPathsForValuesAffectingPropertiesChanged {
    return [NSSet setWithObjects:@"string", nil];
}

@end

ZKSwizzleInterface(_SRECMaterialLayer, ECMaterialLayer, CALayer);
@implementation _SRECMaterialLayer

- (void)setBounds:(CGRect)arg1 {
    ZKOrig(void, arg1);

    // Almost surely the desktop switcher
    if (self.superlayer.class == NSClassFromString(@"CALayer") && self.sublayers.count == 4) {
        NSArray<CALayer *> *unexpandedViews = self.sublayers[3].sublayers[0].sublayers;
        NSArray<CALayer *> *expandedViews = self.sublayers[3].sublayers[1].sublayers;

        int numMonitors = MAX(unexpandedViews.count, expandedViews.count);

        // Get which of the spaces in the current dock is selected
        int selected = getSelected((!unexpandedViews || !unexpandedViews.count) ? expandedViews : unexpandedViews);

        // Get all of the names
        NSMutableArray* names = getNamesFromPlist();

        if (names.count == 0) {
            return;
        }

        // Take a best guess at which monitor it is
        NSMutableArray *possibleMonitors = [[NSMutableArray alloc] init];
        for (int i = 0; i < names.count; i++) {
            if (
                ((NSArray *)names[i]).count == numMonitors && // Same number of monitors
                [names[i][selected][@"selected"] boolValue] // Same index is selected
            ) {
                [possibleMonitors addObject:[NSNumber numberWithInt:i]];
            }
        }
        // If only one monitor, good to go
        // If more than one monitor, then just go with the same cycling as it appears to have been last time it was good to go
        if (possibleMonitors.count == 1) {
            monitorIndex = [possibleMonitors[0] intValue];
        }
        [possibleMonitors release];

        monitorIndex = monitorIndex % names.count;

        for (int i = 0; i < ((NSArray*)names[monitorIndex]).count; i++) {
            if (names[monitorIndex][i][@"name"] != nil && ![names[monitorIndex][i][@"name"] isEqualToString:@""]) {
                if (i < expandedViews.count) {
                    setTextLayer(expandedViews[i], names[monitorIndex][i][@"name"]);
                }
                if (i < unexpandedViews.count) {
                    setTextLayer(unexpandedViews[i], names[monitorIndex][i][@"name"]);
                }
            }
        }

        monitorIndex += 1;
    }
}

@end
