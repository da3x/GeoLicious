//
//  GeoCache.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 18.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import "GeoCache.h"
#import "GeoDatabase.h"

@interface GeoCache ()
@property (nonatomic, strong) NSMutableDictionary *checkinsByDay;
@property (nonatomic, strong) NSMutableDictionary *checkinsByMonth;
@property (nonatomic, strong) NSMutableDictionary *checkinsByYear;
@property (nonatomic, strong) NSMutableDictionary *locationsByRegion;
@property (nonatomic, strong) NSMutableDictionary *locationsByCountry;
@end

#pragma mark - NSArray + NSMutableArray Extensions

@implementation NSArray (Reverse)

- (NSArray *) reversedArray {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

@end

@implementation NSMutableArray (Reverse)

- (void) reverse {
    if ([self count] <= 1) return;
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:j];
        
        i++;
        j--;
    }
}

@end

@implementation GeoCache

// Es wird Zeit, dass ich noch mal einen neuen Ansatz für den Cache mache...
// Und das ganze bei der Gelegenheit gleich mal auslagere. Im Grunde kann ich
// mit einer Schleife pber die CheckIns und Locations entsprechende HashMaps
// aufbauen, aus denen man dann super schnell die TableViews füllen können
// sollte. So schwer kann das ja nicht sein... oder?

#pragma mark - Singleton Pattern

+ (instancetype) shared {
    static GeoCache *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[GeoCache alloc] init];
    });
    return singleton;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self registerEvents];
    }
    return self;
}

#pragma mark - Updates

- (void) registerEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:DB_LOADED        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:DB_SAVED         object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:DB_CHANGED       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:CHECKIN_ADDED    object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:CHECKIN_REMOVED  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:LOCATION_ADDED   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:LOCATION_REMOVED object:nil];
}

- (void) update: (NSNotification *) event
{
    NSLog(@"in GeoCache#update...");
    GeoDatabase *db = [GeoDatabase sharedInstance];

    // Darf aber gerne immer im Hintergrund laufen...
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // Das sollte in jedem Fall synchronisiert werden...
        @synchronized (self) {
            NSLog(@"in GeoCache#update... starting...");

            // Die Dictionaries setzen wir als erstes zurück...
            self.checkinsByDay      = [NSMutableDictionary dictionary];
            self.checkinsByMonth    = [NSMutableDictionary dictionary];
            self.checkinsByYear     = [NSMutableDictionary dictionary];
            self.locationsByRegion  = [NSMutableDictionary dictionary];
            self.locationsByCountry = [NSMutableDictionary dictionary];
            
            // Dann geht's in einer Schleife über die CheckIns...
            for (GeoCheckin *c in [NSArray arrayWithArray:db.checkins]) {
                if (![self.checkinsByDay   objectForKey:c.startOfDay])   [self.checkinsByDay   setObject:[NSMutableArray array] forKey:c.startOfDay];
                if (![self.checkinsByMonth objectForKey:c.startOfMonth]) [self.checkinsByMonth setObject:[NSMutableArray array] forKey:c.startOfMonth];
                if (![self.checkinsByYear  objectForKey:c.startOfYear])  [self.checkinsByYear  setObject:[NSMutableArray array] forKey:c.startOfYear];
                [[self.checkinsByDay   objectForKey:c.startOfDay]   addObject:c];
                [[self.checkinsByMonth objectForKey:c.startOfMonth] addObject:c];
                [[self.checkinsByYear  objectForKey:c.startOfYear]  addObject:c];
            }
            
            // Und dann in einer zweiten Schleife über die Locations...
            for (GeoLocation *l in [NSArray arrayWithArray:db.locations]) {
                NSString *c = l.country  ? l.country : @"-";
                NSString *r = l.locality ? [NSString stringWithFormat:@"%@, %@", c, l.locality] : c;
                if (![self.locationsByRegion  objectForKey:r]) [self.locationsByRegion  setObject:[NSMutableArray array] forKey:r];
                if (![self.locationsByCountry objectForKey:c]) [self.locationsByCountry setObject:[NSMutableArray array] forKey:c];
                [[self.locationsByRegion  objectForKey:r] addObject:l];
                [[self.locationsByCountry objectForKey:c] addObject:l];
            }

            NSLog(@"in GeoCache#update... finished!");

            // Das Event muss im Main Thread raus gehen...
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CACHE_UPDATED object:nil];
            });
        }
    });
}

#pragma mark - Queries CheckIns

