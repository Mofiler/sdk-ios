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
    
    [mof initializeWithAppKey:@"MY-APPKEY-HERE-IOS" appName:@"MyIosTestApplication" identity:@{@"username":@"johndoe"}];
    
    mof.url = @"mofiler.com";
    [mof addIdentityWithIdentity:@{@"name":@"john doe"}];
    [mof addIdentityWithIdentity:@{@"email":@"john@doe.com"}];
    mof.useLocation = false;
    mof.useVerboseContext = true;
    
    
    
    [mof flushDataToMofiler];
    
    [mof getValueWithKey:@"mykey1" identityKey:@"username" identityValue:@"johndoe"];
    [mof getValueWithKey:@"mykey1" identityKey:@"username" identityValue:@"johndoe" callback:^(id resutl, id error) {
        NSLog(@"%@", resutl);
    }];
    
    return YES;
}

@end
