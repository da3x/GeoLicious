//
//  GeoDatabase.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoDatabase.h"
#import "GeoUtils.h"
#import "DateUtils.h"
#import "FSOAuth.h"
#import "FourSquareUtils.h"
#import "Reachability.h"
#import "InAppPurchaseUtils.h"
#import "CloudUtils.h"
#import "NotificationUtils.h"

#define DB_FILENAME @"database.db"

@interface GeoDatabase ()
@property (nonatomic, strong) NSURL *importURL;
@end

@implementation GeoDatabase

@synthesize checkins;
@synthesize locations;

#pragma mark - Einstellungen

#define KEY_ZOOM_ON_START      @"zoomOnStart"
#define KEY_REVERSE_ORDER      @"reverseOrder"
#define KEY_GROUPING_CHECKINS  @"groupingCheckins"
#define KEY_GROUPING_LOCATIONS @"groupingLocations"
#define KEY_AUTO_CHECKIN       @"autoCheckin"
#define KEY_NOTIFICATIONS      @"useNotifications"
#define KEY_ICON_BADGE         @"useIconBadge"
#define KEY_CLEAR_SHORT_EVENTS @"clearShortEvents"
#define KEY_AUTO_BACKUP        @"autoBackup"
#define KEY_GROUP_PINS         @"groupPins"
#define KEY_SATELLITE_MODE     @"satelliteMode"
#define KEY_USE_FOURSQUARE     @"useFoursquare"
#define KEY_USE_FACEBOOK       @"useFacebook"
#define KEY_USE_TWITTER        @"useTwitter"
#define KEY_OAUTH_FOURSQUARE   @"oauthFoursquare"
#define KEY_SOUND              @"sound"

- (BOOL)       zoomOnStart       { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_ZOOM_ON_START];      }
- (BOOL)       reverseOrder      { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_REVERSE_ORDER];      }
- (BOOL)       clearShortEvents  { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_CLEAR_SHORT_EVENTS]; }
- (BOOL)       groupPins         { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_GROUP_PINS];         }
- (BOOL)       useAutoCheckin    { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_AUTO_CHECKIN];       }
- (BOOL)       useNotifications  { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_NOTIFICATIONS];      }
- (BOOL)       useIconBadge      { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_ICON_BADGE];         }
- (BOOL)       useAutoBackup     { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_AUTO_BACKUP];        }
- (BOOL)       useSatelliteMode  { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_SATELLITE_MODE];     }
- (BOOL)       useFoursquare     { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_USE_FOURSQUARE];     }
- (BOOL)       useFacebook       { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_USE_FACEBOOK];       }
- (BOOL)       useTwitter        { return [[NSUserDefaults standardUserDefaults]    boolForKey:KEY_USE_TWITTER];        }
- (NSInteger)  groupingCheckins  { return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_GROUPING_CHECKINS];  }
- (NSInteger)  groupingLocations { return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_GROUPING_LOCATIONS]; }
- (NSString *) oauthFoursquare   { return [[NSUserDefaults standardUserDefaults]  objectForKey:KEY_OAUTH_FOURSQUARE];   }
- (NSString *) sound             { return [[NSUserDefaults standardUserDefaults]  objectForKey:KEY_SOUND];              }

- (void) setZoomOnStart       : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_ZOOM_ON_START];      }
- (void) setReverseOrder      : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_REVERSE_ORDER];      }
- (void) setClearShortEvents  : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_CLEAR_SHORT_EVENTS]; }
- (void) setGroupPins         : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_GROUP_PINS];         }
- (void) setUseAutoCheckin    : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_AUTO_CHECKIN];       }
- (void) setUseNotifications  : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_NOTIFICATIONS];      }
- (void) setUseIconBadge      : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_ICON_BADGE];         }
- (void) setUseAutoBackup     : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_AUTO_BACKUP];        }
- (void) setUseSatelliteMode  : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_SATELLITE_MODE];     }
- (void) setUseFoursquare     : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_USE_FOURSQUARE];     }
- (void) setUseFacebook       : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_USE_FACEBOOK];       }
- (void) setUseTwitter        : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_USE_TWITTER];        }
- (void) setGroupingCheckins  : (NSInteger)  i { [[NSUserDefaults standardUserDefaults] setInteger:i forKey:KEY_GROUPING_CHECKINS];  }
- (void) setGroupingLocations : (NSInteger)  i { [[NSUserDefaults standardUserDefaults] setInteger:i forKey:KEY_GROUPING_LOCATIONS]; }
- (void) setOauthFoursquare   : (NSString *) s { [[NSUserDefaults standardUserDefaults] setObject:s  forKey:KEY_OAUTH_FOURSQUARE];   }
- (void) setSound             : (NSString *) s { [[NSUserDefaults standardUserDefaults] setObject:s  forKey:KEY_SOUND];              }

#pragma mark - statische Methoden

static NSString    *syncUUID  = nil;
static GeoDatabase *singleton = nil;

+ (GeoDatabase *) sharedInstance
{
    if (!syncUUID) syncUUID = [GeoDatabase newUUID];
    if (!singleton) [GeoDatabase reload];
    return singleton;
}

