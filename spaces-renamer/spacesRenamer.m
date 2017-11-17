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

#define plistPath [@"~/Library/Preferences/com.alexbeals.spacesrenamer.plist" stringByExpandingTildeInPath]
#define spacesPath [@"~/Library/Preferences/com.apple.spaces.plist" stringByExpandingTildeInPath]

@interface ECMaterialLayer : CALayer
@end

static void assign(id a, void *key, id assigned) {
    objc_setAssociatedObject(a, key, assigned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void setTextLayer(CALayer *view, NSString *newString) {
    if (view.class == NSClassFromString(@"ECTextLayer")) {
        ((CATextLayer *)view).string = newString;
        NSLog(@"hackingdartmouth - frame: %@, %@", NSStringFromRect(view.frame), [NSValue valueWithRect:view.frame]);
        assign(view, &OVERRIDDEN_STRING, newString);
        assign(view, &FRAME, [NSValue valueWithRect:view.frame]);
    } else {
        // The opacity is animated, but it's the same ONE, until you swipe off
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

ZKSwizzleInterface(_CDCALayer, CALayer, CALayer);
@implementation _CDCALayer
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

ZKSwizzleInterface(_CDECTextLayer, ECTextLayer, CATextLayer);
@implementation _CDECTextLayer
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
