//
//  GeoLocation.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocation.h"
#import "GeoDatabase.h"
#import "GeoUtils.h"

@interface GeoLocation ()
@property (nonatomic) float dropLat;
@property (nonatomic) float dropLon;
@property (nonatomic) CLLocationDistance currentDistance;
@property (nonatomic, retain) NSMutableDictionary *cacheMatches;
@end

@implementation GeoLocation

@synthesize uuid;
@synthesize foursquareID;
@synthesize name;
@synthesize locality;
@synthesize country;
@synthesize address;
@synthesize extra;
@synthesize icon;
@synthesize comment;
@synthesize latitude;
@synthesize longitude;
@synthesize radius;
@synthesize autoCheckin;
@synthesize useFoursquare;
@synthesize useFacebook;
@synthesize useTwitter;

+ (GeoLocation *) create: (CLLocation *) loc
{
    GeoLocation *item = [[GeoLocation alloc] init];
    [item setUuid:[GeoDatabase newUUID]];
    [item setName:NSLocalizedString(@"Custom Location",nil)];
    [item setIcon:@"tree-2.png"];
    [item setLatitude:loc.coordinate.latitude];
    [item setLongitude:loc.coordinate.longitude];
    [item setRadius:100];
    [item setAutoCheckin:NO];
    [item setUseFoursquare:NO];
    [item setUseFacebook:NO];
    [item setUseTwitter:NO];
    [item setCacheMatches:[NSMutableDictionary dictionary]];
    return item;
}

+ (GeoLocation *) createWithName: (NSString *) name lat: (float) lat lon: (float) lon
{
    GeoLocation *item = [[GeoLocation alloc] init];
    [item setUuid:[GeoDatabase newUUID]];
    [item setName:name];
    [item setIcon:@"tree-2.png"];
    [item setLatitude:lat];
    [item setLongitude:lon];
    [item setRadius:100];
    [item setAutoCheckin:NO];
    [item setUseFoursquare:NO];
    [item setUseFacebook:NO];
    [item setUseTwitter:NO];
    [item setCacheMatches:[NSMutableDictionary dictionary]];
    return item;
}

+ (GeoLocation *) createWithFourSquare: (NSDictionary *) foursquare
{
    GeoDatabase *db = [GeoDatabase sharedInstance];
    GeoLocation *item = [[GeoLocation alloc] init];
    [item setUuid:[GeoDatabase newUUID]];
    [item setFoursquareID:[foursquare objectForKey:@"id"]];
    [item setName:[foursquare objectForKey:@"name"]];
    [item setLocality:[[foursquare objectForKey:@"location"] objectForKey:@"city"]];
    [item setCountry:[[foursquare objectForKey:@"location"] objectForKey:@"country"]];
    [item setIcon:@"tree-2.png"];
    [item setLatitude:[[[foursquare objectForKey:@"location"] objectForKey:@"lat"] floatValue]];
    [item setLongitude:[[[foursquare objectForKey:@"location"] objectForKey:@"lng"] floatValue]];
    [item setRadius:100];
    [item setAutoCheckin:NO];
    [item setUseFoursquare:db.useFoursquare];
    [item setUseFacebook:db.useFacebook];
    [item setUseTwitter:db.useTwitter];
    [item setCacheMatches:[NSMutableDictionary dictionary]];

    [item updateIcon:foursquare];
    
    return item;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    [coder encodeInt:12 forKey:@"version"];
    [coder encodeObject:uuid forKey:@"uuid"];
    [coder encodeObject:foursquareID forKey:@"foursquareID"];
    [coder encodeObject:name forKey:@"name"];
    [coder encodeObject:locality forKey:@"locality"];
    [coder encodeObject:country forKey:@"country"];
    [coder encodeObject:address forKey:@"address"];
    [coder encodeObject:extra forKey:@"extra"];
    [coder encodeObject:icon forKey:@"icon"];
    [coder encodeObject:comment forKey:@"comment"];
    [coder encodeFloat:latitude forKey:@"latitude"];
    [coder encodeFloat:longitude forKey:@"longitude"];
    [coder encodeInt:radius forKey:@"radius"];
    [coder encodeBool:autoCheckin forKey:@"autoCheckin"];
    [coder encodeBool:useFoursquare forKey:@"useFoursquare"];
    [coder encodeBool:useFacebook forKey:@"useFacebook"];
    [coder encodeBool:useTwitter forKey:@"useTwitter"];
    // Die Dictionaries müssen wir in Kopie kodieren... sonst kommt es in __NSFastEnumerationMutationHandler unter ungeklärten Umständen zur ConcurrentModificationException!
    [coder encodeObject:[NSMutableDictionary dictionaryWithDictionary:self.cacheMatches] forKey:@"cacheMatches"];
}

