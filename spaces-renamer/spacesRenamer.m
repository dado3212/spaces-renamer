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
static char OVERRIDDEN_WIDTH;
static char OFFSET;
static char MOVED;
static char TYPE;

#define customNamesPlist [@"~/Library/Containers/com.alexbeals.spacesrenamer/com.alexbeals.spacesrenamer.plist" stringByExpandingTildeInPath]
#define listOfSpacesPlist [@"~/Library/Containers/com.alexbeals.spacesrenamer/com.alexbeals.spacesrenamer.currentspaces.plist" stringByExpandingTildeInPath]
#define spacesPath [@"~/Library/Preferences/com.apple.spaces.plist" stringByExpandingTildeInPath]

int monitorIndex = 0;

@interface ECMaterialLayer : CALayer
@end

// Invokes setFrame on the modified children so that they don't change positions on swiping
// between different spaces.  Called on the master parent ECMaterialLayer at the end of
// the override calculations in setFrame
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

    for (int i = 0; i < expandedViews.count; i++) {
      [expandedViews[i].sublayers[0] setFrame:expandedViews[i].sublayers[0].frame];
      [expandedViews[i].sublayers[0].sublayers[0] setFrame:expandedViews[i].sublayers[0].sublayers[0].frame];
    }
  }
}

// Helper method
static void assign(id a, void *key, id assigned) {
  objc_setAssociatedObject(a, key, assigned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Gets the ECTextLayer child from a starting view
// Good for when you don't care whether it's selected or not
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

// Given a view, sets the OFFSET variable for the text layer's parent, and siblings
// if 'modify' is TRUE, it will add the OFFSET variables, otherwise it will overwrite it
static void setOffset(CALayer *view, double offset, bool modify) {
  CATextLayer *textLayer = getTextLayer(view);

  if (textLayer != nil) {
    CALayer *parent = textLayer.superlayer;
    if (modify) {
      id possibleOffset = objc_getAssociatedObject(parent, &OFFSET);
      if (possibleOffset && [possibleOffset isKindOfClass:[NSNumber class]]) {
        assign(parent, &OFFSET, [NSNumber numberWithDouble:offset + [possibleOffset doubleValue]]);
      }
    } else {
      assign(parent, &OFFSET, [NSNumber numberWithDouble:offset]);
    }
    for (int i = 0; i < parent.sublayers.count; i++) {
      if (modify) {
        id possibleOffset = objc_getAssociatedObject(parent.sublayers[i], &OFFSET);
        if (possibleOffset && [possibleOffset isKindOfClass:[NSNumber class]]) {
          assign(parent.sublayers[i], &OFFSET, [NSNumber numberWithDouble:offset + [possibleOffset doubleValue]]);
        }
      } else {
        assign(parent.sublayers[i], &OFFSET, [NSNumber numberWithDouble:offset]);
      }
    }
  }
}

// Finds the text layer, and sets the overridden string and width properties
// to the text layer, its parent, and its siblings.
// Additionally sets the type for determining centering behavior
static void overrideTextLayer(CALayer *view, NSString *newString, double width, NSString *type) {
  CATextLayer *textLayer = getTextLayer(view);

  if (textLayer != nil) {
    textLayer.string = newString;
    CALayer *parent = textLayer.superlayer;
    assign(parent, &OVERRIDDEN_STRING, newString);
    assign(parent, &TYPE, type);
    if (width != -1) {
      assign(parent, &OVERRIDDEN_WIDTH, [NSNumber numberWithDouble:width]);
    }
    for (int i = 0; i < parent.sublayers.count; i++) {
      assign(parent.sublayers[i], &OVERRIDDEN_STRING, newString);
      assign(parent, &TYPE, type);
      if (width != -1) {
        assign(parent.sublayers[i], &OVERRIDDEN_WIDTH, [NSNumber numberWithDouble:width]);
      }
    }
  }
}

// Gets the text area, and renders how large it would be with the new dimensions
// Uses this for calculating how far they should be offset by
static double getTextSize(CALayer *view, NSString *string) {
  double textSize = -1;
  CATextLayer *textLayer = getTextLayer(view);
  if (textLayer != nil) {
    CFRange textRange = CFRangeMake(0, string.length);
    CFMutableAttributedStringRef attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, string.length);
    CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), (CFStringRef) string);
    CFAttributedStringSetAttribute(attributedString, textRange, kCTFontAttributeName, ((CATextLayer *)textLayer).font);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    CFRange fitRange;
    CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, textRange, NULL, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX), &fitRange);
    CFRelease(framesetter);
    CFRelease(attributedString);
    return frameSize.width;
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
- (void)setBounds:(CGRect)arg1 {

  return ZKOrig(void, arg1);
}
- (void)setFrame:(CGRect)arg1 {
  id possibleWidth = objc_getAssociatedObject(self, &OVERRIDDEN_WIDTH);
  if (possibleWidth && [possibleWidth isKindOfClass:[NSNumber class]] && self.class == NSClassFromString(@"CALayer")) {
    arg1.size.width = [possibleWidth doubleValue] + 20;
  }

  int textIndex = self.sublayers.lastObject.class == NSClassFromString(@"ECTextLayer")
  ? (int)self.sublayers.count - 1
  : -1;

  if (textIndex != -1) {
    id possibleWidth = objc_getAssociatedObject(self.sublayers[textIndex], &OVERRIDDEN_WIDTH);
    if (possibleWidth && [possibleWidth isKindOfClass:[NSNumber class]]) {
      arg1.size.width = [possibleWidth doubleValue];
    }

    id possibleType = objc_getAssociatedObject(self, &TYPE);
    if (possibleType && [possibleType isEqualToString:@"expanded"]) {
      // Always just center in the parent view
      arg1.origin.x = self.superlayer.frame.size.width / 2 - arg1.size.width / 2;
    } else {
      id possibleOffset = objc_getAssociatedObject(self.sublayers[textIndex], &OFFSET);
      id didMove = objc_getAssociatedObject(self, &MOVED);
      // Only change the offsets once
      if (possibleOffset && [possibleOffset isKindOfClass:[NSNumber class]] && (!didMove || ![didMove boolValue])) {
        arg1.origin.x += [possibleOffset doubleValue];

        assign(self, &MOVED, [NSNumber numberWithBool:YES]);
      }
    }


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

  id possibleWidth = objc_getAssociatedObject(self, &OVERRIDDEN_WIDTH);
  if (possibleWidth && [possibleWidth isKindOfClass:[NSNumber class]]) {
    arg1.size.width = [possibleWidth doubleValue];
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

    int numMonitors = MAX((int)unexpandedViews.count, (int)expandedViews.count);

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

    double unexpandedOffset = 0;
    for (int i = 0; i < ((NSArray*)names[monitorIndex]).count; i++) {
      NSString *name = names[monitorIndex][i][@"name"];
      // It's overridden
      if (name != nil && ![name isEqualToString:@""]) {
        // Expanded
        if (i < expandedViews.count) {
          double textSize = getTextSize(expandedViews[i], name);
          // Don't have the expanded view string overlap other ones
          overrideTextLayer(expandedViews[i], name, MIN(textSize, expandedViews[i].frame.size.width), @"expanded");
        }
        // Unexpanded
        if (i < unexpandedViews.count) {
          double textSize = getTextSize(unexpandedViews[i], name);
          overrideTextLayer(unexpandedViews[i], name, textSize, @"unexpanded");
          setOffset(unexpandedViews[i], unexpandedOffset, false);
          unexpandedOffset += (textSize - getTextLayer(unexpandedViews[i]).bounds.size.width);
        }
      } else {
        if (i < unexpandedViews.count) {
          setOffset(unexpandedViews[i], unexpandedOffset, false);
        }
      }
    }

    // Make sure that it's centered in the bar when unexpanded
    for (int i = 0; i < ((NSArray*)names[monitorIndex]).count; i++) {
      if (i < unexpandedViews.count) {
        setOffset(unexpandedViews[i], -unexpandedOffset/2, true);
      }
    }

    monitorIndex += 1;

    // So that it doesn't change sizes on switching spaces
    refreshDockView(self);
  }
  ZKOrig(void, arg1);
}

@end