+ (GeoDatabase *) reload
{
    // Aktualisiert die Dateiliste und startet Downloads... das stoßen wir einfach grundsätzlich an.
    [CloudUtils updateCloudDrive];

    @synchronized(syncUUID) {

        // Wir laden aus Library... wenn es dort eine Datei gibt...
        NSString *storePath = [[[[GeoDatabase alloc] init] findPathLibrary] stringByAppendingPathComponent:DB_FILENAME];
        if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
            NSLog(@"storePath = %@", storePath);
            
            // Wenn die Datenbank aus der Cloud kommt, müssen wir sicher sein, dass sie schon vollständig geladen wurde.
            // Das geht am einfachsten, wenn wir einen NSFileCoordinator verwenden. Der funktioniert auch für lokale Dateien.
            NSError *error = nil;
            NSURL *asURL = [NSURL fileURLWithPath:storePath];
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [coordinator coordinateReadingItemAtURL:asURL options:0 error:&error byAccessor:^(NSURL *newURL) {
                @synchronized(syncUUID) {
                    NSLog(@"LOADING!");
                    singleton = [NSKeyedUnarchiver unarchiveObjectWithFile:storePath];
                    [[NSNotificationCenter defaultCenter] postNotificationName:DB_LOADED object:nil];
                }
            }];
        }
        else {
            singleton = [[GeoDatabase alloc] init];
        }
        
        // Wir passen auch jedes mal unsere Notifications an...
        [NotificationUtils setupWithNotifications:singleton.useNotifications
                                        iconBadge:singleton.useIconBadge
                                            sound:singleton.sound];

    }
    
    return singleton;
}

- (NSString *) findPathLibrary
{
    if (self.useCloudDrive) {
        NSURL *iCL = [[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Library"];
        if (iCL) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:iCL.path isDirectory:nil]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:iCL.path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            return iCL.path;
        }
    }
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (NSString *) findPathDocuments
{
    if (self.useCloudDrive) {
        NSURL *iCD = [[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
        if (iCD) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:iCD.path isDirectory:nil]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:iCD.path withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        return iCD.path;
    }
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (id) init
{
    self = [super init];
    if (self) {
        [self setLocations:[NSMutableArray array]];
        [self setCheckins:[NSMutableArray array]];
    }
    return self;
}

+ (NSString *) newUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

- (void) reset
{
    [locations removeAllObjects];
    [checkins removeAllObjects];
    [[GeoUtils sharedInstance] cancelAllRegions];
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:DB_CHANGED object:nil];

    [self updateGeoFencesAll];
}

- (void) demo
{
    NSArray *all = [NSArray arrayWithObjects:
                    [NSArray arrayWithObjects:@"Berlin", @"Berlin", @"Germany", @"52.5234051", @"13.4113999", nil],
                    [NSArray arrayWithObjects:@"Cologne", @"Nordrhein-Westfalen", @"Germany", @"50.9406645", @"6.9599115",  nil],
                    [NSArray arrayWithObjects:@"Hamburg", @"Hamburg", @"Germany",@"53.5534074", @"9.9921962",  nil],
                    [NSArray arrayWithObjects:@"Koblenz", @"Rheinland-Pfalz", @"Germany",@"50.356718", @"7.599485",   nil],
                    [NSArray arrayWithObjects:@"London", @"London", @"Great Britain",@"51.500152", @"-0.126236",  nil],
                    [NSArray arrayWithObjects:@"Paris", @"Île-de-France", @"France",@"48.856614", @"2.3522219",  nil],
                    [NSArray arrayWithObjects:@"Rom", @"Latium", @"Italy",@"41.8905198", @"12.4942486", nil],
                    [NSArray arrayWithObjects:@"Barcelona", @"Catalonia", @"Spain",@"41.409776", @"2.15332",    nil],
                    nil];
    
    [locations removeAllObjects];
    for (NSArray *dd in all) {
        GeoLocation *l = [GeoLocation createWithName:[dd objectAtIndex:0]
                                                 lat:[[dd objectAtIndex:3] floatValue]
                                                 lon:[[dd objectAtIndex:4] floatValue]];
        l.locality = [dd objectAtIndex:1];
        l.country  = [dd objectAtIndex:2];
        [locations addObject:l];
    }
    
    [checkins removeAllObjects];
    NSDate *next = [[DateUtils sharedInstance] dateByAddingDays:-365];
    for (int i=0; i<30; i++) { // 30 Checkins...
        next = [[DateUtils sharedInstance] date:next byAddingDays:(random() % 10)]; // über ein Jahr verteilt...
        GeoLocation *loc = [locations objectAtIndex:(random() % locations.count)]; // an zufälliger Location...
        GeoCheckin *chk = [GeoCheckin create:loc];
        [chk setDate:next];
        [chk refresh];
        [checkins addObject:chk];
    }
    
    [[GeoUtils sharedInstance] cancelAllRegions];
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:DB_CHANGED object:nil];

    [self updateGeoFencesAll];
}

- (void) save
{
    @synchronized(syncUUID) {
        // Wir sortieren die CheckIns...
        self.checkins  = [NSMutableArray arrayWithArray:[checkins  sortedArrayUsingSelector:@selector(compare:)]];
        self.locations = [NSMutableArray arrayWithArray:[locations sortedArrayUsingSelector:@selector(compareByName:)]];
        
        // Wir speichern grundsätzlich im Hintergrund... das UI wird dann aber im Main Thread aktualisiert!
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self doSave];
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self doAfterSave];
                });
                [[NSNotificationCenter defaultCenter] postNotificationName:DB_SAVED object:self];
            });
        });

    }
}

- (void) doSave
{
    // Wir speichern in Library...
    NSString *storePath = [[self findPathLibrary] stringByAppendingPathComponent:DB_FILENAME];
    [NSKeyedArchiver archiveRootObject:singleton toFile:storePath];
}

- (void) doAfterSave
{
    // Immer wenn wir speichern, könnte sich etwas an den Daten so verändert haben, dass wir von den letzten 5 CheckIns einen neuen wieder für das automatische auschecken aktivieren müssen. Jeder neue CheckIn bspw. kommt dafür in Frage.
    [self updateGeoFencesLast5];
    [self updateFoursquare];
    [NotificationUtils setupWithNotifications:self.useNotifications
                                    iconBadge:self.useIconBadge
                                        sound:self.sound];
}

