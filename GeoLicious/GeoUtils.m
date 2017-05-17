//
//  GeoUtils.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoUtils.h"
#import "GeoDatabase.h"
#import "NotificationUtils.h"

@interface GeoUtils ()
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, retain) CLLocation *locationSLC;
@end

@implementation GeoUtils

static GeoUtils *singleton;

+ (GeoUtils *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[GeoUtils alloc] init];
    }
    return singleton;
}

- (id) init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        
        // Seit iOS8 muss man genauer nachfragen... und in NSLocationAlwaysUsageDescription
        // in der Info.plist eine Beschreibung ablegen.
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        NSLog(@"...finished initialization!");
    }
    return self;
}

#pragma mark - public

- (CLLocation *) currentLocation
{
    return self.location;
}

- (void) start
{
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog(@"...started updating location!");
        [self.locationManager startUpdatingLocation];
    }
}

- (void) stop
{
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog(@"...stopped updating location!");
        [self.locationManager stopUpdatingLocation];
    }
}

- (void) startSLC
{
    NSLog(@"in GeoUtils#startSLC()");
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void) stopSLC
{
    NSLog(@"in GeoUtils#stopSLC()");
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

- (NSDictionary *) dataForLatitude: (float) lat longitude: (float) lon
{
    NSString *base = @"http://maps.googleapis.com/maps/api/geocode/json";
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?latlng=%f,%f&sensor=true", base, lat, lon]];
    
    NSMutableDictionary *extracted = [NSMutableDictionary dictionary];

    NSError* error;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (!error && data) {
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        for (NSDictionary *result in [json objectForKey:@"results"]) {
            for (NSDictionary *data in [result objectForKey:@"address_components"]) {
                NSArray *types = [data objectForKey:@"types"];
                if ([types containsObject:@"sublocality"]) {
                    [extracted setObject:[data objectForKey:@"long_name"] forKey:@"sublocality"];
                }
                if ([types containsObject:@"locality"]) {
                    [extracted setObject:[data objectForKey:@"long_name"] forKey:@"locality"];
                }
                if ([types containsObject:@"country"]) {
                    [extracted setObject:[data objectForKey:@"long_name"] forKey:@"country"];
                }
            }
        }
    }
    return extracted;
}

- (void) monitor: (CLRegion *) region
{
    if ([CLLocationManager isMonitoringAvailableForClass:[region class]]) {
        // Das ersetzt automatisch den alten Eintrag... falls vorhanden. Ich gehe mal davon aus, dass die
        // Performance hier ausreichend ist und spare mir das separate prüfen auf bereits vorhandene Fences.
        [self.locationManager startMonitoringForRegion:region];
    }
}

- (void) cancel: (CLRegion *) region
{
    if ([CLLocationManager isMonitoringAvailableForClass:[region class]]) {
        for (CLRegion *r in self.locationManager.monitoredRegions) {
            if ([r.identifier isEqualToString:region.identifier]) {
                [self.locationManager stopMonitoringForRegion:r];
            }
        }
    }
}

- (void) cancelAllRegions
{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        for (CLRegion *r in self.locationManager.monitoredRegions) {
            [self.locationManager stopMonitoringForRegion:r];
        }
    }
}

#pragma mark - private

#pragma mark - CLLocationManagerDelegate

// Delegate method from the CLLocationManagerDelegate protocol.
- (void) locationManager : (CLLocationManager *) manager didUpdateLocations: (NSArray *) locations
{
    // Mit jeder signifikanten Änderung der Location (z.B. via SLC) richten wir auch die GeoFences neu aus!
    if (self.locationSLC == nil || [self.locationSLC distanceFromLocation:[locations lastObject]] > 1000) {
        self.locationSLC = [locations lastObject];
        if ([[GeoDatabase sharedInstance] useAutoCheckin]) {
           [[GeoDatabase sharedInstance] updateGeoFencesAll];
        }
    }

    // NSLog(@"locationManager:didUpdateLocations:");
    self.location = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
//    NSLog(@"locationManager:didEnterRegion:");
    [[GeoDatabase sharedInstance] didEnter:region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
//    NSLog(@"locationManager:didExitRegion:");
    [[GeoDatabase sharedInstance] didExit:region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
//    NSLog(@"locationManager:didStartMonitoringForRegion:");
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"locationManager:monitoringDidFailForRegion:withError: %@", error);

//    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
//                                message:error.localizedDescription
//                               delegate:nil
//                      cancelButtonTitle:NSLocalizedString(@"Okay", nil)
//                      otherButtonTitles:nil] show];
}

@end
