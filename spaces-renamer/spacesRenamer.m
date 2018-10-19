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
static char OFFSET;
static char MOVED;

#define customNamesPlist [@"~/Library/Containers/com.alexbeals.spacesrenamer/com.alexbeals.spacesrenamer.plist" stringByExpandingTildeInPath]
#define listOfSpacesPlist [@"~/Library/Containers/com.alexbeals.spacesrenamer/com.alexbeals.spacesrenamer.currentspaces.plist" stringByExpandingTildeInPath]
#define spacesPath [@"~/Library/Preferences/com.apple.spaces.plist" stringByExpandingTildeInPath]

int monitorIndex = 0;

@interface ECMaterialLayer : CALayer
@end

static void refreshDockView(CALayer *dockView) {
    if (dockView != nil && dockView.superlayer.class == NSClassFromString(@"CALayer") && dockView.sublayers.count == 4) {
        NSArray<CALayer *> *unexpandedViews = dockView.sublayers[3].sublayers[0].sublayers;
        NSArray<CALayer *> *expandedViews = dockView.sublayers[3].sublayers[1].sublayers;

        for (int i = 0; i < unexpandedViews.count; i++) {
            [unexpandedViews[i] setFrame:unexpandedViews[i].frame];
            for (int j = 0; j < unexpandedViews[i].sublayers.count; j++) {
                [unexpandedViews[i].sublayers[j] setFrame:unexpandedViews[i].sublayers[j].frame];
            }
        }
    }
}

static NSString *whatAmI(CALayer *view, NSString *prefix) {
    NSMutableString *children = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i < view.sublayers.count; i++) {
        [children appendString:[
                                NSString stringWithFormat:@"%@\n",
                                whatAmI(
                                        view.sublayers[i],
                                        [NSString stringWithFormat:@"%@\t", prefix]
                                    )
                                ]];
    }
    if (children.length == 0) {
        return [NSString stringWithFormat:@"%@%@ - %@, %@", prefix, view,                                 objc_getAssociatedObject(view, &OVERRIDDEN_STRING),
                objc_getAssociatedObject(view, &OFFSET)];
    } else {
        return [NSString stringWithFormat:@"%@%@\n%@", prefix, view, [children substringToIndex:[children length]-1]];
    }
}

