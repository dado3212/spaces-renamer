//
//  spaces-renamer.m
//  spaces-renamer
//
//  Created by Alex Beals
//  Copyright 2017 Alex Beals.
//

// Renames desktops in the Mission Control Spaces bar, which WindowManager draws on macOS 27.

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>
#import <unistd.h>

static char NATIVE_STRING;
static char NATIVE_WIDTHS;
static char REQUESTED_WIDTH;
static char REQUESTED_POSITION;
static char RENAMED;
static char APPLYING;
static char RETRYING;

// WindowManager's own preferences, the domain its sandbox can read and write. The app writes the
// names and the layout here and the plugin writes its status.
#define prefsDomain @"com.apple.WindowManager"
#define namesKey @"SpacesRenamerNames"
#define monitorsKey @"SpacesRenamerMonitors"
// com.apple.spaces' spans-displays, published by the app: true when desktops are numbered across displays.
#define spansDisplaysKey @"SpacesRenamerSpansDisplays"
#define statusKey @"SpacesRenamerWindowManagerPlugin"
#define namesChangedNotification "com.alexbeals.spacesrenamer.names-changed"

static NSDictionary *customNames;
static NSArray *listOfMonitors;
static NSMutableDictionary *pluginStatus;
static NSHashTable<CATextLayer *> *knownLabels;
static NSHashTable<CALayer *> *knownBars;
static NSString *localizedDesktop, *localizedDesktopFormat;
static void (*originalSetString)(id, SEL, id);
static void (*originalSetBounds)(id, SEL, CGRect);
static void (*originalSetPosition)(id, SEL, CGPoint);
static void (*originalLayoutSublayers)(id, SEL);
static BOOL hooksInstalled;

// Helper method
static void assign(id a, void *key, id assigned) {
  objc_setAssociatedObject(a, key, assigned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static id getPreference(NSString *key) {
  return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                   (__bridge CFStringRef)prefsDomain));
}

static void saveStatus(void) {
  CFPreferencesSetAppValue((__bridge CFStringRef)statusKey,
                          (__bridge CFPropertyListRef)pluginStatus,
                          (__bridge CFStringRef)prefsDomain);
  CFPreferencesAppSynchronize((__bridge CFStringRef)prefsDomain);
}

static void loadNames(void) {
  CFPreferencesAppSynchronize((__bridge CFStringRef)prefsDomain);
  id names = getPreference(namesKey);
  id monitors = getPreference(monitorsKey);
  customNames = [names isKindOfClass:[NSDictionary class]] ? names : @{};
  listOfMonitors = [monitors isKindOfClass:[NSArray class]] ? monitors : @[];
}

// The number in WindowManager's title for a desktop, in Apple's localized format: "Desktop" for a
// display's only desktop, "Desktop 3" otherwise. Japanese/Chinese formats do not contain a space.
// Full-screen apps' titles don't match, and return 0.
static NSInteger getDesktopNumber(NSString *title) {
  if ([title isEqualToString:localizedDesktop]) return 1;
  NSRange placeholder = [localizedDesktopFormat rangeOfString:@"%@"];
  if (placeholder.location == NSNotFound) return 0;
  NSString *prefix = [localizedDesktopFormat substringToIndex:placeholder.location];
  NSString *suffix = [localizedDesktopFormat substringFromIndex:NSMaxRange(placeholder)];
  if ((prefix.length && ![title hasPrefix:prefix]) || (suffix.length && ![title hasSuffix:suffix]) ||
      title.length <= prefix.length + suffix.length) return 0;
  NSString *number = [title substringWithRange:NSMakeRange(prefix.length,
                        title.length - prefix.length - suffix.length)];
  if ([number rangeOfCharacterFromSet:
       [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]].location
      != NSNotFound) return 0;
  NSInteger value = number.integerValue;
  return value > 0 && value < 100000 ? value : 0;
}

static NSString *getDisplayUUID(CALayer *layer) {
  CALayer *root = layer;
  while (root.superlayer) root = root.superlayer;
  if (![root respondsToSelector:NSSelectorFromString(@"context")]) return nil;
  id context;
  NSNumber *display;
  @try {
    context = [root valueForKey:@"context"];
    display = [context valueForKey:@"displayId"];
  } @catch (NSException *exception) { return nil; }
  if (![display isKindOfClass:[NSNumber class]] || !display.unsignedIntValue) return nil;
  CFUUIDRef uuid = CGDisplayCreateUUIDFromDisplayID(display.unsignedIntValue);
  if (!uuid) return nil;
  NSString *value = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
  CFRelease(uuid);
  return value;
}

