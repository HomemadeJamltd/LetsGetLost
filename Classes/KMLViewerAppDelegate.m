/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Delegate for the application.  Simply sets up the KMLViewerViewController in a window. 
 */

#import "KMLViewerAppDelegate.h"
#import "KMLViewerViewController.h"

#import <AVFoundation/AVFoundation.h>

@implementation KMLViewerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bgnd_iphone7_plus.png"]];
    [UITextView appearance].linkTextAttributes = @{ NSForegroundColorAttributeName : [UIColor blackColor] };
 
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
   // [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    
    return YES;
}


-(KMLViewerViewController*) getPlayScene
{
    KMLViewerViewController *kvc = nil;
    UIViewController* vc = [KMLViewerAppDelegate topMostController];
    
    if ( [[vc class] isSubclassOfClass:[KMLViewerViewController class]])
    {
        kvc = (KMLViewerViewController*) vc;
    }
    return kvc;
}

-(void) applicationDidBecomeActive:(UIApplication *)application
{
    KMLViewerViewController *kvc = [self getPlayScene];
    if(kvc)
    {
        [kvc skipAnimations];
        [kvc updateAppearanceOfButtonsAccodingToPlayerState];
    }
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

-(void) applicationWillEnterForeground:(UIApplication *)application
{
    KMLViewerViewController *kvc = [self getPlayScene];
    if(kvc)
    {
       // [kvc skipAnimations];
      //  [kvc updateAppearanceOfButtonsAccodingToPlayerState];
    }
}

-(void) applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
  //  KMLViewerViewController *kvc = [self getPlayScene];
   // if(kvc)
    //    [kvc skipAnimations];

}

@end
