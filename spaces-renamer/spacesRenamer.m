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

/*
 1. Load the customNamesPlist for named spaces
 2. Load the listOfSpacesPlist to get the current list of spaces
 3. Crosslist and return the custom names for each plist
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

        NSMutableArray *monitorNames = [NSMutableArray arrayWithCapacity:listOfSpaces.count];
        for (int j = 0; j < listOfSpaces.count; j++) {
            id name = [dict objectForKey:listOfSpaces[j][@"uuid"]];
            if (name != nil) {
                monitorNames[j] = name;
            } else {
                monitorNames[j] = @"";
            }
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

        // Get all of the names
        NSMutableArray* names = getNamesFromPlist();

        monitorIndex = monitorIndex % names.count;

        for (int i = 0; i < ((NSArray*)names[monitorIndex]).count; i++) {
            if (names[monitorIndex][i] != nil && ![names[monitorIndex][i] isEqualToString:@""] && i < MAX(expandedViews.count, unexpandedViews.count)) {
                setTextLayer(expandedViews[i], names[monitorIndex][i]);
                setTextLayer(unexpandedViews[i], names[monitorIndex][i]);
            }
        }

        monitorIndex += 1;
    }
}

@end
