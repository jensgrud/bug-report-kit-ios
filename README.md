> Bug reporting kit for iOS with logging and screenshots

## Install
Download manually or install via CocoaPods:
```bash
pod 'bug-report-kit-ios', :git => 'https://github.com/jensgrud/bug-report-kit-ios.git'
```

## Setup and usage
Initialize with gesture of choice
```obj-c
#ifdef DEBUG

    [[BugReportKit sharedInstance] enableWithEmails:@[@"info@example.com"] gesture:BugKitGestureLongPress subject:@"" body:@"" began:^(BugReportKit *instance) {
        
        // Overide subject and body
        instance.subject = @"Dynamic header";
        instance.body = @"Dynamic body";
        
    } succeeded:^(BugReportKit *instance) {
        
        // Successfully sent
        
    } failed:^(BugReportKit *instance, NSError *error) {
        
        // Failed
    }];
    
#endif
```

### Reporting
- Currently only supporting email for reporting. 
- Be sure to only include in DEBUG builds unless you know what you are doing.

### Logging
Logging via [CocoaLumberJack](https://github.com/CocoaLumberjack/CocoaLumberjack).
