//
//  AppDelegate.m
//  DSRestAPIHelper_iOS_Sample
//
//  Created by nik on 05/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

#import "AppDelegate.h"
#import "DSAPIHelper.h"
#import "APIConfig.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    
    NSString* action = [[url absoluteString] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@?event=",returnURI] withString:@""];
    NSLog(@"**** url %@ action  %@ absolute %@ *****",url,action,[url absoluteString]);
    
    NSString* message = @"";
    
    if([action rangeOfString:@"cancel" options:NSCaseInsensitiveSearch].location!=NSNotFound) {
         message = @"Recipient didn't signed/send the document.";
    }else if([action rangeOfString:@"signing_complete" options:NSCaseInsensitiveSearch].location!=NSNotFound){
         message = @"Recipient signed the document.";
    } else     if([action rangeOfString:@"decline" options:NSCaseInsensitiveSearch].location!=NSNotFound) {
         message = @"Recipient declined the document.";
    }
    
    [self showMessage:message withDelegate:nil andButtonTitles:@[@"OK"]];
    return YES;
}

- (void)showMessage:(NSString*)message withDelegate:(id)delegate andButtonTitles:(NSArray*)buttonTitles{
    NSString* otherButtonTitle = nil;
    if(buttonTitles.count>1) {
        otherButtonTitle = buttonTitles[1];
    }
    UIAlertView* anAlert = [[UIAlertView alloc] initWithTitle:kAppName message:message delegate:delegate cancelButtonTitle:buttonTitles[0] otherButtonTitles:otherButtonTitle, nil];
    [anAlert show];
}


@end
