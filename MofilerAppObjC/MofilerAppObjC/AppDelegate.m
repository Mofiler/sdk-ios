//
//  AppDelegate.m
//  MofilerAppObjC
//
//  Created by Fernando Chamorro on 10/11/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

#import "AppDelegate.h"
#import <Mofiler/Mofiler-Swift.h>

@interface AppDelegate () <MofilerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    Mofiler* mof = [Mofiler sharedInstance];
    
    [mof initializeWithAppKey:@"MY-APPKEY-HERE-IOS" appName:@"MyIosTestApplication" useLoc: true useAdvertisingId:true];
    mof.delegate = self;
    mof.url = @"mofiler.com";
    [mof addIdentityWithIdentity:@{@"username":@"johndoe"}];
    [mof addIdentityWithIdentity:@{@"name":@"john doe"}];
    [mof addIdentityWithIdentity:@{@"email":@"john@doe.com"}];
    mof.useVerboseContext = true;
    
    [mof injectValueWithNewValue:@{@"mykey1":@"myvalue1"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey2":@"myvalue2"} expirationDateInMilliseconds:[NSNumber numberWithFloat:100000000.0]];
    [mof injectValueWithNewValue:@{@"mykey3":@"myvalue3"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey4":@"myvalue4"} expirationDateInMilliseconds:[NSNumber numberWithFloat:100000000.0]];
    [mof injectValueWithNewValue:@{@"mykey5":@"myvalue5"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey6":@"myvalue6"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey7":@"myvalue7"} expirationDateInMilliseconds:[NSNumber numberWithFloat:100000000.0]];
    [mof injectValueWithNewValue:@{@"mykey8":@"myvalue8"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey9":@"myvalue9"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey10":@"myvalue10"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey11":@"myvalue11"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey12":@"myvalue12"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey13":@"myvalue13"} expirationDateInMilliseconds:nil];
    
    float valueFloat = 111111.32;
    [mof injectValueWithNewValue:@{@"mykey14":[[NSNumber numberWithFloat:valueFloat] stringValue]} expirationDateInMilliseconds:nil];
    
    
    NSDictionary* valueDictionary = @{@"key":@"value"};
    [mof injectValueWithNewValue:@{@"mykey17":valueDictionary.description} expirationDateInMilliseconds:nil];
    
    NSArray* valueArray = @[@"value1",@"value2",@"value3"];
    [mof injectValueWithNewValue:@{@"mykey18":valueArray.description} expirationDateInMilliseconds:nil];
    
    [mof flushDataToMofiler];
    
    [mof getValueWithKey:@"mykey1" identityKey:@"username" identityValue:@"johndoe"];
    [mof getValueWithKey:@"mykey1" identityKey:@"username" identityValue:@"johndoe" callback:^(id resutl, id error) {
        NSLog(@"%@", resutl);
    }];
    
    return YES;
}

- (void) responseValueWithKey:(NSString *)key identityKey:(NSString *)identityKey identityValue:(NSString *)identityValue value:(NSDictionary<NSString *,id> *)value {
    NSLog(@"%@", value);
}

- (void) errorOcurredWithError:(NSString *)error userInfo:(NSDictionary<NSString *,NSString *> *)userInfo {
    NSLog(@"%@", error);
}

@end

