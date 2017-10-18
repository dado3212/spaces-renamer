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

// Hooks into the ChatTableCellView and hijacks the layouts to add the indicator
ZKSwizzleInterface(custom_space, WAWindow, NSObject)
@implementation custom_space
+ (id)windowWithCGSWindow:(unsigned int)arg1 allowAttached:(BOOL)arg2 {
    return nil;
}
+ (id)windowWithCGSWindow:(unsigned int)arg1 {
    return nil;
}
+ (id)windowsWithOwner:(unsigned int)arg1 tags:(int [2])arg2 clearTags:(int [2])arg3 allowMinimized:(BOOL)arg4 {
    return nil;
}
+ (id)windowsWithOwner:(unsigned int)arg1 tags:(int [2])arg2 clearTags:(int [2])arg3 allowMinimized:(BOOL)arg4 orderedIn:(BOOL)arg5 {
    return nil;
}
+ (id)windowsForSwitcher:(unsigned int)arg1 {
    return nil;
}
+ (void)setMenubarAlpha:(float)arg1 {
    return;
}
+ (id)workspaceWindowsWithOwner:(unsigned int)arg1 tags:(int [2])arg2 clearTags:(int [2])arg3 space:(unsigned int)arg4 options:(int)arg5 {
    return nil;
}
+ (id)windowsObscuringDesktop:(BOOL)arg1 {
    return nil;
}
+ (id)hiddenWindows:(unsigned int)arg1 tags:(int [2])arg2 clearTags:(int [2])arg3 allowMinimized:(BOOL)arg4 {
    return nil;
}
- (id)initWithCGSWindow:(unsigned int)arg1 type:(unsigned char)arg2 {
    return nil;
}
- (id)initWithLocalWindow:(unsigned int)arg1 {
    return nil;
}

//- (id)initWithSpace:(id)arg1 title:(id)arg2 andWindows:(id)arg3 usingScaleFactor:(float)arg4 {
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert addButtonWithTitle:@"OK"];
//    [alert addButtonWithTitle:@"Cancel"];
//    [alert setMessageText:@"Delete the record?"];
//    [alert setInformativeText:@"Deleted records cannot be restored."];
//    [alert setAlertStyle:NSWarningAlertStyle];
//
//    if ([alert runModal] == NSAlertFirstButtonReturn) {
//        // OK clicked, delete the record
//       // [self deleteRecord:currentRec];
//    }
//    [alert release];
//
//    return nil; // ZKSuper(id, arg1, arg2, arg3, arg4);
//}
@end
