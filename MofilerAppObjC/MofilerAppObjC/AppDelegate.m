//
//  AppDelegate.m
//  MofilerAppObjC
//
//  Created by Fernando Chamorro on 10/11/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

#import "AppDelegate.h"
#import <Mofiler/Mofiler-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    Mofiler* mof = [Mofiler sharedInstance];
    [mof testDevice];
    
    return YES;
}


@end
