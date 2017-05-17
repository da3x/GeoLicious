//
//  GeoCoreData.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 15.10.15.
//  Copyright © 2015 Daniel Bleisteiner. All rights reserved.
//

#import "CoreData.h"
#import "CoreDataLocation.h"
#import "CoreDataCheckin.h"

@interface GeoCoreData : CoreData <NSFetchedResultsControllerDelegate>

+ (GeoCoreData *) sharedInstance;

// Liefert YES, wenn es mindestens eine Location gibt.
- (BOOL) hasData;

// Liefert die Location zur UUID.
- (CoreDataLocation *) findByUUID: (NSString *) uuid;

// Die beiden erzeugen jeweils völlig neue Datensätze.
- (CoreDataLocation *) newLocation;
- (CoreDataCheckin  *) newCheckin;

// Einstellungen auslesen
- (BOOL)       reverseOrder;
- (BOOL)       clearShortEvents;
- (BOOL)       groupPins;
- (BOOL)       useAutoCheckin;
- (BOOL)       useNotifications;
- (BOOL)       useIconBadge;
- (BOOL)       useAutoBackup;
- (BOOL)       useSatelliteMode;
- (BOOL)       useFoursquare;
- (BOOL)       useFacebook;
- (BOOL)       useTwitter;
- (NSInteger)  groupingCheckins;
- (NSInteger)  groupingLocations;
- (NSString *) oauthFoursquare;
- (NSString *) sound;

// Einstellungen festlegen
- (void) setReverseOrder      : (BOOL)       b;
- (void) setClearShortEvents  : (BOOL)       b;
- (void) setGroupPins         : (BOOL)       b;
- (void) setUseAutoCheckin    : (BOOL)       b;
- (void) setUseNotifications  : (BOOL)       b;
- (void) setUseIconBadge      : (BOOL)       b;
- (void) setUseAutoBackup     : (BOOL)       b;
- (void) setUseSatelliteMode  : (BOOL)       b;
- (void) setUseFoursqaure     : (BOOL)       b;
- (void) setUseFacebook       : (BOOL)       b;
- (void) setUseTwitter        : (BOOL)       b;
- (void) setGroupingCheckins  : (NSInteger)  i;
- (void) setGroupingLocations : (NSInteger)  i;
- (void) setOauthFoursquare   : (NSString *) s;
- (void) setSound             : (NSString *) s;

// Hilfs-Klassen zur Darstellung
- (NSFetchedResultsController *) controllerCheckins;
- (NSFetchedResultsController *) controllerLocations;

@end
