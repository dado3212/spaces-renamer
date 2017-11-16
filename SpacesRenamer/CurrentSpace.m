//
//  CurrentSpace.m
//  SpacesRenamer
//
//  Created by Alex Beals on 11/16/17.
//  Copyright © 2017 cvz. All rights reserved.
//

#import "CurrentSpace.h"
#include <unistd.h>
#include <CoreServices/CoreServices.h>
#include <ApplicationServices/ApplicationServices.h>

typedef int CGSConnection;
extern OSStatus CGSGetWorkspace(const CGSConnection cid, int *workspace);
extern CGSConnection _CGSDefaultConnection(void);

@implementation CurrentSpace

- (void) someMethod {
    int spaceID = 0;
    CGSGetWorkspace(_CGSDefaultConnection(), &spaceID);

    NSLog(@"SomeMethod Ran %d", spaceID);
}

@end
