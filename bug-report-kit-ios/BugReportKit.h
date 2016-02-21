//
//  BugReportKit.h
//  bug-report-kit-ios
//
//  Created by Jens Grud on 14/02/16.
//  Copyright © 2016 Jens Grud. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !DEBUG
#warning Including bug-report-kit-ios in none debug build
#endif

typedef enum : NSUInteger {
    BugKitGestureNone        = 0,
    BugKitGestureLongPress   = 1,
} BugKitGesture;

@interface BugReportKit : NSObject

+ (BugReportKit *)sharedInstance;

typedef void(^bugReporting)();
typedef void(^bugReportingFailed)(NSError *error);

- (void)enableWithEmail:(NSString *)email gesture:(BugKitGesture)gesture;
- (void)enableWithEmail:(NSString *)email gesture:(BugKitGesture)gesture subject:(NSString *)subject body:(NSString *)body began:(bugReporting)began succeeded:(bugReporting)succeeded failed:(bugReportingFailed)failed;

@end
