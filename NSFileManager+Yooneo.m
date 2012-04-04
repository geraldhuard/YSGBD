//
//  NSFileManager+Yooneo.m
//  Chlorofeel
//
//  Created by Gérald HUARD on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+Yooneo.h"

@implementation NSFileManager (Yooneo)


+(NSString*) getDocumentDirectory{
    //NSFileManager *fileManager = [NSFileManager defaultManager];
    //NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

@end
