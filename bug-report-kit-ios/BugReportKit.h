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

@property (nonatomic, strong) NSArray *reportingAddresses;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *body;

typedef void(^bugReporting)(BugReportKit *instance);
typedef void(^bugReportingFailed)(BugReportKit *instance, NSError *error);

- (void)enableWithEmails:(NSArray *)emails gesture:(BugKitGesture)gesture;
- (void)enableWithEmails:(NSArray *)emails gesture:(BugKitGesture)gesture subject:(NSString *)subject body:(NSString *)body began:(bugReporting)began succeeded:(bugReporting)succeeded failed:(bugReportingFailed)failed;

@end
