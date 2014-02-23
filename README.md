# Breaking changes from 0.1 to 1.0
- Notifications overhaul to match Javascript widget more closely, only notifications are now:
  - kWitNotificationAudioStart: recording started
  - kWitNotificationAudioEnd: recording ended
- Some redundant delegate methods have been removed, to keep the interface lean.
  - witDidStartAnalyzing: analysis starts when recording ends (kWitNotificationAudioEnd)
  - witDidStopAnalyzing: analysis stops when response arrives...
- Unused [Wit sharedInstance].instanceId has been removed
- Sounds are gone! Apps can play sounds when reacting to Wit events, but that's not the role of Wit SDK

# Install
## CocoaPods
    pod 'Wit', '~> 1.1.0'
## .framework & .bundle
- Drag and drop both files in project
- Link with QuartzCore, SystemConfiguration (and maybe AudioToolbox, Security, MobileCoreServices)

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

# Using Wit.framework in a project
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

# Building Wit.framework
- Build for iPhone simulator
- Build for iOS device
- Grab .framework and .bundle from Products
