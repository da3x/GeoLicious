//
//  NotificationUtils.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 22.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import "NotificationUtils.h"
#import <UserNotifications/UserNotifications.h>

@interface NotificationUtils ()
@property(atomic) BOOL useNotifications;
@property(atomic) BOOL useIconBadge;
@property(nonatomic, strong) NSString *sound;
@property(nonatomic, strong) UNUserNotificationCenter *center;
@end

@implementation NotificationUtils

#pragma mark - Singleton Pattern

+ (instancetype) shared {
    static NotificationUtils *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[NotificationUtils alloc] init];
    });
    return singleton;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        if (iOS10) {
            self.center = [UNUserNotificationCenter currentNotificationCenter];
        }
        self.useIconBadge = NO;
        self.useNotifications = NO;
        self.sound = nil;
    }
    return self;
}

#pragma mark - Configuration

+ (void) setupWithNotifications: (BOOL) enabled iconBadge: (BOOL) badge sound: (NSString *) sound
{
    [NotificationUtils shared].useNotifications = enabled;
    [NotificationUtils shared].useIconBadge     = badge;
    [NotificationUtils shared].sound            = sound;
}

#pragma mark - Notifications

+ (void) notificationWithIdentifier: (NSString *) identifier
                              title: (NSString *) title
                               body: (NSString *) body
                              sound: (NSString *) sound
                              delay: (NSTimeInterval) delay
                           userInfo: (NSDictionary *) userInfo
{
    NotificationUtils *shared = [NotificationUtils shared];
    if (shared.useNotifications) {
        if (iOS10) {
            // Zuerst müssen wir erfragen, ob der User die Notifications zulassen möchte... oder schon zugelassen hat.
            [shared.center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                                         completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"ERROR: %@", error.localizedDescription);
                    return;
                }

                // Dann basteln wir uns den NotificationContent zusammen...
                UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
                content.title    = title;
                content.body     = body;
                content.userInfo = userInfo;
                content.sound    = sound ? [UNNotificationSound soundNamed:sound] : shared.sound ? [UNNotificationSound soundNamed:shared.sound] : nil;

                // Und melden das ganze schließlich im Center an...
                UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:delay > 0 ? delay : 1 repeats:NO];
                UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                [[NotificationUtils shared].center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"ERROR: %@", error.localizedDescription);
                        return;
                    }
                }];
            }];
        }
        else {
            // Ab iOS8 muss man um Erlaubnis fragen, wenn man Notifications verwenden möchte...
            if (iOS8) {
                UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            }

            UILocalNotification *local = [[UILocalNotification alloc] init];
            local.alertBody = body;
            // TODO: local.alertAction = NSLocalizedString(@"Open",nil);
            local.soundName = sound ? sound : shared.sound ? shared.sound : nil;
            local.userInfo = userInfo;
            // TODO: local.category = ACTIONS_DEFAULT;
            [[UIApplication sharedApplication] presentLocalNotificationNow:local];
        }
    }
    
    // Mit jeder Notification zählen wir den BadgeCount nach oben...
    if (shared.useIconBadge) {
        [UIApplication sharedApplication].applicationIconBadgeNumber++;
    }
}

#pragma mark - Tests

+ (void) test
{
    [NotificationUtils setupWithNotifications:YES iconBadge:YES sound:nil];
    [NotificationUtils notificationWithIdentifier:@"TEST"
                                            title:@"NotificationUtils"
                                             body:@"Wenn Du das lesen kannst, funktionieren die Notifications."
                                            sound:nil
                                            delay:3
                                         userInfo:nil];
}

@end
