//
//  GeoAppDelegate.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoAppDelegate.h"
#import "GeoDatabase.h"
#import "GeoUtils.h"
#import "GeoSlidesVC.h"
#import "GeoSettingsVC.h"
#import "GeoNavController.h"
#import "InAppPurchaseUtils.h"
#import "CoreDataMigration.h"
#import "GeoCache.h"
#import "NotificationUtils.h"

@interface GeoAppDelegate ()
@end

@implementation GeoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"in application:didFinishLaunchingWithOptions:");
    // Override point for customization after application launch.

    // Ohne das INIT werden die Events nicht registriert... das muss unbedingt VOR dem Laden der Datenbank passieren!
    [GeoCache shared];

    // Die Location Services als solche brauchen wir für diverse Sachen, wenn die App im Vordergrund agiert.
    // Sobald sie wieder in den Hintergrund geht, lassen wir nur die SLC laufen.
    [[GeoUtils sharedInstance] start];

    // Falls gewünscht, aktivieren wir SLC... also Significant Location Changes.
    if ([[GeoDatabase sharedInstance] useAutoCheckin]) {
        [[GeoUtils sharedInstance] startSLC];
        // Das startet indirekt auch die GeoFences, sobald das erste SLC rein kommt...
    }

    UIColor *tint = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    if (iOS7) {
        [UISearchBar appearance].tintColor = tint;
        [UISwitch appearance].tintColor = tint;
        [UISwitch appearance].onTintColor = tint;
        [UIStepper appearance].tintColor = tint;
    }

    [self.window makeKeyAndVisible]; // Das darf nicht fehlen...
    
    if ([[[GeoDatabase sharedInstance] checkins] count] == 0 && [[[GeoDatabase sharedInstance] locations] count] == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome to GeoLicious!",nil)
                                    message:NSLocalizedString(@"You may start with a check-in via the top button or search for a location on the map... or visit the settings for a detailed introduction.",nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Let's start!",nil) otherButtonTitles:nil] show];
    }
    else if ([[GeoDatabase sharedInstance] isNewVersion]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GeoLicious Update!",nil)
                                    message:NSLocalizedString(@"See what's new...",nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Close",nil)
                          otherButtonTitles:NSLocalizedString(@"Show",nil), nil] show];
    }

    
    [[GeoDatabase sharedInstance] testSettings];
    
    // Nur dann, wenn das auch gewollt ist... spart einen Dialog beim ersten Install!
    if ([[GeoDatabase sharedInstance] useNotifications]) {
        [[GeoDatabase sharedInstance] registerActions];
    }
    
    // Das prüfen ich nur bei neuen Einträgen... nicht sofort beim Start!
    // [[GeoDatabase sharedInstance] limitReached];

    [InAppPurchaseUtils sharedInstance];
   
    // Startet die Migration... wird aber nur 1x ausgeführt... dann erst wieder, wenn die Datenbank gelöscht wird.
    // [CoreDataMigration start];
    
    NSLog(@"done!");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    // Nur dann, wenn das auch gewollt ist... spart einen Dialog beim ersten Install!
    if ([[GeoDatabase sharedInstance] useIconBadge]) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }

    NSLog(@"in applicationWillResignActive:");
    [[GeoDatabase sharedInstance] dailyBackup];
    
    // Auch das ist hier eigentlich unnötig... das ist ja schon passiert.
    // [[GeoDatabase sharedInstance] save];
    
    // Das lassen wir erst mal weg... es dauert oft länger als die 10s, die der App noch bleiben...
    // [[GeoDatabase sharedInstance] updateGeoFence];
    
    NSLog(@"done!");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"in applicationDidEnterBackground:");
    
    // Die Location Services als solche brauchen wir für diverse Sachen, wenn die App im Vordergrund agiert.
    // Sobald sie wieder in den Hintergrund geht, lassen wir nur die SLC laufen.
    [[GeoUtils sharedInstance] stop];

    // Nur zum testen...
    // [[GeoDatabase sharedInstance] testActions];
    // [NotificationUtils test];
    // ECG: [[GeoDatabase sharedInstance] didEnter:@"EE2863A6-9E69-46D4-95CA-883AB807C2E5"];


}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"in applicationWillEnterForeground:");
    // Nur dann, wenn das auch gewollt ist... spart einen Dialog beim ersten Install!
    if ([[GeoDatabase sharedInstance] useIconBadge]) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }

    // Die Location Services als solche brauchen wir für diverse Sachen, wenn die App im Vordergrund agiert.
    // Sobald sie wieder in den Hintergrund geht, lassen wir nur die SLC laufen.
    [[GeoUtils sharedInstance] start];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"in applicationDidBecomeActive:");
    // Nur dann, wenn das auch gewollt ist... spart einen Dialog beim ersten Install!
    if ([[GeoDatabase sharedInstance] useIconBadge]) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }

    // Wenn wir iCloud Drive nutzen, müssen wir jetzt sicherheitshalber die Daten neu laden...
    if ([[GeoDatabase sharedInstance] useCloudDrive]) [GeoDatabase reload];
    
    // Wir kümmern uns noch mal um Foursquare... bei jedem neuen Öffnen der App!
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GeoDatabase sharedInstance] updateFoursquare];
    });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"in applicationWillTerminate:");
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"in application:openURL:sourceApplication:annotation:");
    NSLog(@"%@",sourceApplication);
    
    // geolicious://foursquare?code=TC0LYZVCQROPWXUB5V1HKBVO101MEQ2I3RUMU3YL14HMT0KP#_=_
    if ([sourceApplication isEqualToString:@"com.naveenium.foursquare"] ||
        [sourceApplication isEqualToString:@"com.apple.mobilesafari"] ||
        [sourceApplication isEqualToString:@"com.apple.SafariViewService"]) {
        [[GeoDatabase sharedInstance] finishFoursquare:url];
        return YES;
    }

    // Database "open in"...
    if (url != nil && [url isFileURL]) {
        if ([[url pathExtension] isEqualToString:@"db"]) {
            [[GeoDatabase sharedInstance] askForImport:url];
        }
    }

    return YES;
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    // NOP
}