- (NSArray<NSDate *> *) checkinsSegments: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse
{
    // Der Zugriff muss gegen #update synchronisiert werden!
    @synchronized (self) {
        NSArray *all = nil;
        
        // Zuerst ermitteln wir die relevante Quelle...
        if (grouping == 0) all = [self.checkinsByDay   allKeys];
        if (grouping == 1) all = [self.checkinsByMonth allKeys];
        if (grouping == 2) all = [self.checkinsByYear  allKeys];
        
        // Dann filtern wir sie...
        if (filter && filter.length > 0) {
            NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:all.count];
            for (NSDate *d in all) {
                NSArray *ccc = nil;
                if (grouping == 0) ccc = [self.checkinsByDay   objectForKey:d];
                if (grouping == 1) ccc = [self.checkinsByMonth objectForKey:d];
                if (grouping == 2) ccc = [self.checkinsByYear  objectForKey:d];
                for (GeoCheckin *c in ccc) {
                    if ([c matches:filter]) {
                        [filtered addObject:d];
                        break;
                    }
                }
            }
            all = filtered;
        }
        
        // Zum Schluss wird sortiert...
        all = [all sortedArrayUsingSelector:@selector(compare:)];
        if (reverse) all = [all reversedArray];
            
        return all;
    }
}

- (NSArray<GeoCheckin *> *) checkins: (NSDate *) segment grouping: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse
{
    // Der Zugriff muss gegen #update synchronisiert werden!
    @synchronized (self) {
        NSArray *all = nil;
        
        // Zuerst ermitteln wir die relevante Quelle...
        if (grouping == 0) all = [self.checkinsByDay   objectForKey:segment];
        if (grouping == 1) all = [self.checkinsByMonth objectForKey:segment];
        if (grouping == 2) all = [self.checkinsByYear  objectForKey:segment];
        
        // Dann filtern wir sie...
        if (filter && filter.length > 0) {
            NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:all.count];
            for (GeoCheckin *c in all) {
                if ([c matches:filter]) [filtered addObject:c];
            }
            all = filtered;
        }
        
        // Zum Schluss wird sortiert...
        all = [all sortedArrayUsingSelector:@selector(compare:)];
        if (reverse) all = [all reversedArray];
        
        return all;
    }
}

#pragma mark - Queries Locations

- (NSArray<NSString *> *) locationSegments: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse
{
    // Der Zugriff muss gegen #update synchronisiert werden!
    @synchronized (self) {
        NSArray *all = nil;
        
        // Zuerst ermitteln wir die relevante Quelle...
        if (grouping == 0) all = [self.locationsByRegion  allKeys];
        if (grouping == 1) all = [self.locationsByCountry allKeys];
        
        // Dann filtern wir sie...
        if (filter && filter.length > 0) {
            NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:all.count];
            for (NSString *n in all) {
                NSArray *ccc = nil;
                if (grouping == 0) ccc = [self.locationsByRegion  objectForKey:n];
                if (grouping == 1) ccc = [self.locationsByCountry objectForKey:n];
                for (GeoLocation *l in ccc) {
                    if ([l matches:filter]) {
                        [filtered addObject:n];
                        break;
                    }
                }
            }
            all = filtered;
        }
        
        // Zum Schluss wird sortiert...
        all = [all sortedArrayUsingSelector:@selector(compare:)];
        // NICHT bei den Locations! if (reverse) all = [all reversedArray];
        
        return all;
    }
}

- (NSArray<GeoLocation *> *) locations: (NSString *) segment grouping: (NSInteger) grouping filter: (NSString *) filter reverse: (BOOL) reverse
{
    // Der Zugriff muss gegen #update synchronisiert werden!
    @synchronized (self) {
        NSArray *all = nil;
        
        // Zuerst ermitteln wir die relevante Quelle...
        if (grouping == 0) all = [self.locationsByRegion  objectForKey:segment];
        if (grouping == 1) all = [self.locationsByCountry objectForKey:segment];
        
        // Dann filtern wir sie...
        if (filter && filter.length > 0) {
            NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:all.count];
            for (GeoLocation *l in all) {
                if ([l matches:filter]) [filtered addObject:l];
            }
            all = filtered;
        }
        
        // Zum Schluss wird sortiert...
        all = [all sortedArrayUsingSelector:@selector(compareByName:)];
        // NICHT bei den Locations! if (reverse) all = [all reversedArray];
        
        return all;
    }
}

@end