- (void) updateFoursquare
{
    // Ohne das synchronized habe ich manchmal doppelte CheckIns...
    @synchronized(self.oauthFoursquare) {
        if (self.useFoursquare) {
            // Wir suchen aus allen CheckIns die raus, die wir nach Foursquare synchronisieren wollen...
            for (GeoCheckin *chkin in [NSArray arrayWithArray:checkins]) {
                if (chkin.useFoursquare) {
                    if (!chkin.didFoursquare) {
                        // Nach spätestens 24h geben wir aber auf... also Zeit vergleichen!
                        NSDate *now = [[DateUtils sharedInstance] date];
                        NSDate *max = [[DateUtils sharedInstance] date:chkin.date byAddingSeconds:60*60];
                        // Nach frühestens 3 Minuten synchronisieren wir!
                        // Es könnte sein, dass es ein Drive-By ist und wir den gar nicht haben wollen.
                        if ([[DateUtils sharedInstance] date:max isAfter:now]) {
                            // Der CheckIn ist noch relativ neu... wir versuchen unser Glück!
                            NSLog(@"Foursquare Sync für %@...", chkin.location.name);
                            if ([[FourSquareUtils sharedInstance] sync:chkin facebook:self.useFacebook twitter:self.useTwitter]) {
                                chkin.didFoursquare = YES;
                                [[NSNotificationCenter defaultCenter] postNotificationName:DID_FOURSQUARE object:chkin];
                                // Wir gehen davon aus, dass das immer im Hintergrund läuft... und rufen
                                // daher in diesem Fall direkt doSave auf.
                                [self doSave];
                            }
                        }
                        else {
                            // Ein zu alter CheckIn wird abgestellt... den versuchen wir nicht mehr!
                            chkin.useFoursquare = NO;
                            [[NSNotificationCenter defaultCenter] postNotificationName:DID_FOURSQUARE object:chkin];
                        }
                    }
                }
            }
        }
    }
}

- (NSArray *) allIconsHTTP
{
    NSMutableSet *all = [NSMutableSet set];
    for (GeoLocation *l in [NSArray arrayWithArray:locations]) {
        if ([l.icon hasPrefix:@"http"]) [all addObject:l.icon];
    }
    return all.allObjects;
}

#pragma mark - Save and BackUp

// UIFileSharingEnabled = YES in der Info.plist!
- (void) backup
{
    @synchronized(syncUUID) {
        // Wir speichern in Documents...
        NSDateFormatter *fff = [[DateUtils sharedInstance] createFormatter:@"'BackUp-'yyyyMMdd-HHmmss'.db'"];
        NSString *filename = [fff stringFromDate:[[DateUtils sharedInstance] date]];
        NSString *storePath = [[self findPathDocuments] stringByAppendingPathComponent:filename];
        [NSKeyedArchiver archiveRootObject:singleton toFile:storePath];
    }
}

- (void) dailyBackup
{
    @synchronized(syncUUID) {
        if ([self useAutoBackup]) {
            // Wir speichern in Documents...
            NSDateFormatter *fff = [[DateUtils sharedInstance] createFormatter:@"'Daily-'yyyyMMdd'.db'"];
            NSString *filename = [fff stringFromDate:[[DateUtils sharedInstance] date]];
            NSString *storePath = [[self findPathDocuments] stringByAppendingPathComponent:filename];
            [NSKeyedArchiver archiveRootObject:singleton toFile:storePath];

            // Nur die letzten 10 automatischen BackUps aufheben...
            NSMutableArray *daily = [NSMutableArray array];
            for (NSString *bbb in [self backups]) {
                if ([bbb rangeOfString:@"Daily-"].location == 0) [daily addObject:bbb];
            }
            if (daily.count > 10) {
                NSFileManager *nsfm = [NSFileManager defaultManager];
                for (NSString *fff in [daily subarrayWithRange:NSMakeRange(0, daily.count - 10)]) {
                    [nsfm removeItemAtPath:[[self findPathDocuments] stringByAppendingPathComponent:fff]
                                     error:nil];
                }
            }
        }
    }
}

- (void) restore: (NSString *) filename
{
    // Wir laden aus Documents...
    NSString *storePath = [[self findPathDocuments] stringByAppendingPathComponent:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
        singleton = [NSKeyedUnarchiver unarchiveObjectWithFile:storePath];
        [singleton save];
        [[NSNotificationCenter defaultCenter] postNotificationName:DB_CHANGED object:nil];

        [singleton updateGeoFencesAll];
    }
}

- (void) askForImport: (NSURL *) source
{
    self.importURL = source;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Database?",nil)
                                                    message:NSLocalizedString(@"Do you really want to import this database? It will replace your current one – but I'll make a fresh backup before!",nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"Import",nil), nil];
    alert.tag = ALERT_IMPORT;
    [alert show];
}

- (void) restoreWithBackUp: (NSURL *) source
{
    // Erst das zwingend notwendige BackUp...
    [self backup];
    // Dann die Datenbank einlesen...
    singleton = [NSKeyedUnarchiver unarchiveObjectWithFile:source.path];
    [singleton save];
    [[NSNotificationCenter defaultCenter] postNotificationName:DB_CHANGED object:nil];

    [singleton updateGeoFencesAll];
}

- (void) delete: (NSString *) filename
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[[self findPathDocuments] stringByAppendingPathComponent:filename]
                                               error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error.localizedDescription);
    }
}

- (NSArray *) backups
{
    NSMutableArray *files = [NSMutableArray array];
    for (NSString *fn in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self findPathDocuments] error:nil]) {
        if ([fn hasSuffix:@".db"]) [files addObject:fn];
    }
    return files;
}

- (NSDictionary *) backupDetails: (NSString *) filename
{
    return [[NSFileManager defaultManager] attributesOfItemAtPath:[[self findPathDocuments] stringByAppendingPathComponent:filename]
                                                            error:nil];
}

#pragma mark - NSArchiver LOAD / SAVE

