//
//  SpacesRenamerBridge.h
//  SpacesRenamer
//
//  Created by Alex Beals on 3/28/18.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

#ifndef SpacesRenamerBridge_h
#define SpacesRenamerBridge_h

#import <Foundation/Foundation.h>

typedef int CGSConnectionID;

int _CGSDefaultConnection();
id CGSCopyManagedDisplaySpaces(int conn);

CGSConnectionID CGSMainConnectionID(void);
extern long CGSManagedDisplayGetCurrentSpace(CGSConnectionID cid, CFStringRef uuid);

#endif /* SpacesRenamerBridge_h */
