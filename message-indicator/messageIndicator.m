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

@interface IMMessage : NSObject
@property(retain, nonatomic) NSString *guid;
@property(readonly, nonatomic) BOOL isFromMe;
@end

@interface IMChat : NSObject
@property(readonly, nonatomic) NSString *guid;
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

@interface MessageIndicator: NSView
@property(retain, nonatomic) IMChat *chat;
@end

@implementation MessageIndicator
- (id)initWithChat:(IMChat *)chat {
    NSRect frame = CGRectMake(6, 12, 9, 9);
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = true;
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:162.0f/255.0f green:162.0f/255.0f blue:162.0f/255.0f alpha:1.0f].CGColor;
        self.layer.cornerRadius = frame.size.width * 0.5;
        self.layer.masksToBounds = true;
        
        self.chat = chat;
    }
    return self;
}

- (void)mouseDown:(NSEvent *)event {
    // Control and click
    if (event.modifierFlags & NSControlKeyMask) {
        // Saves the ID for the most recent message in the chat, to hide it
        NSString *messageGuid = self.chat.lastFinishedMessage.guid;
        NSString *chatGuid = self.chat.guid;
        
        NSUserDefaults *cachedDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *cached = [[cachedDefaults dictionaryForKey:@"cached"]  mutableCopy];
        
        if (cached == nil) {
            cached = [[NSMutableDictionary alloc] init];
        }
        cached[chatGuid] = messageGuid;
        [cachedDefaults setObject:cached forKey:@"cached"];
        [cachedDefaults synchronize];
         
        [self setHidden:true];
    }
}
@end

// Gets the indicator layer if it exists by recursing on subviews
static MessageIndicator* getIndicator(NSView *view) {
    for (NSView *subview in [view subviews]) {
        if ([subview isKindOfClass: [MessageIndicator class]]) {
            return (MessageIndicator *)subview;
        }
    }
    
    return nil;
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
    
    // Check from cache, limit only if could change needsResponse
    if (needsResponse) {
        NSString *messageGuid = ((ChatTableCellView *)self).chatDisplayController.chat.lastFinishedMessage.guid;
        NSString *chatGuid =((ChatTableCellView *)self).chatDisplayController.chat.guid;
        
        NSUserDefaults *cachedDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *cached = [[cachedDefaults dictionaryForKey:@"cached"]  mutableCopy];

        // If it needs response but the most recent is saved in the cleared caching, then don't show indicator
        if (cached && cached[chatGuid]) {
            if ([cached[chatGuid] isEqualToString:messageGuid]) {
                needsResponse = false;
            } else {
                // If it's been updated, save space by removing the chat from the array
                [cached removeObjectForKey:chatGuid];
                [cachedDefaults setObject:cached forKey:@"cached"];
                [cachedDefaults synchronize];
            }
        }
        [cached release];
    }
    
    // Get current indicator (check to see if it's already there)
    MessageIndicator *currentIndicator = getIndicator(self);
    
    // If no indicator, then create and add it
    if (currentIndicator == nil) {
        // Makes the "unresponded to" indicator
        MessageIndicator *newIndicator = [[MessageIndicator alloc] initWithChat:((ChatTableCellView *)self).chatDisplayController.chat];
        
        [self addSubview:newIndicator];
        
        currentIndicator = newIndicator;
    }
    
    // Toggle visibility based on status
    if (needsResponse) {
        currentIndicator.chat = ((ChatTableCellView *) self).chatDisplayController.chat;
        [currentIndicator setHidden:false];
    } else if (!needsResponse) {
        [currentIndicator setHidden:true];
    }
}
@end