- (BOOL) isNewVersion
{
    // Wenn die letzte bekannte Version kleiner als die aktuelle ist, sagen wir YES!
    return NO; // TODO: self.lastVersion < 1.81f;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    // NSLog(@"START Saving Database!");
    [coder encodeInt:18 forKey:@"version"];
    [coder encodeFloat:1.81f forKey:@"lastVersion"];
    // Die Arrays müssen wir in Kopie kodieren... sonst kommt es in __NSFastEnumerationMutationHandler unter ungeklärten Umständen zur ConcurrentModificationException!
    [coder encodeObject:[NSMutableArray arrayWithArray:locations] forKey:@"locations"];
    [coder encodeObject:[NSMutableArray arrayWithArray:checkins]  forKey:@"checkins"];
    // NSLog(@"END Saving Database!");
}

- initWithCoder: (NSCoder *) coder
{
    // NSLog(@"START Loading Database!");
	self = [self init];
    int v = [coder decodeIntForKey:@"version"];
    
    [self setLocations:[coder decodeObjectForKey:@"locations"]];
    [self setCheckins:[coder decodeObjectForKey:@"checkins"]];

    // Das war mal nen Bug... hatte vergessen, bestimmte neue Locations in Array zu legen...
    // Grundsätzlich ist es aber keine schlechte Idee, alle Locations aus den CheckIns immer
    // aufzufüllen, damit da nix fehlt.
    for (GeoCheckin *chkin in [NSArray arrayWithArray:checkins]) {
        if (![locations containsObject:chkin.location]) [locations addObject:chkin.location];
    }
    
    // Bei Datenbanken mit einer Version < 18 müssen wir die Settings aus diesen auslesen und in die NSUserDefaults migrieren.
    if (v < 18) {
        if (v >  2) [self setUseAutoCheckin    :[coder decodeBoolForKey  :@"autoCheckin"]];
        if (v >  3) [self setGroupingCheckins  :[coder decodeIntForKey   :@"groupingCheckins"]];
        if (v >  3) [self setGroupingLocations :[coder decodeIntForKey   :@"groupingLocations"]];
        if (v >  4) [self setGroupPins         :[coder decodeBoolForKey  :@"groupPins"]];
        if (v >  5) [self setUseSatelliteMode  :[coder decodeBoolForKey  :@"satelliteMode"]];
        if (v >  7) [self setUseAutoBackup     :[coder decodeBoolForKey  :@"autoBackup"]];
        if (v >  8) [self setUseNotifications  :[coder decodeBoolForKey  :@"useNotifications"]];
        if (v >  8) [self setUseIconBadge      :[coder decodeBoolForKey  :@"useIconBadge"]];
        if (v > 10) [self setClearShortEvents  :[coder decodeBoolForKey  :@"clearShortEvents"]];
        if (v > 11) [self setUseFoursquare     :[coder decodeBoolForKey  :@"useFoursquare"]];
        if (v > 11) [self setOauthFoursquare   :[coder decodeObjectForKey:@"oauthFoursquare"]];
        if (v > 13) [self setUseFacebook       :[coder decodeBoolForKey  :@"useFacebook"]];
        if (v > 13) [self setUseTwitter        :[coder decodeBoolForKey  :@"useTwitter"]];
        if (v > 14) [self setSound             :[coder decodeObjectForKey:@"sound"]];
        if (v > 15) [self setReverseOrder      :[coder decodeBoolForKey  :@"reverseOrder"]];
        if (v > 16) [self setZoomOnStart       :[coder decodeBoolForKey  :@"zoomOnStart"]];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // NSLog(@"END Loading Database!");
    return self;
}

#pragma mark - Settings

- (BOOL) useCloudDrive
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:USE_CLOUD_DRIVE];
}

- (void) setUseCloudDrive: (BOOL) use
{
    [[NSUserDefaults standardUserDefaults] setBool:use forKey:USE_CLOUD_DRIVE];
}

#pragma mark - Sonstiges

- (MKCoordinateRegion) bestFit
{
    CLLocationCoordinate2D tlc; // TOP LEFT COORD
    tlc.latitude = -90;
    tlc.longitude = 180;
    
    CLLocationCoordinate2D brc; // BOTTOM RIGHT COORD
    brc.latitude = 90;
    brc.longitude = -180;
    
    for (GeoLocation *annotation in [NSArray arrayWithArray:locations]) {
        tlc.longitude = fmin(tlc.longitude, annotation.coordinate.longitude);
        tlc.latitude = fmax(tlc.latitude, annotation.coordinate.latitude);
        
        brc.longitude = fmax(brc.longitude, annotation.coordinate.longitude);
        brc.latitude = fmin(brc.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = tlc.latitude - (tlc.latitude - brc.latitude) * 0.5;
    region.center.longitude = tlc.longitude + (brc.longitude - tlc.longitude) * 0.5;
    region.span.latitudeDelta = fabs(tlc.latitude - brc.latitude) * 1.2;
    region.span.longitudeDelta = fabs(brc.longitude - tlc.longitude) * 1.2;
    
    return region;
}

- (void) removeLocation: (GeoLocation *) l
{
    [self.locations removeObject:l];
    for (GeoCheckin *chkin in [NSArray arrayWithArray:checkins]) {
        if ([chkin.location isEqual:l]) {
            [self.checkins removeObject:chkin];
        }
    }
}

- (NSArray *) findNearBy: (CLLocation *) location query: (NSString *) query
{
    NSMutableArray *found = [NSMutableArray array];
    for (GeoLocation *l in [NSArray arrayWithArray:locations]) {
        float meters = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:l.latitude longitude:l.longitude]];
        if (query) {
            if ([l matches:query]) {
                [found addObject:l];
            }
        }
        else if (meters < 1000)  {
            [found addObject:l];
        }
    }
    return [found sortedArrayUsingComparator:^NSComparisonResult(GeoLocation *a, GeoLocation *b) {
        float m1 = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:a.latitude longitude:a.longitude]];
        float m2 = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:b.latitude longitude:b.longitude]];
        if (m1 < m2) return NSOrderedAscending;
        if (m1 > m2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

- (GeoLocation *) locationByUUID: (NSString *) uuid
{
    for (GeoLocation *l in [NSArray arrayWithArray:locations]) {
        if ([l.uuid isEqualToString:uuid]) return l;
    }
    return nil;
}

// Mit jedem automatischen CheckIn legen wir ein neues Item zur schon
// vorhandenen Location an.
- (void) didEnter:(NSString *) locationUUID
{
    NSLog(@"in didEnter: with '%@'", locationUUID);
    if ([self limitReached]) return;
    for (GeoLocation *l in [NSArray arrayWithArray:locations]) {
        if (l.autoCheckin && [l.uuid isEqualToString:locationUUID]) {
            NSLog(@"checking in to '%@'...", l.name);
            GeoCheckin *chk = [GeoCheckin create:l];
            chk.autoCheckin = YES;
            [checkins addObject:chk];

            [self save];

            [[NSNotificationCenter defaultCenter] postNotificationName:CHECKIN_ADDED object:chk];

            if ([self useNotifications]) {
                UILocalNotification *local = [[UILocalNotification alloc] init];
                local.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Checked you in: %@",nil), l.name];
                local.alertAction = NSLocalizedString(@"Open",nil);
                local.soundName = self.sound;
                local.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:chk.uuid, @"uuid", nil];
                local.category = ACTIONS_DEFAULT;
                [[UIApplication sharedApplication] presentLocalNotificationNow:local];
            }
            if ([self useIconBadge]) {
                [UIApplication sharedApplication].applicationIconBadgeNumber++;
            }
            
            break;
        }
    }
    NSLog(@"done!");
}

