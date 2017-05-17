//
//  CoreDataMigration.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 28.05.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import "CoreDataMigration.h"
#import "CoreDataLocation.h"
#import "CoreDataCheckin.h"

@implementation CoreDataMigration

+ (void) start
{
    NSLog(@"Prüfe Migration der alten Datenbank...");
    GeoDatabase *db = [GeoDatabase sharedInstance];
    GeoCoreData *cd = [GeoCoreData sharedInstance];

    // Die Migration starten wir nur ein einziges mal... danach nicht mehr.
    // Später kann es gut sein, dass wir das noch mal neu machen...
    // aber für's erste soll das genügen.
    if (![cd hasData]) {
        
        NSLog(@"#1 Settings nach UserDefaults...");
        [self handleSettings:cd db:db];
        NSLog(@"#2 Locations nach CoreData...");
        [self handleLocations:cd db:db];
        NSLog(@"#3 CheckIns nach CoreData...");
        [self handleCheckins:cd db:db];

        NSLog(@"Zeit alles zu speichern!");
        [cd saveContext];
    }
    
    // Ein kurzer Test der Daten...
    [self debug:cd];
}

// Die ganzen Einstellungen legen wir zukünftig in den NSUserDefaults ab... also Geräte-spezifisch!
+ (void)handleSettings:(GeoCoreData *)cd db:(GeoDatabase *)db
{
//    [cd setUseAutoCheckin    :[db autoCheckin]];
//    [cd setUseNotifications  :[db useNotifications]];
//    [cd setUseIconBadge      :[db useIconBadge]];
//    [cd setClearShortEvents  :[db clearShortEvents]];
//    [cd setUseAutoBackup     :[db autoBackup]];
//    [cd setGroupPins         :[db groupPins]];
//    [cd setUseSatelliteMode  :[db satelliteMode]];
//    [cd setUseFoursqaure     :[db useFoursquare]];
//    [cd setUseFacebook       :[db useFacebook]];
//    [cd setUseTwitter        :[db useTwitter]];
//    [cd setReverseOrder      :[db reverseOrder]];
//    [cd setGroupingCheckins  :[db groupingCheckins]];
//    [cd setGroupingLocations :[db groupingLocations]];
//    [cd setOauthFoursquare   :[db oauthFoursquare]];
//    [cd setSound             :[db sound]];
//
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Die Locations wandern alle in CoreData...
+ (void)handleLocations:(GeoCoreData *)cd db:(GeoDatabase *)db
{
    for (GeoLocation *old in [db locations]) {
        CoreDataLocation *loc = [cd newLocation];
        
        loc.uuid          = old.uuid;
        loc.foursquareID  = old.foursquareID;
        loc.name          = old.name;
        loc.locatlity     = old.locality;
        loc.country       = old.country;
        loc.address       = old.address;
        loc.extra         = old.extra;
        loc.icon          = old.icon;
        loc.comment       = old.comment;
        loc.latitude      = [[NSNumber alloc] initWithFloat:old.latitude];
        loc.longitude     = [[NSNumber alloc] initWithFloat:old.longitude];
        loc.radius        = [[NSNumber alloc] initWithInt:old.radius];
        loc.autoCheckin   = [[NSNumber alloc] initWithBool:old.autoCheckin];
        loc.useFoursquare = [[NSNumber alloc] initWithBool:old.useFoursquare];
        loc.useTwitter    = [[NSNumber alloc] initWithBool:old.useTwitter];
        loc.useFacebook   = [[NSNumber alloc] initWithBool:old.useFacebook];
    }
}

// Die Checkins wandern alle in CoreData...
+ (void)handleCheckins:(GeoCoreData *)cd db:(GeoDatabase *)db
{
    for (GeoCheckin *old in [db checkins]) {
        CoreDataCheckin *chk = [cd newCheckin];
        
        chk.uuid          = old.uuid;
        chk.date          = old.date;
        chk.left          = old.left;
        chk.comment       = old.comment;
        chk.useFacebook   = [[NSNumber alloc] initWithBool:old.useFacebook];
        chk.useFoursquare = [[NSNumber alloc] initWithBool:old.useFoursquare];
        chk.useTwitter    = [[NSNumber alloc] initWithBool:old.useTwitter];
        chk.autoCheckin   = [[NSNumber alloc] initWithBool:old.autoCheckin];
        chk.didFoursquare = [[NSNumber alloc] initWithBool:old.didFoursquare];
        chk.location      = [cd findByUUID:old.location.uuid];
        
        [chk updateSections];
    }
}

+ (void)debug:(GeoCoreData *)cd
{
    NSLog(@"sections = %lu", [[[cd controllerCheckins] sections] count]);
    NSLog(@"sections = %@", [[cd controllerCheckins] sections]);
}
@end
