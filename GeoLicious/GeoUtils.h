//
//  GeoUtils.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define BERLIN_LAT  52.5234051
#define BERLIN_LON  13.4113999

@protocol GeoUtilsDelegate <NSObject>
// Das Delegate muss den Utils sagen, ob das Feature im Moment vom User auch aktiviert wurde. Nur dann dürfen die Utils überhaupt aktiv werden.
- (BOOL) isGeoEnabled;
// Damit wir bei "Significant Location Changes" die GeoFences neu anordnen können, brauchen wir die Liste all derer, die in Frage kommen.
- (NSArray *) findGeoFences;
// Jedes Objekt, das für ein GeoFence in Frage kommt, muss die passende Region liefern können... Koordinaten und Radius mit konstanter UUID.
- (CLRegion *) findGeoRegion: (id) source;
@end

@interface GeoUtils : NSObject <CLLocationManagerDelegate>

+ (GeoUtils *) sharedInstance;

- (void) start;
- (void) stop;

- (void) startSLC;
- (void) stopSLC;

- (CLLocation *) currentLocation;

- (NSDictionary *) dataForLatitude: (float) lon longitude: (float) lat;

- (void) monitor: (CLRegion *) region;
- (void) cancel: (CLRegion *) region;
- (void) cancelAllRegions;

@end