- initWithCoder: (NSCoder *) coder
{
	self = [self init];
    int v = [coder decodeIntForKey:@"version"];

    [self setName:[coder decodeObjectForKey:@"name"]];
    [self setLatitude:[coder decodeFloatForKey:@"latitude"]];
    [self setLongitude:[coder decodeFloatForKey:@"longitude"]];
    [self setAutoCheckin:[coder decodeBoolForKey:@"autoCheckin"]];

    if (v < 2) [self setUuid:[GeoDatabase newUUID]];
    else       [self setUuid:[coder decodeObjectForKey:@"uuid"]];
    
    if (v < 3) [self setRadius:100];
    else       [self setRadius:[coder decodeIntForKey:@"radius"]];
    
    if (v > 3) {
        [self setLocality:[coder decodeObjectForKey:@"locality"]];
        [self setCountry:[coder decodeObjectForKey:@"country"]];
    }
    else {
        NSArray *strs = [self.name componentsSeparatedByString:@", "];
        if (strs.count > 0) [self setName:[strs objectAtIndex:0]];
        if (strs.count > 1) [self setLocality:[strs objectAtIndex:1]];
        if (strs.count > 2) [self setCountry:[strs objectAtIndex:2]];
    }

    if (v > 4) [self setIcon:[coder decodeObjectForKey:@"icon"]];
    else       [self setIcon:@"tree-2.png"];

    if (v > 5) [self setFoursquareID:[coder decodeObjectForKey:@"foursquareID"]];

    if (v > 6) {
        [self setAddress:[coder decodeObjectForKey:@"address"]];
        [self setExtra:[coder decodeObjectForKey:@"extra"]];
    }
    
    if (v > 7) {
        [self setUseFoursquare:[coder decodeBoolForKey:@"useFoursquare"]];
    }
    
    if (v > 8) {
        [self setUseFacebook:[coder decodeBoolForKey:@"useFacebook"]];
        [self setUseTwitter:[coder decodeBoolForKey:@"useTwitter"]];
    }

    if (v > 9) {
        [self setCacheMatches:[coder decodeObjectForKey:@"cacheMatches"]];
    }

    if (v > 11) {
        [self setComment:[coder decodeObjectForKey:@"comment"]];
    }
    
    // Mit Version 12 haben wir neue Such-Features eingeführt... daher muss der Cache wieder weg!
    if (v < 12) {
        [self setCacheMatches:[NSMutableDictionary dictionary]];
    }
    
    if (v < 11) {
        // Notwendige Korrektur zwischenzeitlich falsch gespeicherter Pfade...
        if ([self.icon rangeOfString:@"/Foursquare"].length > 0) {
            [self setIcon:[self.icon substringFromIndex:[self.icon rangeOfString:@"/Foursquare"].location]];
        }
        // Das war eine alte Korrektur... danach biegen wir das noch mal um...
        // Weil wir jetzt die URL speichern... nicht mehr den lokalen Pfad!
        // Ab Version 11 des Archives ist das bereits korrigert und muss nicht mehr angefasst werden.
        if ([self.icon rangeOfString:@"/Foursquare"].location == 0) {
            // ALT: /Foursquare/Categories/cat_abc/icon_abc.png
            // NEU: https://ss1.4sqi.net/img/categories_v2/cat_abc/icon_abc.png
            [self setIcon:[NSString stringWithFormat:@"https://ss1.4sqi.net/img/categories_v2/%@", [self.icon substringFromIndex:23]]];
        }
    }

    // Einige Icons wurden zwischenzeitlich ersetzt...
    self.icon = [self.icon stringByReplacingOccurrencesOfString:@"/food/chinese_88.png" withString:@"/food/asian_88.png"];
    self.icon = [self.icon stringByReplacingOccurrencesOfString:@"/arts_entertainment/movietheater_cineplex_88.png" withString:@"/arts_entertainment/movietheater_88.png"];

    return self;
}

// Aus Performancegründen cachen wir einige Angaben... die dann unter bestimmten Umständen aber natürlich aktualisiert werden müssen.
// Daher ist diese Methode zu jeweils dann aufzurufen, wenn sich Daten am Objekt geändert haben können.
- (void) refresh
{
    NSLog(@"in refresh");
    [self.cacheMatches removeAllObjects];
}