static void assign(id a, void *key, id assigned) {
    objc_setAssociatedObject(a, key, assigned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void setOffset(CALayer *view, int offset) {
    if (view.sublayers.count == 0) {
        assign(view, &OFFSET, [NSNumber numberWithInt:offset]);
    } else {
        // The opacity is animated, but it's the same ONE, until you swipe off
        for (int i = 0; i < view.sublayers.count; i++) {
            setOffset(view.sublayers[i], offset);
        }
    }
}

static void setTextLayer(CALayer *view, NSString *newString) {
    if (view.sublayers.count == 0) {
        assign(view, &OVERRIDDEN_STRING, newString);
        if (view.class == NSClassFromString(@"ECTextLayer")) {
            ((CATextLayer *)view).string = newString;
        }
    } else {
        // The opacity is animated, but it's the same ONE, until you swipe off
        for (int i = 0; i < view.sublayers.count; i++) {
            setTextLayer(view.sublayers[i], newString);
        }
    }
}

static CATextLayer *getTextLayer(CALayer *view) {
    CATextLayer *layer = nil;
    if (view.class == NSClassFromString(@"ECTextLayer")) {
        layer = (CATextLayer *)view;
    } else {
        for (int i = 0; i < view.sublayers.count; i++) {
            CATextLayer *tempLayer = getTextLayer(view.sublayers[i]);
            if (tempLayer != nil) {
                layer = tempLayer;
                break;
            }
        }
    }
    return layer;
}

static double getTextSize(CALayer *view, NSString *string) {
    double textSize = -1;
    CATextLayer *textLayer = getTextLayer(view);
    if (textLayer != nil) {
        CTFontRef _contentFont = ((CATextLayer *)textLayer).font;
        int strLength = (int)[string length];
        CGGlyph glyphs[strLength];
        unichar chars[strLength];
        NSRange range = {0, strLength};
        [string getCharacters:chars range:range];

        bool rc = CTFontGetGlyphsForCharacters(_contentFont, chars, glyphs, strLength);
        if (rc) {
            textSize = CTFontGetAdvancesForGlyphs(_contentFont, kCTFontOrientationDefault, glyphs, NULL, strLength);
        }
    }
    return textSize;
}

// The highlighted space has 2 sublayers, while as a normal space only has 1
static int getSelected(NSArray<CALayer *> *views) {
    NSUInteger selectedIndex = [views indexOfObjectPassingTest:
    ^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        return (BOOL)(layer.sublayers.count > 1);
    }];

    return selectedIndex == NSNotFound ? -1 : (int)selectedIndex;
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
- (void)setFrame:(CGRect)arg1 {
    if ([objc_getAssociatedObject(self, &OVERRIDDEN_FRAME) isEqualToString:@"background"]) {
        id possibleString = objc_getAssociatedObject(self, &OVERRIDDEN_STRING);
        if (possibleString && [possibleString isKindOfClass:[NSString class]]) {
            arg1.size.width = getTextSize(self.superlayer, possibleString) + 20;
        }
        return ZKOrig(void, arg1);
    }

    if (
        self.sublayers.count == 1 &&
        self.sublayers[0].class == NSClassFromString(@"ECTextLayer")
    ) {
        id possibleString = objc_getAssociatedObject(self.sublayers[0], &OVERRIDDEN_STRING);
        if (possibleString && [possibleString isKindOfClass:[NSString class]]) {
            arg1.size.width = getTextSize(self.sublayers[0], possibleString);
        }

        id possibleOffset = objc_getAssociatedObject(self.sublayers[0], &OFFSET);
        id didMove = objc_getAssociatedObject(self, &MOVED);
        if (possibleOffset && [possibleOffset isKindOfClass:[NSNumber class]] && (!didMove || ![didMove boolValue])) {
            arg1.origin.x += [possibleOffset intValue];
            assign(self, &MOVED, [NSNumber numberWithBool:YES]);
        }
        return ZKOrig(void, arg1);
    } else if (
       self.sublayers.count == 2 &&
       self.sublayers[0].class == NSClassFromString(@"CALayer") &&
       self.sublayers[0].cornerRadius == 5.0 &&
       self.sublayers[1].class == NSClassFromString(@"ECTextLayer")
    ) {
        // This is the part of the background and the text when scrolling
        assign(self.sublayers[0], &OVERRIDDEN_FRAME, @"background");
        assign(self.sublayers[0], &OFFSET, objc_getAssociatedObject(self.sublayers[1], &OFFSET));

        id possibleString = objc_getAssociatedObject(self.sublayers[1], &OVERRIDDEN_STRING);
        if (possibleString && [possibleString isKindOfClass:[NSString class]]) {
            arg1.size.width = getTextSize(self.sublayers[1], possibleString);
        }

        id possibleOffset = objc_getAssociatedObject(self.sublayers[1], &OFFSET);
        id didMove = objc_getAssociatedObject(self, &MOVED);
        if (possibleOffset && [possibleOffset isKindOfClass:[NSNumber class]] && (!didMove || ![didMove boolValue])) {
            arg1.origin.x += [possibleOffset intValue];
            assign(self, &MOVED, [NSNumber numberWithBool:YES]);
        }
        return ZKOrig(void, arg1);
    }

    return ZKOrig(void, arg1);
}
@end

ZKSwizzleInterface(_SRECTextLayer, ECTextLayer, CATextLayer);
@implementation _SRECTextLayer
- (void)setFrame:(CGRect)arg1 {
    @try {
        [self removeObserver:self forKeyPath:@"propertiesChanged" context:nil];
    } @catch(id anException) {}
    [self addObserver:self
                       forKeyPath:@"propertiesChanged"
                          options:NSKeyValueObservingOptionNew
                          context:nil];

    id possibleString = objc_getAssociatedObject(self, &OVERRIDDEN_STRING);
    if (possibleString && [possibleString isKindOfClass:[NSString class]]) {
        arg1.size.width = getTextSize(self, possibleString);
    }

    ZKOrig(void, arg1);
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
- (void)setFrame:(CGRect)arg1 {
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

        int offset = 0;
        for (int i = 0; i < ((NSArray*)names[monitorIndex]).count; i++) {
            if (names[monitorIndex][i][@"name"] != nil && ![names[monitorIndex][i][@"name"] isEqualToString:@""]) {
                if (i < expandedViews.count) {
                    setTextLayer(expandedViews[i], names[monitorIndex][i][@"name"]);
                }
                if (i < unexpandedViews.count) {
                    setTextLayer(unexpandedViews[i], names[monitorIndex][i][@"name"]);
                    setOffset(unexpandedViews[i], offset);
                    if ([names[monitorIndex][i][@"name"] length] != 0) {
                        double textSize = getTextSize(unexpandedViews[i], names[monitorIndex][i][@"name"]);
                        offset += (textSize - getTextLayer(unexpandedViews[i]).bounds.size.width);
                    }
                }
            } else {
                if (i < unexpandedViews.count) {
                    setOffset(unexpandedViews[i], offset);
                    if ([names[monitorIndex][i][@"name"] length] != 0) {
                        double textSize = getTextSize(unexpandedViews[i], names[monitorIndex][i][@"name"]);
                        offset += (textSize - getTextLayer(unexpandedViews[i]).bounds.size.width);
                    }
                }
            }
        }

        monitorIndex += 1;

        refreshDockView(self);
    }
    ZKOrig(void, arg1);
}

@end
