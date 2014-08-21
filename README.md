
This tutorial will show you how to get started in minutes using the Wit SDK for iOS.
We'll create a project from scratch, but you can easily apply this guide to any existing project.
As we want to focus on the Wit SDK integration, the app will only display the user's intent and the entities Wit.AI picked up.

## Prerequisites

To follow this tutorial, you will need:

* A [Wit.AI account][wit]
* [Xcode][xcode] (this has been tested on Xcode 5.0)

## Create the Xcode project


We'll start from a basic iOS project.
In Xcode, go to `File > New > Project` or press `Cmd + Shift + N`.

Select the `Single View Application`.

![Creating a new project](https://d2n5jyo54r6d2a.cloudfront.net/docs/images/ios-tuto/new-project-1.png)

Type a name for your project.

![Setting up the new project](https://d2n5jyo54r6d2a.cloudfront.net/docs/images/ios-tuto/new-project-2.png)

## Pulling Wit SDK into your project


You can integrate the Wit SDK to your app by either using [CocoaPods][cocoapods] or using a build of the Wit.framework (see below).
We recommend that you use [CocoaPods][cocoapods]. If you're unfamiliar with it, and don't have time to learn how to use it, please see below to use the .framework file.

##### Using CocoaPods

A Wit pod is available on the central repository.

Go to your project directory, use `pod init` to create a `Podfile`.

Just add this line to your `Podfile`:

```ruby
pod 'Wit', '~> 1.2.0'
```

Now use `pod install` to pull the dependencies and create an Xcode workspace.

If you had your project (`.xcodeproj`) open in Xcode, close it and open the `.xcworkspace` file instead. From now on, you should only use the `.xcworkspace` file.

##### Using Wit.framework

Grab the latest binary from [our GitHub repo](https://github.com/wit-ai/wit-ios-sdk/releases) or build it from source.

Now, we need to add the binary and the resources (images, etc.) to our project.

In Xcode, go to `File > Add Files to "Wit Tuto"...` or press `Cmd + Opt + A`.
Select the `Wit.framework` and `Wit.bundle` files you just downloaded or built.

Your project tree should look something like this:

![Adding Wit.framework](https://d2n5jyo54r6d2a.cloudfront.net/docs/images/ios-tuto/framework.png)

The last step is to dynamically link to native Cocoa frameworks used by Wit SDK, as illustrated by the screenshot below.
To do so, go to your project settings, `Build Phases` tab, expand `Link Binary With Libraries` and add the following libraries using the **+** button.

- AVFoundation
- MobileCoreServices
- SystemConfiguration

![Linking to dynamic libraries](https://d2n5jyo54r6d2a.cloudfront.net/docs/images/ios-tuto/linking.png)

## Use Wit in your project

Wit is now available in your Xcode project.
Tell your app to use it.

To do so, add the following line to `Supporting Files/WitTuto-Prefix.pch`:

```objc
#import <Wit/Wit.h>
```

## Adding the Wit button


We'll add a recording button to the main screen of the app.
First, we need to enter our access token so Wit.AI knows what instance we are querying.
You can grab it <a href="https://wit.ai/GITHUB_ID/INSTANCE_NAME/settings" class="wit-link">from your Wit console</a>, under `Settings\Access Token`.

Edit `FOOAppDelegate.m` and add the following line to specify your access token:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [Wit sharedInstance].accessToken = @"xxx"; // replace xxx by your Wit.AI access token
  return YES;
}
```

Now we're all set to query the Wit API. As a convenience, the SDK provides a `WitMicButton` view to simply record the user's voice and request the API. Note that you can also call Wit programmatically using the `- (void) toggleCaptureVoiceIntent:(id)sender` instance method of the `Wit` class.

Adding the button to our main view is done by adding those lines to `FOOViewController.m`:

```objc
@implementation FOOViewController {
  UILabel *labelView;
}
```

```objc
- (void)viewDidLoad
{
  [super viewDidLoad];

  // set the WitDelegate object
  [Wit sharedInstance].delegate = self;

  // create the button
  CGRect screen = [UIScreen mainScreen].bounds;
  CGFloat w = 100;
  CGRect rect = CGRectMake(screen.size.width/2 - w/2, 60, w, 100);

  WITMicButton* witButton = [[WITMicButton alloc] initWithFrame:rect];
  [self.view addSubview:witButton];

  // create the label
  labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, screen.size.width, 50)];
  labelView.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:labelView];
}
```

## Acting upon Wit.AI response

Wit SDK specifies the `WitDelegate` protocol for your app to implement.

Edit `FOOViewController.h` and add `WitDelegate` to the list of protocols implemented by the `FOOViewController` class. Your @interface declaration should look something like that:

```objc
@interface FOOViewController : UIViewController <WitDelegate>
@end
```

Now, let's edit `FOOViewController.m` to actually implement the protocol. We want to display the user's intent returned by the Wit API.

```objc
- (void)witDidGraspIntent:(NSString *)intent entities:(NSDictionary *)entities body:(NSString *)body error:(NSError *)e {
    if (e) {
      NSLog(@"[Wit] error: %@", [e localizedDescription]);
      return;
    }

    labelView.text = [NSString stringWithFormat:@"intent = %@", intent];

    [self.view addSubview:labelView];
}
```

## Run your app

That's it! Just run the app in the simulator, press the microphone button and say "Wake me up at 7am".
Provided your instance has an "alarm" intent, you should see this something like this

![Running the app](https://d2n5jyo54r6d2a.cloudfront.net/docs/images/ios-tuto/result.png)

Now go check <a href="https://wit.ai/GITHUB_ID/INSTANCE_NAME/inbox" class="wit-link">your inbox</a>, the command you just said should be there. Click the wave icon next to the sentence to play the audio file.

![Wave icon](https://d2n5jyo54r6d2a.cloudfront.net/docs/images/tutorial/inbox_wave.png)

If your instance is brand new, it will need a bit of training before yielding satisfying results.
Please refer to the [relevant documentation section][training].

You can find the code for this tutorial at [https://github.com/wit-ai/wit-ios-helloworld](https://github.com/wit-ai/wit-ios-helloworld).


[wit]: https://wit.ai/
[training]: {{ site.baseurl }}/howtos/#intents-with-entities
[xcode]: https://developer.apple.com/xcode/
[cocoapods]: http://cocoapods.org