static NSDictionary *getMonitor(NSString *displayUUID) {
  if (!displayUUID) return listOfMonitors.count == 1 &&
    [listOfMonitors[0] isKindOfClass:[NSDictionary class]] ? listOfMonitors[0] : nil;
  CFUUIDRef main = CGDisplayCreateUUIDFromDisplayID(CGMainDisplayID());
  NSString *mainUUID = main ? CFBridgingRelease(CFUUIDCreateString(NULL, main)) : nil;
  if (main) CFRelease(main);
  for (id monitor in listOfMonitors) {
    if (![monitor isKindOfClass:[NSDictionary class]]) continue;
    id identifier = monitor[@"Display Identifier"];
    if ([identifier isEqual:displayUUID] ||
        ([identifier isEqual:@"Main"] && [displayUUID isEqual:mainUUID])) return monitor;
  }
  return nil;
}

static NSArray *getDesktops(NSDictionary *monitor) {
  id spaces = monitor[@"Spaces"];
  if (![spaces isKindOfClass:[NSArray class]]) return @[];
  NSMutableArray *desktops = [NSMutableArray array];
  for (id space in spaces) {
    if (![space isKindOfClass:[NSDictionary class]]) continue;
    id type = space[@"type"];
    if ([type isKindOfClass:[NSNumber class]] && [type integerValue] == 0)
      [desktops addObject:space];
  }
  return desktops;
}

static NSDictionary *getSpace(NSDictionary *monitor, NSInteger number) {
  // Desktops are numbered across displays when the displays share spaces.
  id spans = getPreference(spansDisplaysKey);
  NSArray *spaces;
  if ([spans respondsToSelector:@selector(boolValue)] && [spans boolValue]) {
    NSMutableArray *all = [NSMutableArray array];
    for (id candidate in listOfMonitors) {
      if ([candidate isKindOfClass:[NSDictionary class]])
        [all addObjectsFromArray:getDesktops(candidate)];
    }
    spaces = all;
  } else spaces = getDesktops(monitor);
  return number > 0 && number <= (NSInteger)spaces.count ? spaces[number - 1] : nil;
}

// The unexpanded bar: each container sits in "SpacesBar" and shows only its label. WindowManager
// sizes a label for its string, capped at 87pt, and spaces the containers for its own "Desktop N"
// titles, 22pt apart. As in the Dock version, a renamed label gets its full width and every
// container moves by the accumulated difference, keeping the gaps and centering the row.
// WindowManager lays the bar out again while it is open, so this is applied in the geometry
// setters, which record what WindowManager asked for. In the expanded bar each container is the
// root of its own window, and WindowManager already fits or truncates a name to the thumbnail.
#define kMaxLabelWidth 400

static BOOL isUnexpanded(CALayer *container) {
  return [container.name isEqualToString:@"SpacesBarPreviewContainerLayer"] &&
         [container.superlayer.name isEqualToString:@"SpacesBar"];
}

// The holder centers the label, and the current desktop's selection pill, in the container.
static CATextLayer *getHolderTextLayer(CALayer *holder) {
  for (CALayer *layer in holder.sublayers) {
    if ([layer.name isEqualToString:@"PreviewLabel"] && [layer isKindOfClass:[CATextLayer class]])
      return (CATextLayer *)layer;
  }
  return nil;
}

static CATextLayer *getTextLayer(CALayer *container) {
  for (CALayer *holder in container.sublayers) {
    CATextLayer *label = getHolderTextLayer(holder);
    if (label) return label;
  }
  return nil;
}

// The label's width in the unexpanded bar, given the width WindowManager asked for.
static CGFloat getUnexpandedWidth(CATextLayer *label, CGFloat requested) {
  if (![objc_getAssociatedObject(label, &RENAMED) boolValue]) return requested;
  return MAX(requested, MIN(ceil(label.preferredFrameSize.width), kMaxLabelWidth));
}