- (void) application: (UIApplication *) application
         handleActionWithIdentifier: (NSString *) identifier
         forLocalNotification:(UILocalNotification *)notification
         completionHandler:(void(^)())completionHandler
{
    if ([notification.category isEqualToString:ACTIONS_DEFAULT]) {
        if ([identifier isEqualToString:ACTION_DISCARD]) {
            [[GeoDatabase sharedInstance] notificationDiscard:[notification.userInfo objectForKey:@"uuid"]];
        }
        else if ([identifier isEqualToString:ACTION_CHECKOUT]) {
            [[GeoDatabase sharedInstance] notificationCheckout:[notification.userInfo objectForKey:@"uuid"]];
        }
    }
    
    // Am Ende muss aufgeräumt werden!
    completionHandler();
}


#pragma mark - UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.numberOfButtons == 2) {
        if (buttonIndex == 1) {
            if (iPad) {
                UISplitViewController *svc = (UISplitViewController *) self.window.rootViewController;
                UITabBarController *tbc = [svc.viewControllers objectAtIndex:0];
                tbc.selectedIndex = 2;
                UIViewController *vvc = ((GeoNavController *) tbc.selectedViewController).visibleViewController;
                [vvc performSegueWithIdentifier:@"Version" sender:self];
            }
            else {
                UITabBarController *tbc = (UITabBarController *) self.window.rootViewController;
                tbc.selectedIndex = 3;
                UIViewController *vvc = ((GeoNavController *) tbc.selectedViewController).visibleViewController;
                [vvc performSegueWithIdentifier:@"Version" sender:self];
            }
        }
    }
}

@end
