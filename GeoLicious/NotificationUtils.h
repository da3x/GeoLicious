//
//  NotificationUtils.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 22.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationUtils : NSObject

+ (void) setupWithNotifications: (BOOL) enabled
                      iconBadge: (BOOL) badge
                          sound: (NSString *) sound;

+ (void) notificationWithIdentifier: (NSString *) identifier
                              title: (NSString *) title
                               body: (NSString *) body
                              sound: (NSString *) sound
                              delay: (NSTimeInterval) delay
                           userInfo: (NSDictionary *) userInfo;

+ (void) test;

@end