// Wenn wir die aktuelle Location verlassen und noch nicht anderweitig
// eingecheckt haben, setzen wir das Datum, an dem der CheckIn verlassen
// wurde... aber nur 1x... also wenn es noch leer ist.
- (void) didExit:(NSString *) locationUUID
{
    NSLog(@"in didExit: with '%@'", locationUUID);
    // Nur die letzten 5 CheckIns kommen dafür in Frage...
    for (int i = 0; i < checkins.count && i < 5; i++) {
        GeoCheckin *last = (GeoCheckin *)[checkins objectAtIndex: checkins.count - (i+1)];
        if (!last.left && [[[last location] uuid] isEqualToString:locationUUID]) {
            NSLog(@"checking out from '%@'...", last.location.name);
            [last setLeft:[[DateUtils sharedInstance] date]];
            
            // Automatisch angelegte CheckIns von weniger als 3 Minuten werden auf Wunsch wieder entfernt!
            BOOL discarded = NO;
            if (self.clearShortEvents && last.location.autoCheckin) {
                NSDate *check = [[DateUtils sharedInstance] date:last.date byAddingSeconds:5*60];
                if ([[DateUtils sharedInstance] date:last.left isBefore:check]) {
                    [self.checkins removeObject:last];
                    discarded = YES;
                }
            }
            
            [self save];
            
            // Falls die Location keinen Auto-Check-In macht, war es der letzte CheckIn,
            // der nur 1x automatisch auschecken soll.
            if (!last.location.autoCheckin) [last.location updateGeoFence:NO];
          
            NSString      *str = NSLocalizedString(@"Checked you out: %@", nil);
            if (discarded) str = NSLocalizedString(@"Removed short Event: %@", nil);
                
            [NotificationUtils notificationWithIdentifier:[last location].uuid
                                                    title:[last location].name
                                                     body:[NSString stringWithFormat:str, [last location].name]
                                                    sound:nil
                                                    delay:0
                                                 userInfo:nil];
            
            
            // Wir checken nur aus dem letzten CheckIn zu dieser UUID aus... nicht aus mehreren,
            // die zufällig noch in der Timeline liegen.
            NSLog(@"done!");
            return;
        }
    }
}

// Seit v1.7.1 kann man von der Notification aus auschecken. Diese Methode erledigt das,
// ohne dabei aber wieder neue Notifications zu erzeugen... stillschweigend.
- (void) notificationCheckout:(NSString *) checkinUUID
{
    NSLog(@"in notificationCheckout: with '%@'", checkinUUID);
    if (!checkinUUID) return;

    // Von hinten nach vorne suchen... das ist viel wahrscheinlicher!
    for (long i = checkins.count - 1; i >= 0; i--) {
        GeoCheckin *last = [self.checkins objectAtIndex:i];
        if ([last.uuid isEqualToString:checkinUUID]) {
            NSLog(@"checking out from '%@'...", last.location.name);
            [last setLeft:[[DateUtils sharedInstance] date]];
            
            [self save];

            // Falls die Location keinen Auto-Check-In macht, war es der letzte CheckIn,
            // der nur 1x automatisch auschecken soll.
            if (!last.location.autoCheckin) [last.location updateGeoFence:NO];

            return;
        }
    }
    
    NSLog(@"done!");
}

// Seit v1.7.1 kann man von der Notification aus verwerfen. Diese Methode erledigt das,
// ohne dabei aber wieder neue Notifications zu erzeugen... stillschweigend.
- (void) notificationDiscard:(NSString *) checkinUUID
{
    NSLog(@"in notificationDiscard: with '%@'", checkinUUID);
    if (!checkinUUID) return;
    
    // Von hinten nach vorne suchen... das ist viel wahrscheinlicher!
    for (long i = checkins.count - 1; i >= 0; i--) {
        GeoCheckin *last = [self.checkins objectAtIndex:i];
        if ([last.uuid isEqualToString:checkinUUID]) {
            NSLog(@"discarding checking for '%@'...", last.location.name);
            [self.checkins removeObject:last];
            
            [self save];
            
            // Falls die Location keinen Auto-Check-In macht, war es der letzte CheckIn,
            // der nur 1x automatisch auschecken soll.
            if (!last.location.autoCheckin) [last.location updateGeoFence:NO];
            
            return;
        }
    }
    
    NSLog(@"done!");
}

