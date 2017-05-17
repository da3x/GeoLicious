//
//  GeoLocation.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface GeoLocation : NSObject <MKAnnotation>

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *foursquareID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *locality;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *extra;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic) int radius;
@property (nonatomic) BOOL autoCheckin;
@property (nonatomic) BOOL useFoursquare;
@property (nonatomic) BOOL useFacebook;
@property (nonatomic) BOOL useTwitter;

    
+ (GeoLocation *) create: (CLLocation *) loc;
+ (GeoLocation *) createWithName: (NSString *) name lat: (float) lat lon: (float) lon;
+ (GeoLocation *) createWithFourSquare: (NSDictionary *) foursquare;

- (int) countCheckins;

- (NSString *) detail;

- (void) queryLocation;
- (void) updateGeoFence: (BOOL) force;

- (void) updateDistanceTo: (CLLocation *) where;

- (NSComparisonResult) compareByDistance: (GeoLocation *) other;
- (NSComparisonResult) compareByName: (GeoLocation *) other;

// Aus Performancegründen cachen wir einige Angaben... die dann unter bestimmten Umständen aber natürlich aktualisiert werden müssen.
// Daher ist diese Methode zu jeweils dann aufzurufen, wenn sich Daten am Objekt geändert haben können.
- (void) refresh;

- (BOOL) matches: (NSString *) filter;

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D) coordinate;
- (void) setCoordinate: (CLLocationCoordinate2D) coords;
- (NSString *) title;
- (NSString *) subtitle;

#pragma mark - Hilfsmethoden

- (void) initCoords;
- (void) saveCoords;

@end
