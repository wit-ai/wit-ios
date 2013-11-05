# Install
## CocoaPods
    pod 'Wit', '~> 0.1.0'
## .framework
Link with QuartzCore, AVFoundation, MobileCoreServices, SystemConfiguration, Security

## FooViewController.h
    @interface FooController : UIViewController <WitDelegate>
    @end

## FooViewController.m
    WITMicButton* witButton = [[WITMicButton alloc] initWithFrame:...];
    [self.view addSubview:witButton];

    [Wit sharedInstance].accessToken = @"xxx";
    [Wit sharedInstance].delegate = self;

    - (void)witDidGraspIntent:(NSString *)intent entities:(NSDictionary *)entities body:(NSString *)body error:(NSError *)e {
    }

# Notifications
    kWitNotificationUploadProgress = userInfo.progress shows current upload progress
    kWitNotificationRecordingStarted = recording just started
    kWitNotificationRecordingCompleted = recording stopped (userInfo.error shows error, if any)
    kWitNotificationResponseReceived = received Wit API response

# Wit.framework
cf. https://github.com/jverkoey/iOS-Framework#first_parties

1. `git submodule update --init`
2. Add the framework project to your application project
3. Make the framework static library target a dependency
4. Link your application with the framework static library
5. Import the framework header (and add to resources)
6. In dependent project, link to dynamic libs
    - AVFoundation `# audio recording`
    - QuartzCore `# drawing`
9. Build and test!
