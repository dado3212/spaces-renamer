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
@end

ZKSwizzleInterface(custom_expose, WVDisplaySpaces, NSObject)
@implementation custom_expose
//- (_Bool)switchToSpace:(id)arg1 fromServer:(BOOL)arg2 updatePSN:(BOOL)arg3 {
//    return ZKSuper(BOOL, arg1, arg2, arg3);
//}
//- (_Bool)switchToNextSpaceForApplication:(struct CPSProcessSerNum)arg1;
//- (void)switchForWindowDrag:(_Bool)arg1;
//- (_Bool)switchToNextSpace:(_Bool)arg1;
//- (_Bool)switchToPreviousSpace:(_Bool)arg1;
//- (void)switchToLastSpace;
//- (_Bool)canAddUserSpace;
- (void)insertSpace:(id)arg1 afterSpace:(id)arg2  {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1, arg2);
}
- (void)moveSpace:(id)arg1 afterSpace:(id)arg2  {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1, arg2);
}
- (void)removeSpace:(id)arg1  {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1);
}
- (void)setCurrentSpace:(id)arg1  {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1);
}
- (void)addUserSpace:(id)arg1  {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1);
}
- (void)insertSpace:(id)arg1 atIndex:(unsigned long long)arg2  {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1, arg2);
}
- (void)addSpace:(id)arg1 {
    NSString *str = [arg1 description]; //Your text or XML
    [str writeToFile:@"/Users/alexbeals/Desktop/log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ZKOrig(void, arg1);
}
@end

// Hooks into the ChatTableCellView and hijacks the layouts to add the indicator
ZKSwizzleInterface(custom_space, WAWindow, NSObject)
@implementation custom_space
- (void)updateFrame {

//    NSString *str = [((WAWindow *)self) description]; //Your text or XML
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