// How much wider the label is than the title WindowManager spaced the container for.
static CGFloat getExtraWidth(CALayer *container) {
  CATextLayer *label = getTextLayer(container);
  NSNumber *requested = objc_getAssociatedObject(label, &REQUESTED_WIDTH);
  NSDictionary<NSNumber *, NSNumber *> *natives = objc_getAssociatedObject(label, &NATIVE_WIDTHS);
  if (!requested || !natives.count || ![objc_getAssociatedObject(label, &RENAMED) boolValue]) return 0;
  NSNumber *native = natives[@(label.fontSize)];
  // Measured at another font size: scale it.
  CGFloat nativeWidth = native ? native.doubleValue
    : natives.allValues[0].doubleValue * label.fontSize / natives.allKeys[0].doubleValue;
  return getUnexpandedWidth(label, requested.doubleValue) - nativeWidth;
}

static CGFloat getRequestedX(CALayer *container) {
  NSValue *requested = objc_getAssociatedObject(container, &REQUESTED_POSITION);
  return requested ? requested.pointValue.x : container.position.x;
}

static CGFloat getOffset(CALayer *container) {
  NSMutableArray<CALayer *> *row = [NSMutableArray array];
  for (CALayer *layer in container.superlayer.sublayers) {
    if ([layer.name isEqualToString:@"SpacesBarPreviewContainerLayer"]) [row addObject:layer];
  }
  [row sortUsingComparator:^NSComparisonResult(CALayer *a, CALayer *b) {
    return [@(getRequestedX(a)) compare:@(getRequestedX(b))];
  }];
  CGFloat before = 0, own = 0, total = 0;
  BOOL reached = NO;
  for (CALayer *layer in row) {
    CGFloat extra = getExtraWidth(layer);
    total += extra;
    if (layer == container) { own = extra; reached = YES; }
    else if (!reached) before += extra;
  }
  return round(before + own / 2 - total / 2);
}

// Sets WindowManager's last requested geometry again, which the setter hooks adjust. Needed
// when the containers join the bar after WindowManager laid them out, and when names change.
static void refreshFrames(CALayer *bar) {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  for (CALayer *container in bar.sublayers) {
    if (!isUnexpanded(container)) continue;
    NSValue *position = objc_getAssociatedObject(container, &REQUESTED_POSITION);
    if (position) container.position = position.pointValue;
    CATextLayer *label = getTextLayer(container);
    NSNumber *width = objc_getAssociatedObject(label, &REQUESTED_WIDTH);
    if (!width) continue;
    CGRect bounds = label.bounds;
    bounds.size.width = width.doubleValue;
    label.bounds = bounds;
    // WindowManager puts the label and the pill at the holder's left edge: x = width / 2.
    label.position = CGPointMake(bounds.size.width / 2, label.position.y);
    for (CALayer *sibling in label.superlayer.sublayers) {
      if (![sibling.name isEqualToString:@"SpacesBarPreviewLabelSelection"]) continue;
      CGRect pill = sibling.bounds;
      pill.size.width = bounds.size.width + 20;
      sibling.bounds = pill;
      sibling.position = CGPointMake(bounds.size.width / 2, sibling.position.y);
    }
  }
  [CATransaction commit];
}

static BOOL overrideTextLayer(CATextLayer *label) {
  if (![label.name isEqualToString:@"PreviewLabel"]) return YES;
  if (objc_getAssociatedObject(label, &APPLYING)) return YES;
  NSString *original = objc_getAssociatedObject(label, &NATIVE_STRING);
  if (![original isKindOfClass:[NSString class]]) return YES;
  CALayer *container = label.superlayer.superlayer;
  if (![container.name isEqualToString:@"SpacesBarPreviewContainerLayer"]) return NO;
  NSInteger number = getDesktopNumber(original);
  // Reused layers may now show full-screen apps. Restore the host's own title.
  NSString *desired = original;
  if (number) {
    NSDictionary *monitor = getMonitor(getDisplayUUID(container));
    if (!monitor) return NO;
    id uuid = getSpace(monitor, number)[@"uuid"];
    id custom = [uuid isKindOfClass:[NSString class]] ? customNames[uuid] : nil;
    if ([custom isKindOfClass:[NSString class]] && [custom length]) desired = custom;
  }
  BOOL renamed = ![desired isEqual:original];
  if (!renamed && ![objc_getAssociatedObject(label, &RENAMED) boolValue]) return YES;
  // Setting the same string again would only redraw the label.
  if (![label.string isEqual:desired]) {
    assign(label, &APPLYING, @YES);
    // Call the original setter directly. A custom name equal to another desktop
    // title must not become the label's original identity on this recursive pass.
    originalSetString(label, @selector(setString:), desired);
    assign(label, &APPLYING, nil);
  }
  assign(label, &RENAMED, @(renamed));
  if (renamed && !pluginStatus[@"FirstLabelUpdatedAt"]) {
    pluginStatus[@"FirstLabelUpdatedAt"] = [NSDate date];
    saveStatus();
  }
  return YES;
}