- (void) updateIcon: (NSDictionary *) foursquare
{
    NSArray *cats = [foursquare objectForKey:@"categories"];
    if ([cats count] > 0) {
        NSString *url = [NSString stringWithFormat:@"%@88.png",[[[cats objectAtIndex:0] objectForKey:@"icon"] objectForKey:@"prefix"]];

        // NSLog(@"4sq icon url = %@", url);
        // z.B. https://ss1.4sqi.net/img/categories_v2/travel/default_88.png
        // z.B. https://ss1.4sqi.net/img/categories_v2/building/eventspace_88.png
        // z.B. https://ss1.4sqi.net/img/categories_v2/education/cafeteria_88.png

        // Ab sofort speichern wir nur noch die URL... nutzen den ImageCache für den Zugriff! Das stellt sicher,
        // dass wir auch nach einer Neu-Installation mit einer alten Datenbank die Icons laden können.
        [self setIcon:url];
    }
}

- (int) countCheckins
{
    int n = 0;
    for (GeoCheckin *chkin in [[GeoDatabase sharedInstance] checkins]) {
        if ([chkin.location isEqual:self]) n++;
    }
    return n;
}

- (NSString *) detail
{
    NSMutableString *str = [NSMutableString string];
    if (self.locality && self.locality.length > 0) [str appendString:self.locality];
    if (self.country  && self.country.length  > 0) [str length] > 0 ? [str appendFormat:@", %@", self.country] : [str appendString:self.country];
    if (self.address  && self.address.length  > 0) [str length] > 0 ? [str appendFormat:@", %@", self.address] : [str appendString:self.address];
    if (self.extra    && self.extra.length    > 0) [str length] > 0 ? [str appendFormat:@", %@", self.extra]   : [str appendString:self.extra];
    return str;
}

- (void) queryLocation
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error)
    {
        if ([placemarks count] > 0) {
            CLPlacemark *pm = [placemarks objectAtIndex:0];
            if ([self.name isEqualToString:@"..."]) self.name = pm.name; // nur bei ...
            self.locality = pm.locality;
            self.country  = pm.country;
            self.address = [NSString stringWithFormat:@"%@, %@ %@, %@", pm.name, pm.postalCode, pm.locality, pm.administrativeArea];
        }
        [self refresh];
        [[GeoDatabase sharedInstance] save];
        [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_UPDATED object:self];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

#pragma mark - Geo Fence Tools

- (void) updateGeoFence: (BOOL) force
{
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(self.latitude, self.longitude)
                                                         radius:self.radius
                                                     identifier:self.uuid];
    
    if (force || self.autoCheckin) {
        NSLog(@"adding GeoFence for '%@'...", self.name);
        [[GeoUtils sharedInstance] monitor:region];
    }
    else {
        [[GeoUtils sharedInstance] cancel:region];
    }
}

- (void) updateDistanceTo: (CLLocation *) where
{
    CLLocation *fence = [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
    self.currentDistance = [fence distanceFromLocation:where];
}

- (NSComparisonResult) compareByDistance: (GeoLocation *) other
{
    if (self.currentDistance < other.currentDistance) return NSOrderedAscending;
    if (self.currentDistance > other.currentDistance) return NSOrderedDescending;
    return NSOrderedSame;
}

#pragma mark - Sortierung und Filterung

- (NSComparisonResult) compareByName: (GeoLocation *) other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

- (BOOL) matches: (NSString *) filter
{
    if (filter && [filter length] > 0) {
        // Das Ergebnis wird aus Performancegründen gecached...
        if ([self.cacheMatches objectForKey:filter]) return [[self.cacheMatches objectForKey:filter] isEqualToString:@"YES"];
        // Wenn wir es aber noch nicht wissen, müssen wir genauer nachschauen...
        BOOL m = NO;
        if (!m && [self.uuid     rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.name     rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.locality rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.country  rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.comment  rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [[filter lowercaseString] isEqualToString:@"geofence"] && self.autoCheckin) m = YES;
        [self.cacheMatches setObject:(m ? @"YES" : @"NO") forKey:filter];
        return m;
    }
    return YES;
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D) coordinate
{
    if (self.dropLat != 0 && self.dropLon != 0) {
        return CLLocationCoordinate2DMake(self.dropLat, self.dropLon);
    }
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (void) setCoordinate: (CLLocationCoordinate2D) coords
{
    self.dropLat = coords.latitude;
    self.dropLon = coords.longitude;
}

- (NSString *) title
{
    if (!name) return NSLocalizedString(@"...",nil);
    return name;
}

- (NSString *) subtitle
{
    return [NSString stringWithFormat:NSLocalizedString(@"%i Checkins",nil), self.countCheckins];
}

#pragma mark - Hilfsmethoden

- (void) initCoords
{
    self.dropLat = 0;
    self.dropLon = 0;
}
- (void) saveCoords
{
    if (self.dropLat != 0 && self.dropLon != 0) {
        self.latitude = self.dropLat;
        self.longitude = self.dropLon;
    }
}

@end
