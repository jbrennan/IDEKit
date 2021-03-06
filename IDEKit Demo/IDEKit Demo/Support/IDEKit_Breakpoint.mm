//
//  IDEKit_Breakpoint.mm
//  IDEKit
//
//  Created by Glenn Andreas on 9/19/04.
//  Copyright 2004 by Glenn Andreas.
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Library General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//  
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Library General Public License for more details.
//  
//  You should have received a copy of the GNU Library General Public
//  License along with this library; if not, write to the Free
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import "IDEKit_Breakpoint.h"
#import "IDEKit_UniqueFileIDManager.h"
#import "IDEKit_Delegate.h"
#import "IDEKit_SrcEditViewBreakpoints.h"
#import "IDEKit_BreakpointManager.h"

NSString *IDEKit_BreakpointFile = @"IDEKit_BreakpointFile";
NSString *IDEKit_BreakpointLineNum = @"IDEKit_BreakpointLineNum";
NSString *IDEKit_BreakpointKind = @"IDEKit_BreakpointKind";
NSString *IDEKit_BreakpointData = @"IDEKit_BreakpointData";
NSString *IDEKit_BreakpointProject = @"IDEKit_BreakpointProject";
NSString *IDEKit_BreakpointTarget = @"IDEKit_BreakpointTarget";
NSString *IDEKit_BreakpointUUID = @"IDEKit_BreakpointUUID";

@implementation IDEKit_Breakpoint
+ (IDEKit_Breakpoint *) breakpointAssociatedWith:(IDEKit_UniqueID *)bpID
{
    return [bpID representedObjectForKey:@"IDEKit_Breakpoint"];
}
+ (IDEKit_Breakpoint *) breakpointFromPlist:(NSDictionary *)plist // will return existing one if possible
{
    NSString *uid = plist[IDEKit_BreakpointUUID];
    if (uid) {
	IDEKit_UniqueID *unique = [IDEKit_UniqueID uniqueIDFromString:uid];
	IDEKit_Breakpoint *retval = [self breakpointAssociatedWith: unique];
	if (retval) {
	    return retval; // we already exist in some other file probably
	}
    }
    return [[self alloc] initFromPlist: plist];
}

- (id) initFromPlist: (NSDictionary *)plist
{
    self = [super init];
    if (self) {
	myFile = [IDEKit_UniqueID uniqueIDFromString: plist[IDEKit_BreakpointFile]];
	myProj = [IDEKit_UniqueID uniqueIDFromString: plist[IDEKit_BreakpointProject]];
	myTarget = plist[IDEKit_BreakpointTarget];
	myData = plist[IDEKit_BreakpointData];
	myKind = [plist[IDEKit_BreakpointKind] intValue];
	myUnique = [IDEKit_UniqueID uniqueIDFromString: plist[IDEKit_BreakpointUUID]];
	if (!myUnique) // just to be safe
	    myUnique = [IDEKit_UniqueID uniqueID];
	[myUnique setRepresentedObject:self forKey:@"IDEKit_Breakpoint"];
    }
    return self;
}
- (NSDictionary *) asPlist
{
    if (myProj) {
	if (myTarget) {
	    return @{IDEKit_BreakpointUUID: [myUnique stringValue],
		IDEKit_BreakpointFile: [myFile stringValue],
		IDEKit_BreakpointTarget: myTarget,
		IDEKit_BreakpointProject: [myProj stringValue],
		IDEKit_BreakpointKind: @(myKind),
		IDEKit_BreakpointData: myData};
	} else {
	    return @{IDEKit_BreakpointUUID: [myUnique stringValue],
		IDEKit_BreakpointFile: [myFile stringValue],
		IDEKit_BreakpointProject: [myProj stringValue],
		IDEKit_BreakpointKind: @(myKind),
		IDEKit_BreakpointData: myData};
	}
    } else {
	return @{IDEKit_BreakpointUUID: [myUnique stringValue],
	    IDEKit_BreakpointFile: [myFile stringValue],
	    IDEKit_BreakpointKind: @(myKind),
	    IDEKit_BreakpointData: myData};
    }
}

- (id) initWithKind: (NSInteger) kind file: (IDEKit_UniqueID *)fileID line: (NSInteger) line
{
    self = [super init];
    if (self) {
	myKind = kind;
	myData = NULL;
	myBestLineNum = line;
	myFile = fileID;
	myUnique = [IDEKit_UniqueID uniqueID];
	[myUnique setRepresentedObject:self forKey:@"IDEKit_Breakpoint"];
    }
    return self;
}

- (void) dealloc
{
    [myUnique setRepresentedObject:NULL forKey:@"IDEKit_Breakpoint"];
}
- (BOOL) disabled
{
    return (myKind & IDEKit_kDisabledBreakpointFlag) ? YES : NO;
}
- (void) setDisabled: (BOOL) disabled
{
    if (disabled) 
	myKind |= IDEKit_kDisabledBreakpointFlag;
    else
	myKind &= ~IDEKit_kDisabledBreakpointFlag;
    [[IDEKit_BreakpointManager sharedBreakpointManager] redrawBreakpoint:self];
}	    
- (NSInteger) kind
{
    return myKind & IDEKit_kBreakPointKindMask;
}
- (void) setKind: (NSInteger) kind
{
    myKind = (myKind & (~IDEKit_kBreakPointKindMask)) | (kind & IDEKit_kBreakPointKindMask);
    [[IDEKit_BreakpointManager sharedBreakpointManager] redrawBreakpoint:self];
}
- (id) data
{
    return myData;
}
- (void) setData: (id) data
{
    if (data != myData) {
	myData = data;
    }
    [[IDEKit_BreakpointManager sharedBreakpointManager] redrawBreakpoint:self];
}
- (IDEKit_UniqueID *) fileID
{
    return myFile;
}
- (IDEKit_UniqueID *) projID
{
    return myProj;
}
- (IDEKit_UniqueID *) uniqueID
{
    return myUnique;
}
- (NSString *) target
{
    return myTarget;
}

- (NSInteger) lineForBuffer: (IDEKit_UniqueID *) bufferID
{
    IDEKit_SrcEditView *view = [IDEKit_SrcEditView srcEditViewAssociatedWith:bufferID];
    if (view) {
	// this is the authority of the line number
	return [view findBreakpoint: self];
    }
    // the buffer isn't an open view, so it better be my file
    if ([bufferID isEqualToID: myFile]) {
	return myBestLineNum;
    }
    return 0; // breakpoint isn't in that file
}

- (void) setFileLine: (NSInteger) line // for the master file
{
    myBestLineNum = line;
}

- (void) drawAtX: (float) midx y: (float) midy
{
    [IDEKit drawBreakpointKind: myKind x: midx y: midy];
}

@end