static void retryOverride(CATextLayer *label, int attempts) {
  if (attempts <= 0 || objc_getAssociatedObject(label, &RETRYING)) return;
  assign(label, &RETRYING, @YES);
  __weak CATextLayer *weakLabel = label;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 60), dispatch_get_main_queue(), ^{
    CATextLayer *live = weakLabel;
    if (!live) return;
    assign(live, &RETRYING, nil);
    if (!overrideTextLayer(live)) retryOverride(live, attempts - 1);
    else if (isUnexpanded(live.superlayer.superlayer)) refreshFrames(live.superlayer.superlayer.superlayer);
  });
}

static void overrideTextLayers(CALayer *root) {
  if ([root isKindOfClass:[CATextLayer class]] && [root.name isEqualToString:@"PreviewLabel"]) {
    CATextLayer *label = (CATextLayer *)root;
    [knownLabels addObject:label];
    if (!objc_getAssociatedObject(label, &NATIVE_STRING) && [label.string isKindOfClass:[NSString class]])
      assign(label, &NATIVE_STRING, [label.string copy]);
    if (!overrideTextLayer(label)) retryOverride(label, 60);
  }
  for (CALayer *child in root.sublayers) overrideTextLayers(child);
}

static void hookedSetString(id self, SEL selector, id string) {
  CATextLayer *label = self;
  originalSetString(self, selector, string);
  if (![NSThread isMainThread] || ![label.name isEqualToString:@"PreviewLabel"]) return;
  // Only track plain host titles; attributed labels are left to WindowManager.
  if (![string isKindOfClass:[NSString class]]) {
    assign(label, &NATIVE_STRING, nil);
    return;
  }
  assign(label, &NATIVE_STRING, [string copy]);
  // The unexpanded bar is spaced for this title. Measure it before it is renamed.
  NSMutableDictionary *natives = objc_getAssociatedObject(label, &NATIVE_WIDTHS) ?: [NSMutableDictionary dictionary];
  natives[@(label.fontSize)] = @(ceil(label.preferredFrameSize.width));
  assign(label, &NATIVE_WIDTHS, natives);
  [knownLabels addObject:label];
  if (!overrideTextLayer(label)) retryOverride(label, 60);
}

static void overrideBar(CALayer *bar) {
  [knownBars addObject:bar];
  overrideTextLayers(bar);
  refreshFrames(bar);
}

static void hookedSetBounds(CALayer *self, SEL selector, CGRect bounds) {
  NSString *name = [NSThread isMainThread] ? self.name : nil;
  CALayer *holder = self.superlayer;
  if ([name isEqualToString:@"PreviewLabel"] && [self isKindOfClass:[CATextLayer class]]) {
    assign(self, &REQUESTED_WIDTH, @(bounds.size.width));
    if (isUnexpanded(holder.superlayer)) {
      bounds.size.width = getUnexpandedWidth((CATextLayer *)self, bounds.size.width);
      // WindowManager sizes the holder first, for its own width. Widen it around its center.
      CGRect holderBounds = holder.bounds;
      if (holderBounds.size.width != bounds.size.width) {
        holderBounds.size.width = bounds.size.width;
        holder.bounds = holderBounds;
      }
    }
  } else if ([name isEqualToString:@"SpacesBarPreviewLabelSelection"]) {
    CATextLayer *label = getHolderTextLayer(holder);
    if (label && isUnexpanded(holder.superlayer))
      bounds.size.width = getUnexpandedWidth(label, bounds.size.width - 20) + 20;
  }
  originalSetBounds(self, selector, bounds);
  if ([name isEqualToString:@"SpacesBar"]) overrideBar(self);
}

