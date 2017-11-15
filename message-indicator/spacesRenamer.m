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

//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert addButtonWithTitle:@"OK"];
//    [alert addButtonWithTitle:@"Cancel"];
//    [alert setMessageText:@"Delete the record?"];
//    [alert setInformativeText:@"Deleted records cannot be restored."];
//    [alert setAlertStyle:NSWarningAlertStyle];
//
//    if ([alert runModal] == NSAlertFirstButtonReturn) {
//        // OK clicked, delete the record
//        // [self deleteRecord:currentRec];
//    }
//    [alert release];

@interface WAWindow : NSObject
@property(readonly, nonatomic) NSArray *windows; // @dynamic windows;
@property(readonly, nonatomic) NSArray *descendents; // @dynamic descendents;
@property(readonly, nonatomic) NSString *displayName; // @dynamic displayName;
@end

ZKSwizzleInterface(HookWVMinimizedAndRecentsItemLayer, WVMinimizedAndRecentsItemLayer, CALayer)
@implementation HookWVMinimizedAndRecentsItemLayer
- (struct CGRect)_frameForHighlight {
    return CGRectMake(0, 0, 0, 0);
}
@end

@interface ECMaterialLayer : CALayer
{
    CALayer *_backdropLayer;
    CALayer *_tintLayer;
    NSString *_groupName;
    _Bool _reduceTransparency;
    NSUInteger _material;
}
@end

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
          @"%@",
          unexpandedViews[0].sublayers
        );
        self.superlayer.opacity = 1; // Overall top view
        // self.opacity = 0; // The expanded view
        // self.sublayers[3] has 3 children and is the only relevant thing
        self.sublayers[3].sublayers[0].sublayers[0].opacity = 0;


        unexpandedViews[0].opacity = 0.2;
    }

    if (false) {
        /*
         Prevent coloring of some layers
         Floor = Dock Background Frost Layer
         CALayer = Mission Control
         ECBezelIconListLayer = Application switcher background
         */

        if (// self.superlayer.class != NSClassFromString(@"Dock.FloorLayer")
            self.superlayer.class != NSClassFromString(@"DOCKFloorLayer")
            && self.superlayer.class != NSClassFromString(@"CALayer")
            && self.superlayer.class != NSClassFromString(@"ECBezelIconListLayer")) {

            NSUInteger _material = ZKHookIvar(self, NSUInteger, "_material");
            if (_material != 0) {
                //                CALayer *_tintLayer = ZKHookIvar(self, CALayer *, "_tintLayer");
                //                [_tintLayer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0 alpha:0] CGColor]];
                //                [_tintLayer setOpacity:0];
                //                _tintLayer.compositingFilter = nil;

                CALayer *_backdropLayer = ZKHookIvar(self, CALayer *, "_backdropLayer");
                NSColor *_newColor = NSColor.blackColor;
                [_backdropLayer setBackgroundColor:[_newColor CGColor]];
                [_backdropLayer setOpacity:40.0 / 100.0];

            }

        }
    }
}

@end

// Hooks into the ChatTableCellView and hijacks the layouts to add the indicator
ZKSwizzleInterface(custom_space, WAWindow, NSObject)
@implementation custom_space
- (void)updateFrame {

    // NSLog(@"hackingdartmouth - Updating frame");

//    NSString *str = ((WAWindow *)self).displayName;
//    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

//    [alert addButtonWithTitle:@"OK"];
//    [alert addButtonWithTitle:@"Cancel"];
//    [alert setMessageText:@"Delete the record?"];
//    [alert setInformativeText:@"Deleted records cannot be restored."];
//    [alert setAlertStyle:NSWarningAlertStyle];
//
//    if ([alert runModal] == NSAlertFirstButtonReturn) {
//        // OK clicked, delete the record
//        // [self deleteRecord:currentRec];
//    }
    // [alert release];

    ZKOrig(void);
}
@end