- (void) updateGeoFencesAll
{
    // Das kann immer im Hintergrund passieren...
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        if ([self useAutoCheckin]) {
            
            // Alle Locations mit aktiviertem GeoFence werden geprüft und die 15 nächstliegenden werden aktiviert...
            NSMutableArray *active = [NSMutableArray array];
            for (GeoLocation *location in [NSArray arrayWithArray:locations]) {
                if (location.autoCheckin) {
                    [active addObject:location];
                    [location updateDistanceTo:[[GeoUtils sharedInstance] currentLocation]];
                }
                else {
                    // Locations OHNE automatischen CheckIn verwerfen wir, falls wie noch eine aktive Region haben!
                    // Aber auch wirklich nur dann. Früher habe ich immer erst mal alles abgebrochen und dann neu aufgebaut.
                    // Das war sehr schlecht für die Performance und generel nicht so schlau.
                    [location updateGeoFence:NO];
                }
            }
            
            int activated = 0;
            NSArray *sorted = [active sortedArrayUsingSelector:@selector(compareByDistance:)];
            for (GeoLocation *location in sorted) {
                if (activated > 15) location.autoCheckin = NO;
                [location updateGeoFence:NO]; // Aktiviert oder deaktivert die Region... je nach aktuellem Status!
                if (activated > 15) location.autoCheckin = YES;
                activated++;
            }
            
            // Dazu kommen dann bis zu 5 weitere aus den letzten offenen Locations...
            [self updateGeoFencesLast5];
        }
        else {
            // Ansonsten brechen wir alle bestehenden Zäune ab!
            [[GeoUtils sharedInstance] cancelAllRegions];
        }
        
    });
}

- (void) updateGeoFencesLast5
{
    // Das kann immer im Hintergrund passieren...
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // Zusätzlich aktivieren wir den GeoFence der letzten 5 Locations,
        // falls dort noch kein CheckOut stattgefunden hat. Das ermöglicht uns,
        // auch bei manuellem CheckIn automatisch auszuchecken.
        if ([self useAutoCheckin]) {
            for (int i = 0; i < checkins.count && i < 5; i++) {
                GeoCheckin *chk = (GeoCheckin *)[checkins objectAtIndex: checkins.count - (i+1)];
                if (![chk left]) {
                    [[chk location] updateGeoFence:YES];
                }
            }
        }
        
    });
}

- (NSString *) exportGPX
{
    NSMutableString *gpx = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"];
    [gpx appendString:@"<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" version=\"1.1\" creator=\"GeoLicious\"\n"];
    [gpx appendString:@"     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"];
    [gpx appendString:@"     xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n"];
    for (GeoCheckin *chkin in [NSArray arrayWithArray:checkins]) {
        [gpx appendString:[chkin exportGPX]];
    }
    [gpx appendString:@"</gpx>\n"];
    return gpx;
}

- (NSString *) exportCSV
{
    NSMutableString *csv = [NSMutableString string];
    [csv appendString:@"CHECKIN;CHECKOUT;NAME;LOCALITY;COUNTRY;ADDRESS;EXTRA;LATITUDE;LONGITUDE;COMMENT;UUID\n"];
    for (GeoCheckin *chkin in [NSArray arrayWithArray:checkins]) {
        [csv appendString:[chkin exportCSV]];
    }
    return csv;
}

