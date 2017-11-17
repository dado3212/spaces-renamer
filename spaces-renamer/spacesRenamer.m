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

#define plistPath [@"~/Library/Preferences/com.alexbeals.spacesrenamer.plist" stringByExpandingTildeInPath]
#define spacesPath [@"~/Library/Preferences/com.apple.spaces.plist" stringByExpandingTildeInPath]

@interface ECMaterialLayer : CALayer
@end

static void setTextLayer(CALayer *view, NSString *newString) {
    if (view.class == NSClassFromString(@"ECTextLayer")) {
        ((CATextLayer *)view).string = newString;
        objc_setAssociatedObject(
            view,
            &OVERRIDDEN_STRING,
            newString,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC
        );
        NSLog(@"hackingdartmouth - %@", NSStringFromRect(view.bounds));
//        self.viewNo2.frame.size.width, self.viewNo2.frame.size.height);
//        self.customLayer = [CALayer layer];
//        self.customLayer.frame = viewNo2.frame;
//        self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
//        [self.view.layer addSublayer:self.customLayer];
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

static NSString *pad(NSString *string, int length) {
    if ([string length] >= length) { return string; }
    int add = length - [string length];
    if (add % 2 == 0) {
        return [NSString stringWithFormat:@"%*c%@%*c", add / 2, ' ', string, add / 2, ' '];
    } else {
        return [NSString stringWithFormat:@"%*c%@%*c", (add + 1) / 2, ' ', string, (add - 1) / 2, ' '];
    }
}

ZKSwizzleInterface(_CDECTextLayer, ECTextLayer, CATextLayer);
@implementation _CDECTextLayer


- (void)setBounds:(CGRect)arg1 {
    ZKOrig(void, arg1);

    @try {
        [self removeObserver:self forKeyPath:@"propertiesChanged" context:nil];
    } @catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    [self addObserver:self
                       forKeyPath:@"propertiesChanged"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
}

-(void)dealloc {
    @try {
        [self removeObserver:self forKeyPath:@"propertiesChanged" context:nil];
    } @catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    ZKOrig(void);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"hackingdartmouth - observe: %@, %@", self.string, change);

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
        NSLog(@"hackingdartmouth bounds - %@", NSStringFromRect(arg1));

        NSArray<CALayer *> *unexpandedViews = self.sublayers[3].sublayers[0].sublayers;
        NSArray<CALayer *> *expandedViews = self.sublayers[3].sublayers[1].sublayers;

        // Get all of the names
        NSMutableArray* names = getNamesFromPlist();
        // Change them if set
        for (int i = 0; i < names.count; i++) {
            if (names[i] != nil && ![names[i] isEqualToString:@""]) {
                setTextLayer(expandedViews[i], pad(names[i], 1));
                setTextLayer(unexpandedViews[i], pad(names[i], 1));
            }
        }
    }
}

@end
