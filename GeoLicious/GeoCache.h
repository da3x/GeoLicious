//
//  GeoCache.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 18.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeoCache : NSObject

#pragma mark - Singleton Pattern

+ (instancetype) shared;

#pragma mark - Queries CheckIns

- (NSArray<NSDate *> *) checkinsSegments: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse;
- (NSArray<GeoCheckin *> *) checkins: (NSDate *) segment grouping: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse;

#pragma mark - Queries Locations

- (NSArray<NSString *> *) locationSegments: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse;
- (NSArray<GeoLocation *> *) locations: (NSString *) segment grouping: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse;

@end
