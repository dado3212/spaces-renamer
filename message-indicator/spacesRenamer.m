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

ZKSwizzleInterface(HookECBezelIconListLabelLayer, ECBezelIconListLabelLayer, CALayer)
@implementation HookECBezelIconListLabelLayer
- (void)setString:(id)arg1 maxWidth:(unsigned int)arg2 {
    NSLog(@"hackingdartmouth - layout sublayers");
    ZKOrig(void);
}
@end

// Hooks into the ChatTableCellView and hijacks the layouts to add the indicator
ZKSwizzleInterface(custom_space, WAWindow, NSObject)
@implementation custom_space
- (void)updateFrame {

    NSLog(@"hackingdartmouth - Updating frame");

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
