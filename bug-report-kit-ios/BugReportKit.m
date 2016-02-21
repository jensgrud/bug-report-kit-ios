//
//  BugReportKit.m
//  bug-report-kit-ios
//
//  Created by Jens Grud on 14/02/16.
//  Copyright © 2016 Jens Grud. All rights reserved.
//

#import "BugReportKit.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface BugReportKit() <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSMapTable *windowsWithGesturesAttached;

@property (nonatomic, weak) UIWindow *window;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BugKitGesture gesture;
@property (nonatomic, strong) DDFileLogger *fileLogger;
@property (nonatomic, strong) NSString *reportingAddress;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *body;

@property (nonatomic, copy) bugReporting(bugReportingBegan);
@property (nonatomic, copy) bugReporting(bugReportingSucceeded);
@property (nonatomic, copy) bugReportingFailed(bugReportingFailed);

@end

@implementation BugReportKit

+ (BugReportKit *)sharedInstance {
    static BugReportKit *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    if (self = [super init]) {
        
        self.windowsWithGesturesAttached = [NSMapTable weakToWeakObjectsMapTable];
        
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        
        self.fileLogger = [[DDFileLogger alloc] init];
        _fileLogger.rollingFrequency = 60 * 60 * 24;
        _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:_fileLogger];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeVisible:) name:UIWindowDidBecomeVisibleNotification object:nil];
    }
    
    return self;
}

#pragma mark Configure

- (void)enableWithEmail:(NSString *)email gesture:(BugKitGesture)gesture
{
    [self enableWithEmail:email gesture:gesture subject:@"" body:@"" began:nil succeeded:nil failed:nil];
}

- (void)enableWithEmail:(NSString *)email gesture:(BugKitGesture)gesture subject:(NSString *)subject body:(NSString *)body began:(bugReporting)began succeeded:(bugReporting)succeeded failed:(bugReportingFailed)failed
{
    self.enabled = YES;
    self.gesture = gesture;
    self.reportingAddress = email;
    self.subject = subject;
    self.body = body;
    
    self.bugReportingBegan = began;
    self.bugReportingSucceeded = succeeded;
    self.bugReportingFailed = failed;
    
    if (!self.gesture) {
        [[NSException exceptionWithName:NSGenericException reason:@"Cannot enable without proper gesture" userInfo:nil] raise];
    }
    
    // dispatched to next main-thread loop so the app delegate has a chance to set up its window
    dispatch_async(dispatch_get_main_queue(), ^{
        [self ensureWindow];
        [self attach:self.window];
    });
}

#pragma mark Attach

- (void)ensureWindow
{
    if (self.window) {
        return;
    }
    
    self.window = UIApplication.sharedApplication.keyWindow;
    
    if (!self.window) {
        self.window = UIApplication.sharedApplication.windows.lastObject;
    }
    if (!self.window) {
        [[NSException exceptionWithName:NSGenericException reason:@"Cannot find any application windows" userInfo:nil] raise];
    }
    if (!self.window.rootViewController){
        [[NSException exceptionWithName:NSGenericException reason:@"Requires a rootViewController set on the window" userInfo:nil] raise];
    }
}

- (void)windowDidBecomeVisible:(NSNotification *)notification
{
    UIWindow *newWindow = (UIWindow *)notification.object;
    if (!newWindow || ![newWindow isKindOfClass:UIWindow.class]) {
        return;
    }
    [self attach:newWindow];
}

- (void)attach:(UIWindow *)window
{
    if (!self.enabled) {
        return;
    }
    
    if ([self.windowsWithGesturesAttached objectForKey:window]) {
        return;
    }
    
    [self.windowsWithGesturesAttached setObject:window forKey:window];
    
    UIGestureRecognizer *gesture;
    
    switch (self.gesture) {
        case BugKitGestureLongPress:{
            gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognized:)];
            ((UILongPressGestureRecognizer*) gesture).minimumPressDuration = 3.0;
        }
            break;
        default:
            break;
    }
    
    window.userInteractionEnabled = YES;
    window.gestureRecognizers = @[gesture];
}

#pragma mark Gestures

- (void)gestureRecognized:(UIGestureRecognizer *)sender
{    
    if (sender.state == UIGestureRecognizerStateRecognized) {
        
        [self report];
        
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        
        if (self.bugReportingBegan) {
            self.bugReportingBegan();
        }
    }
}

#pragma mark Reporting

- (void)report {
    
    if (![MFMailComposeViewController canSendMail]) {
        return;
    }
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    [mailComposer.navigationBar setTintColor:[UIColor whiteColor]];
    mailComposer.mailComposeDelegate = self;
    
    [mailComposer setSubject:self.subject];
    [mailComposer setMessageBody:self.body isHTML:NO];
    
    NSData *noteData = [NSData dataWithContentsOfFile:self.fileLogger.currentLogFileInfo.filePath];
    
    [mailComposer setToRecipients:@[self.reportingAddress]];
    [mailComposer addAttachmentData:[self screenshot] mimeType:@"image/png" fileName:@"screenshot.png"];
    [mailComposer addAttachmentData:noteData mimeType:@"text/plain" fileName:@"console.log"];
    
    [self.window.rootViewController presentViewController:mailComposer animated:YES completion:^{
        
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            if (self.bugReportingSucceeded) {
                self.bugReportingSucceeded();
            }
            break;
        case MFMailComposeResultFailed:
            if (self.bugReportingFailed) {
                self.bugReportingFailed(error);
            }
            break;
        default:
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark Data

- (NSData *)screenshot
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(self.window.bounds.size, NO, [UIScreen mainScreen].scale);
    }
    else {
        UIGraphicsBeginImageContext(self.window.bounds.size);
    }
    
    [self.window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return UIImagePNGRepresentation(image);
}

@end
