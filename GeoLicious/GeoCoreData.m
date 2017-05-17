//
//  GeoCoreData.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 15.10.15.
//  Copyright © 2015 Daniel Bleisteiner. All rights reserved.
//

#import "GeoCoreData.h"

@implementation GeoCoreData

static GeoCoreData *singleton;

+ (GeoCoreData *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[GeoCoreData alloc] init];
    }
    return singleton;
}

#pragma mark - Suchfunktionen

- (BOOL) hasData
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CoreDataLocation"
                                                         inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (array != nil) return array.count > 0;
    
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    return NO;
}

- (CoreDataLocation *) findByUUID: (NSString *) uuid
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CoreDataLocation"
                                                         inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uuid = %@)", uuid];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (array != nil) return array.firstObject;
    
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    return nil;
}

#pragma mark - Erzeugen neuer Daten

- (CoreDataLocation *) newLocation
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"CoreDataLocation"
                                         inManagedObjectContext:self.managedObjectContext];
}

- (CoreDataCheckin *) newCheckin
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"CoreDataCheckin"
                                         inManagedObjectContext:self.managedObjectContext];
}

#pragma mark - Einstellungen

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

- (void) setReverseOrder      : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_REVERSE_ORDER];      }
- (void) setClearShortEvents  : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_CLEAR_SHORT_EVENTS]; }
- (void) setGroupPins         : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_GROUP_PINS];         }
- (void) setUseAutoCheckin    : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_AUTO_CHECKIN];       }
- (void) setUseNotifications  : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_NOTIFICATIONS];      }
- (void) setUseIconBadge      : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_ICON_BADGE];         }
- (void) setUseAutoBackup     : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_AUTO_BACKUP];        }
- (void) setUseSatelliteMode  : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_SATELLITE_MODE];     }
- (void) setUseFoursqaure     : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_USE_FOURSQUARE];     }
- (void) setUseFacebook       : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_USE_FACEBOOK];       }
- (void) setUseTwitter        : (BOOL)       b { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:KEY_USE_TWITTER];        }
- (void) setGroupingCheckins  : (NSInteger)  i { [[NSUserDefaults standardUserDefaults] setInteger:i forKey:KEY_GROUPING_CHECKINS];  }
- (void) setGroupingLocations : (NSInteger)  i { [[NSUserDefaults standardUserDefaults] setInteger:i forKey:KEY_GROUPING_LOCATIONS]; }
- (void) setOauthFoursquare   : (NSString *) s { [[NSUserDefaults standardUserDefaults] setObject:s  forKey:KEY_OAUTH_FOURSQUARE];   }
- (void) setSound             : (NSString *) s { [[NSUserDefaults standardUserDefaults] setObject:s  forKey:KEY_SOUND];              }

#pragma mark - Grundlagen zur Darstellung

- (NSFetchedResultsController *) controllerCheckins
{
    NSInteger grp = [self groupingCheckins];
    return [self controllerForEntity:@"CoreDataCheckin"
                                sort:@"date"
                             reverse:[self reverseOrder]
                                path:grp == 0 ? @"sectionDay" : grp == 1 ? @"sectionMonth" : @"sectionYear"
                               cache:@"checkins"];
}

- (NSFetchedResultsController *) controllerLocations
{
    return [self controllerForEntity:@"CoreDataLocation"
                                sort:@"country"
                             reverse:NO
                                path:@"country"
                               cache:@"locations"];
}

- (NSFetchedResultsController *) controllerForEntity:(NSString *) entity sort:(NSString *) sort reverse:(BOOL) reverse path:(NSString *) path cache:(NSString *) cache
{
    // Der folgende Code stammt überwiegend aus dem SampleCode von Apple...
    // https://developer.apple.com/library/ios/samplecode/DateSectionTitles/Introduction/Intro.html
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entity
                                                         inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setFetchBatchSize:20];
    [request setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:sort ascending:reverse ? NO : YES]]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                          managedObjectContext:self.managedObjectContext
                                                                            sectionNameKeyPath:path
                                                                                     cacheName:cache];
    // Das Delegate wird vermutlich mal wichtig sein...
    frc.delegate = self;
    
    NSError *error;
    if (![frc performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        return nil;
    }
    
    return frc;
}

#pragma mark - NSFetchedResultsControllerDelegate

// noch nix...

@end
