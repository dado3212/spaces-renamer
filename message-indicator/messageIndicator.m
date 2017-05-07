//
//  message-indicator.m
//  message-indicator
//
//  Created by Alex Beals
//  Copyright 2017 Alex Beals.
//

@import AppKit;
#import "ZKSwizzle.h"
#import <QuartzCore/QuartzCore.h>

static char response_indicator;

@interface IMMessage : NSObject
@property(readonly, nonatomic) BOOL isFromMe;
@end

@interface IMChat : NSObject
@property(readonly, nonatomic) IMMessage *lastFinishedMessage;
@property(readonly, nonatomic) NSArray *participants;
@end

@interface SOChatDisplayController : NSObject
@property(retain, nonatomic) IMChat *chat;
@end

@interface ChatTableCellView: NSObject
@property(readonly) SOChatDisplayController *chatDisplayController;
@property(retain) NSView *unreadIndicator;
@end

// Gets the indicator layer if it exists by recursing on subviews
static NSView* getIndicator(NSView *view) {
    for (NSView *subview in [view subviews]) {
        if ([subview isKindOfClass: [NSView class]]) {
            if ([objc_getAssociatedObject(subview, &response_indicator) isEqualToString:@"RESPONSE"]) {
                return (NSView *)subview;
            }
        }
    }
    
    return nil;
}

// Creates an indicator NSView (gray, slightly below)
static NSView *indicator() {
    NSView *indicator = [[NSView alloc] initWithFrame: CGRectMake(6, 12, 9, 9)];
    
    indicator.wantsLayer = true;
    indicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:162.0f/255.0f green:162.0f/255.0f blue:162.0f/255.0f alpha:1.0f].CGColor;
    indicator.layer.cornerRadius = 5;
    indicator.layer.masksToBounds = true;
    
    return indicator;
}

// Hooks into the ChatTableCellView and hijacks the layouts to add the indicator
ZKSwizzleInterface(custom_cellView, ChatTableCellView, NSTableCellView)
@implementation custom_cellView

// Ran when the summary for a cell changes (new message either direction)
- (void)_updateSummary {
    ZKOrig(void);
    
    // Indicator if:
    //  - you weren't the last person to send a message
    //  - it's not a group message
    bool needsResponse = !((ChatTableCellView *)self).chatDisplayController.chat.lastFinishedMessage.isFromMe && ((ChatTableCellView *)self).chatDisplayController.chat.participants.count == 1;
    
    // Get current indicator (check to see if it's already there)
    NSView *currentIndicator = getIndicator(self);
    
    // If no indicator, then create and add it
    if (currentIndicator == nil) {
        // Makes the "unresponded to" indicator
        NSView *newIndicator = indicator();
        
        // Add attribute to identify it
        objc_setAssociatedObject(newIndicator, &response_indicator, @"RESPONSE", OBJC_ASSOCIATION_RETAIN);
        
        [self addSubview:newIndicator];
        
        currentIndicator = newIndicator;
    }
    
    // Toggle visibility based on status
    if (needsResponse) {
        [currentIndicator setHidden:false];
    } else if (!needsResponse) {
        [currentIndicator setHidden:true];
    }
}

@end