// Ich bin inzwischen an dem Punkt, dass ich das ganze nicht mehr pro LOCATION sondern nur noch pro Stadt tracken möchte.
// Daher setze ich mich mal daran, die ganzen Einträge auf Knopfdruck zu komprimieren und auf Stadt-Level runter zu brechen.
// Dazu werden sowohl die Orte als auch die CheckIns auf dieses Level komprimiert und zusammengelegt.
- (void) compressToCityLevel
{
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    GeoLocation *last; NSDate *start; NSDate *end;
    
    // Wir gehen in einer Schleife über alle CheckIns. Diese sind chronologisch aufsteigend sortiert!
    for (GeoCheckin *c in [NSArray arrayWithArray:checkins]) {
        
        // Relevant ist hier nicht nur der Ort alleine... auch das Land spielt eine Rolle.
        // Streng genommen auch die PLZ. Es wäre ja denkbar, dass es den Ort mehrfach gibt.
        // Also basteln wir uns einen KEY zusammen, der ausreichend genau ist. Wir beschränken uns aber auf Ort und Land.
        NSString *c1 = [c.location.locality stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *c2 = [c.location.country  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        // CheckIns ohne ausreichende Ortsangabe müssen wir leider verwerfen...
        if (!c1 || !c2 || c1.length == 0 || c2.length == 0) {
            [self.checkins removeObject:c];
            continue;
        }
        
        // Ein paar Fehler korrigieren wir direkt...
        if ([c1 isEqualToString:@"Kreuzberg"])          c1 = @"Berlin";
        if ([c1 isEqualToString:@"Cologne"])            c1 = @"Köln";
        if ([c1 isEqualToString:@"Fürstenwalde"])       c1 = @"Fürstenwalde (Spree)";
        if ([c1 isEqualToString:@"Bad Saarow-Pieskow"]) c1 = @"Bad Saarow";
        if ([c1 isEqualToString:@"Brandenburg"])        c1 = @"Brandenburg an der Havel";
        if ([c1 isEqualToString:@"Grünheide"])          c1 = @"Grünheide (Mark)";
        // Auch bei den Ländern...
        if ([c2 isEqualToString:@"Germany"])            c2 = @"Deutschland";

        // Wir wollen nur die korrekten neuen Locations erhalten...
        c.location.comment = nil;

        NSString *k = [NSString stringWithFormat:@"%@:%@", c1, c2];
        GeoLocation *kk = [map valueForKey:k];
        // Wenn wir den Ort das erste mal treffen, erstellen wir dafür einen neuen Datensatz.
        if (!kk) {
            kk = [GeoLocation createWithName:c.location.locality lat:c.location.latitude lon:c.location.longitude];
            kk.comment = @"via compressToCityLevel()...";
            kk.radius = 1000;
            kk.autoCheckin = NO;
            kk.locality = c.location.locality;
            kk.country = c.location.country;
            kk.icon = @"https://ss1.4sqi.net/img/categories_v2/parks_outdoors/neighborhood_88.png";
            [map setObject:kk forKey:k];
            [self.locations addObject:kk];
        }
        
        // Jetzt prüfen wir, ob der Ort im Vergleich zum letzten Treffer wechselt. In diesem Fall nehmen
        // wir den gesammelten Zeitraum und erzeugen einen CheckIn dafür. Wir fassen also immer nur
        // zusammenhängende Aufenthalte in einem CheckIn zusammen.
        if (last && last != kk) {
            GeoCheckin *cc = [GeoCheckin create:last];
            cc.date = start;
            cc.left = end;
            [self.checkins addObject:cc];

            last  = nil;
            start = nil;
            end   = nil;
        }
        last  = kk;
        start = !start ? c.date :          [start earlierDate:c.date];
        end   = !end   ? c.left : c.left ? [end     laterDate:c.left] : end;
        
        // Den alten CheckIn löschen wir...
        [self.checkins removeObject:c];
    }

    // Für den letzten CheckIn müssen wir den Eintrag ebenfalls anlegen.
    GeoCheckin *cc = [GeoCheckin create:last];
    cc.date = start;
    cc.left = nil;
    [self.checkins addObject:cc];

    // Am Ende löschen wir alle Orte, die wir nicht mehr benötigen...
    for (GeoLocation *l in [NSArray arrayWithArray:locations]) {
        if (![@"via compressToCityLevel()..." isEqualToString:l.comment] &&
            ![@"Location Update pending..."   isEqualToString:l.comment]) {
            [self.locations removeObject:l];
        }
    }

    // Am Ende speichern und Update auslösen...
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:DB_CHANGED object:nil];
}

#pragma mark - Foursquare

- (void) connectFoursquare: (UIViewController *) vc
{

    // Na super... damit mit iOS 9 dir FourSquare Authentifizierung klappt, muss ich Universal Links integrieren...
    // Was anscheinend einen eigenen WebServer erfordert! Hallo?! Geht's noch?
    // https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/AppSearch/UniversalLinks.html#//apple_ref/doc/uid/TP40016308-CH12

    FSOAuthStatusCode code = [[FSOAuth shared] authorizeUserUsingClientId:FOURSQUARE_CLIENT_ID
                                                  nativeURICallbackString:FOURSQUARE_CALLBACK
                                               universalURICallbackString:nil // FOURSQUARE_UNIVERSAL_LINK
                                                     allowShowingAppStore:NO
                                                presentFromViewController:vc];

    switch (code) {
        case FSOAuthStatusSuccess:
            break;
        case FSOAuthStatusErrorInvalidClientID:
        case FSOAuthStatusErrorInvalidCallback:
            [self alertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"foursquare.oauth.invalid", nil) autohide:NO];
            break;
        case FSOAuthStatusErrorFoursquareNotInstalled:
        case FSOAuthStatusErrorFoursquareOAuthNotSupported:
        default:
            // wegen allowShowingAppStore eigentlich nicht relevant...
            break;
    }
}

- (void) disconnectFoursquare
{
    self.oauthFoursquare = nil;
    self.useFoursquare = NO;
    [self save];
}

- (void) finishFoursquare: (NSURL *) url
{
    FSOAuthErrorCode error;
    NSString *code = [[FSOAuth shared] accessCodeForFSOAuthURL:url error:&error];
    NSLog(@"code = %@", code);
    switch (error) {
        case FSOAuthErrorNone:
            [self alertWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"foursquare.oauth.success", nil) autohide:YES];
            [self finalizeFoursquare:code];
            break;
        case FSOAuthErrorUnknown:
        case FSOAuthErrorInvalidRequest:
        case FSOAuthErrorInvalidClient:
        case FSOAuthErrorInvalidGrant:
        case FSOAuthErrorUnauthorizedClient:
        case FSOAuthErrorUnsupportedGrantType:
        default:
            [self alertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"foursquare.oauth.error", nil) autohide:NO];
            break;
    }
}

- (void) finalizeFoursquare: (NSString *) code
{
    [[FSOAuth shared] requestAccessTokenForCode:code
                                       clientId:FOURSQUARE_CLIENT_ID
                              callbackURIString:FOURSQUARE_CALLBACK
                                   clientSecret:FOURSQUARE_CLIENT_SECRET
                                completionBlock:^(NSString *authToken, BOOL requestCompleted, FSOAuthErrorCode errorCode) {
       if (requestCompleted) {
           switch (errorCode) {
               case FSOAuthErrorNone:
                   NSLog(@"Alles lief bestens! authToken = %@", authToken);
                   self.oauthFoursquare = authToken;
                   self.useFoursquare = YES;
                   [self save];
                   break;
               case FSOAuthErrorUnknown:
               case FSOAuthErrorInvalidRequest:
               case FSOAuthErrorInvalidClient:
               case FSOAuthErrorInvalidGrant:
               case FSOAuthErrorUnauthorizedClient:
               case FSOAuthErrorUnsupportedGrantType:
               default:
                   [self alertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"foursquare.oauth.error", nil) autohide:NO];
                   break;
           }
       }
       else {
           [self alertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"foursquare.oauth.offline", nil) autohide:NO];
       }
   }];
}

