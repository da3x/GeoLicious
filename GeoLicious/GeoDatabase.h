//
//  GeoDatabase.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocation.h"
#import "GeoCheckin.h"
#import <Foundation/Foundation.h>

#define DB_LOADED         @"DB_LOADED"
#define DB_SAVED          @"DB_SAVED"
#define DB_CHANGED        @"DB_CHANGED"

#define CACHE_UPDATED     @"CACHE_UPDATED"

#define DID_FOURSQUARE    @"DID_FOURSQUARE"

#define USE_CLOUD_DRIVE   @"USE_CLOUD_DRIVE"

#define CHECKIN_ADDED     @"CHECKIN_ADDED"
#define CHECKIN_REMOVED   @"CHECKIN_REMOVED"

#define LOCATION_ADDED    @"LOCATION_ADDED"
#define LOCATION_REMOVED  @"LOCATION_REMOVED"
#define LOCATION_SELECTED @"LOCATION_SELECTED"
#define LOCATION_UPDATED  @"LOCATION_UPDATED"

#define MAP_MODE_CHANGED  @"MAP_MODE_CHANGED"

#define ACTIONS_DEFAULT   @"ACTIONS_DEFAULT"
#define ACTION_DISCARD    @"ACTION_DISCARD"
#define ACTION_CHECKOUT   @"ACTION_CHECKOUT"

@interface GeoDatabase : NSObject

@property (nonatomic, retain) NSMutableArray *checkins;
@property (nonatomic, retain) NSMutableArray *locations;

+ (GeoDatabase *) sharedInstance;
+ (GeoDatabase *) reload;

+ (NSString *) newUUID;

- (NSString *) findPathLibrary;
- (NSString *) findPathDocuments;

- (BOOL)       zoomOnStart;
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

- (void) setZoomOnStart       : (BOOL)       b;
- (void) setReverseOrder      : (BOOL)       b;
- (void) setClearShortEvents  : (BOOL)       b;
- (void) setGroupPins         : (BOOL)       b;
- (void) setUseAutoCheckin    : (BOOL)       b;
- (void) setUseNotifications  : (BOOL)       b;
- (void) setUseIconBadge      : (BOOL)       b;
- (void) setUseAutoBackup     : (BOOL)       b;
- (void) setUseSatelliteMode  : (BOOL)       b;
- (void) setUseFoursquare     : (BOOL)       b;
- (void) setUseFacebook       : (BOOL)       b;
- (void) setUseTwitter        : (BOOL)       b;
- (void) setGroupingCheckins  : (NSInteger)  i;
- (void) setGroupingLocations : (NSInteger)  i;
- (void) setOauthFoursquare   : (NSString *) s;
- (void) setSound             : (NSString *) s;

- (void) reset;
- (void) demo;
- (void) save;
- (void) backup;
- (void) dailyBackup;
- (void) restore: (NSString *) filename;
- (void) delete: (NSString *) filename;
- (NSArray *) backups;
- (NSDictionary *) backupDetails: (NSString *) filename;
- (void) askForImport: (NSURL *) source;

- (BOOL) isNewVersion;

- (BOOL) useCloudDrive;
- (void) setUseCloudDrive: (BOOL) use;

- (MKCoordinateRegion) bestFit;

- (void) removeLocation: (GeoLocation *) l;

- (NSArray *) findNearBy: (CLLocation *) location query: (NSString *) query;
- (GeoLocation *) locationByUUID: (NSString *) uuid;

- (void) didEnter:(NSString *) locationUUID;
- (void) didExit:(NSString *) locationUUID;
- (void) updateGeoFencesAll;
- (void) updateGeoFencesLast5;

- (void) notificationCheckout:(NSString *) checkinUUID;
- (void) notificationDiscard:(NSString *) checkinUUID;

- (void) updateFoursquare;

- (NSArray *) allIconsHTTP;

- (NSString *) exportGPX;
- (NSString *) exportCSV;

- (void) compressToCityLevel;

- (void) connectFoursquare: (UIViewController *) vc;
- (void) disconnectFoursquare;
- (void) finishFoursquare: (NSURL *) url;

- (UIAlertView *) alertWithTitle: (NSString *) title message: (NSString *) msg autohide: (BOOL) hide;
- (void) fireBadges: (GeoCheckin *) checkin;
- (void) testSettings;
- (BOOL) limitReached;

- (void) registerActions;
- (void) testActions;

@end
