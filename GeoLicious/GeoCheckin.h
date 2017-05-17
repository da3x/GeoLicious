//
//  GeoCheckin.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GeoLocation;

@interface GeoCheckin : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) GeoLocation *location;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *left;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic) BOOL autoCheckin;
@property (nonatomic) BOOL useFoursquare;
@property (nonatomic) BOOL useFacebook;
@property (nonatomic) BOOL useTwitter;
@property (nonatomic) BOOL didFoursquare;

// int jahr, monat und tag...

+ (GeoCheckin *) create: (GeoLocation *) loc;

- (NSString *) dateString;
- (NSString *) dateStringCheckIn;
- (NSString *) dateStringCheckOut;

- (NSDate *) startOfDay;
- (NSDate *) startOfMonth;
- (NSDate *) startOfYear;

// Aus Performancegründen cachen wir einige Angaben... die dann unter bestimmten Umständen aber natürlich aktualisiert werden müssen.
// Daher ist diese Methode zu jeweils dann aufzurufen, wenn sich Daten am Objekt geändert haben können.
- (void) refresh;

- (NSDate *) dateForGrouping: (NSInteger) grouping;
- (BOOL) matches: (NSString *) filter;

- (NSComparisonResult) compare: (GeoCheckin *) other;

- (NSString *) exportGPX;
- (NSString *) exportCSV;

@end