#pragma mark - Alerts

- (UIAlertView *) alertWithTitle: (NSString *) title message: (NSString *) msg autohide: (BOOL) hide
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:hide ? nil : NSLocalizedString(@"Okay", nil)
                                          otherButtonTitles:nil];
    [alert show];
    if (hide) [self performSelector:@selector(hideAlert:) withObject:alert afterDelay:3];
    return alert;
}

- (void) hideAlert: (UIAlertView *) alert
{
    [alert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void) fireBadges: (GeoCheckin *) checkin
{
    GeoCheckin *last = nil;
    for (long i=[checkins count]-1; i>=0; i--) {
        GeoCheckin *ci = [checkins objectAtIndex:i];
        if ([ci.location isEqual:checkin.location]) {
            if (![ci isEqual:checkin]) {
                last = ci;
                break;
            }
        }
    }
    if (last) {
        DateUtils *du = [DateUtils sharedInstance];
        NSString *str = NSLocalizedString(@"It has been %@ since your last visit!", nil);
        NSString *msg = [NSString stringWithFormat:str, [du stringFrom:last.left ? last.left : last.date to:checkin.date], nil];
        [[GeoDatabase sharedInstance] alertWithTitle:NSLocalizedString(@"Welcome back!", nil)
                                             message:msg
                                            autohide:YES];
    }
}

- (void) testSettings
{
    if (iOS8 && ([self useNotifications] || [self useIconBadge])) {
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    }
    if (iOS8 && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
                 [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)) {
        [self alertWithTitle:NSLocalizedString(@"Location Services",nil)
                     message:NSLocalizedString(@"Please enable Location Services...",nil)
                    autohide:NO];
    }
    if (![CLLocationManager locationServicesEnabled]) {
        [self alertWithTitle:NSLocalizedString(@"Location Services",nil)
                     message:NSLocalizedString(@"Please enable Location Services...",nil)
                    autohide:NO];
    }
    // iOS7 setzt GeoFencing und BackgroundMode gleich... in iOS8 ist das getrennt. Wir prüfen das GeoFencing aber nur,
    // wenn es auch über den automatischen CheckIn aktiviert ist.
    if ([self useAutoCheckin]) {
        if (iOS7 && !iOS8 && ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied ||
                     [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted)) {
            [self alertWithTitle:NSLocalizedString(@"Background Mode",nil)
                         message:NSLocalizedString(@"Please enable Background Mode...",nil)
                        autohide:NO];
        }
        if (iOS8 && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [self alertWithTitle:NSLocalizedString(@"Location Services",nil)
                         message:NSLocalizedString(@"Please enable Always On Mode...",nil)
                        autohide:NO];
        }
    }
    
    // Das testet leider nicht, ob WiFi aktiviert ist... sondern ob man zu einem WLAN connected ist!
    // Reachability *wifiReach = [Reachability reachabilityForLocalWiFi];
    // if ([wifiReach currentReachabilityStatus] == NotReachable) {
    //     [self alertWithTitle:NSLocalizedString(@"WiFi",nil)
    //                  message:NSLocalizedString(@"Please enable WiFi...",nil)
    //                 autohide:NO];
    // }
}

- (BOOL) limitReached
{
    if (![[InAppPurchaseUtils sharedInstance] verifyProduct:PRODUCT_ID_PRO]) {
        BOOL limit = NO;
        if (checkins.count  >= 10) limit = YES;
        if (locations.count >= 10) limit = YES;
        if (limit) {
            [[InAppPurchaseUtils sharedInstance] goProAlert];
        }
        return limit;
    }
    return NO;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == ALERT_LIMIT) {
        if (alertView.firstOtherButtonIndex == buttonIndex) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:LINK_APPSTORE_FULL]];
        }
        return;
    }
    if (alertView.tag == ALERT_IMPORT) {
        if (alertView.firstOtherButtonIndex == buttonIndex) {
            [self restoreWithBackUp:self.importURL];
        }
        return;
    }
}

#pragma mark - Notifications

- (void) registerActions
{
    // Die eine Action soll den CheckIn verwerfen...
    UIMutableUserNotificationAction* action1 = [[UIMutableUserNotificationAction alloc] init];
    [action1 setIdentifier:ACTION_DISCARD];
    [action1 setTitle:NSLocalizedString(@"discard", nil)];
    [action1 setActivationMode:UIUserNotificationActivationModeBackground];
    [action1 setDestructive:YES];

    // Eine zweite Action soll den CheckIn abschließen und das Ende-Datum eintragen...
    UIMutableUserNotificationAction* action2 = [[UIMutableUserNotificationAction alloc] init];
    [action2 setIdentifier:ACTION_CHECKOUT];
    [action2 setTitle:NSLocalizedString(@"checkout", nil)];
    [action2 setActivationMode:UIUserNotificationActivationModeBackground];
    [action2 setDestructive:NO];

    UIMutableUserNotificationCategory* cat = [[UIMutableUserNotificationCategory alloc] init];
    [cat setIdentifier:ACTIONS_DEFAULT];
    [cat setActions:@[action2, action1] forContext:UIUserNotificationActionContextDefault];
    
    // Beide Actions sind das default für alle Notifications...
    NSSet* cats = [NSSet setWithArray:@[cat]];
    UIUserNotificationSettings* settings = [UIUserNotificationSettings
                                            settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)
                                            categories:cats];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (void) testActions
{
    UILocalNotification *local = [[UILocalNotification alloc] init];
    local.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Checked you in: %@",nil), @"TEST"];
    local.alertAction = NSLocalizedString(@"Open",nil);
    local.soundName = self.sound;
    local.category = ACTIONS_DEFAULT;
    local.fireDate = [NSDate dateWithTimeIntervalSinceNow:10];
    [[UIApplication sharedApplication] scheduleLocalNotification:local];
}

@end
