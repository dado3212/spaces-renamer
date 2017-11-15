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

@interface ECMaterialLayer : CALayer
{
    CALayer *_backdropLayer;
    CALayer *_tintLayer;
    NSString *_groupName;
    _Bool _reduceTransparency;
    NSUInteger _material;
}
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

static void textChange(CALayer *view, NSString *newString, NSString *path) {
    // Apply to self
    if (view.class == NSClassFromString(@"ECTextLayer")) {
        NSLog(@"hackingdartmouth - Found ECTextLayer with path %@", path);
        ((CATextLayer *)view).string = newString;
    }
    // Apply to all children
    for (int i = 0; i < view.sublayers.count; i++) {
        textChange(view.sublayers[i], newString, [NSString stringWithFormat:@"%@%d", path, i]);
    }
}

ZKSwizzleInterface(_CDECMaterialLayer, ECMaterialLayer, CALayer);
@implementation _CDECMaterialLayer

- (void)setBounds:(CGRect)arg1 {
    ZKOrig(void, arg1);

    NSLog(@"hackingdartmouth - setting bounds: %@", self.superlayer.class);

    if (self.superlayer.class == NSClassFromString(@"CALayer") && self.sublayers.count == 4) {
        // --- SUBLAYERS ---
        // "<CABackdropLayer: 0x608000224240>", -> The background color
        // "<CALayer: 0x6080002298a0>", -> unknown
        // "<CALayer: 0x6080002207c0>", -> unknown
        // "<CALayer: 0x608000225e20>" -> THANK GOD EVERYTHING RELEVANT

        // "<CALayer"> -> The un-zoomed text
        // "<CALayer"> -> Everything else? (has 7 children layers [7 desktops!!!])
        // "<CALayer"> -> Really unclear

        NSArray<CALayer *> *unexpandedViews = self.sublayers[3].sublayers[0].sublayers;
        NSArray<CALayer *> *expandedViews = self.sublayers[3].sublayers[1].sublayers;

        // Super layer only has it as its sublayer
        NSLog(
          @"hackingdartmouth sublayers - %@",
          expandedViews[0].sublayers[0].sublayers
        );

        setTextLayer(expandedViews[0], @"1 Opened");
        setTextLayer(unexpandedViews[0], @"1 Closed");

        // Set the text layer to be "Hello" for now.
        // setTextLayer(unexpandedViews[0], @"Hello");

        // See if can cast to WVSpacesItemLayer from the expandedViews (seemingly no)
    }
}

@end