static void hookedSetPosition(CALayer *self, SEL selector, CGPoint position) {
  NSString *name = [NSThread isMainThread] ? self.name : nil;
  if ([name isEqualToString:@"SpacesBarPreviewContainerLayer"]) {
    assign(self, &REQUESTED_POSITION, [NSValue valueWithPoint:position]);
    if (isUnexpanded(self)) position.x += getOffset(self);
  } else if ([name isEqualToString:@"PreviewLabel"] || [name isEqualToString:@"SpacesBarPreviewLabelSelection"]) {
    // Both sit at the holder's left edge, so WindowManager asks for x = width / 2.
    CATextLayer *label = getHolderTextLayer(self.superlayer);
    if (label && isUnexpanded(self.superlayer.superlayer))
      position.x = getUnexpandedWidth(label, position.x * 2) / 2;
  }
  originalSetPosition(self, selector, position);
}

static void hookedLayoutSublayers(id self, SEL selector) {
  originalLayoutSublayers(self, selector);
  if ([NSThread isMainThread] && [[self name] isEqualToString:@"SpacesBar"]) overrideBar(self);
}

static void installHooks(void) {
  if (hooksInstalled) return;
  Method setString = class_getInstanceMethod([CATextLayer class], @selector(setString:));
  Method setBounds = class_getInstanceMethod([CALayer class], @selector(setBounds:));
  Method setPosition = class_getInstanceMethod([CALayer class], @selector(setPosition:));
  Method layoutSublayers = class_getInstanceMethod([CALayer class], @selector(layoutSublayers));
  if (!setString || !setBounds || !setPosition || !layoutSublayers) return;
  originalSetString = (void (*)(id, SEL, id))method_getImplementation(setString);
  originalSetBounds = (void (*)(id, SEL, CGRect))method_getImplementation(setBounds);
  originalSetPosition = (void (*)(id, SEL, CGPoint))method_getImplementation(setPosition);
  originalLayoutSublayers = (void (*)(id, SEL))method_getImplementation(layoutSublayers);
  method_setImplementation(setString, (IMP)hookedSetString);
  method_setImplementation(setBounds, (IMP)hookedSetBounds);
  method_setImplementation(setPosition, (IMP)hookedSetPosition);
  method_setImplementation(layoutSublayers, (IMP)hookedLayoutSublayers);
  hooksInstalled = YES;
  pluginStatus[@"HooksInstalled"] = @YES;
  saveStatus();
}

__attribute__((constructor)) static void pluginLoaded(void) {
  @autoreleasepool {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.WindowManager"] ||
        NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27) return;
    Dl_info image = {0};
    dladdr((const void *)&pluginLoaded, &image);
    pluginStatus = [@{@"HostPID": @(getpid()), @"LoadedAt": [NSDate date], @"HooksInstalled": @NO,
                      @"LibraryPath": image.dli_fname ? [NSString stringWithUTF8String:image.dli_fname] : @""}
                    mutableCopy];
    saveStatus();
    void (^setUp)(void) = ^{
      knownLabels = [NSHashTable weakObjectsHashTable];
      knownBars = [NSHashTable weakObjectsHashTable];
      NSBundle *bundle = [NSBundle mainBundle];
      localizedDesktop = [bundle localizedStringForKey:@"Desktop" value:@"Desktop" table:nil];
      localizedDesktopFormat = [bundle localizedStringForKey:@"Desktop %@" value:@"Desktop %@" table:nil];
      loadNames();
      installHooks();
      int token;
      notify_register_dispatch(namesChangedNotification, &token, dispatch_get_main_queue(), ^(int ignored) {
        (void)ignored;
        loadNames();
        for (CATextLayer *label in knownLabels.allObjects) {
          if (!overrideTextLayer(label)) retryOverride(label, 60);
        }
        for (CALayer *bar in knownBars.allObjects) refreshFrames(bar);
      });
    };
    if ([NSThread isMainThread]) setUp();
    else dispatch_async(dispatch_get_main_queue(), setUp);
  }
}
