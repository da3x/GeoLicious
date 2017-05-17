//
//  GeoCheckin.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoCheckin.h"
#import "DateUtils.h"
#import "GeoLocation.h"

@interface GeoCheckin ()
@property (nonatomic, strong) NSDateFormatter *dd;
@property (nonatomic, strong) NSDateFormatter *tt;
@property (nonatomic, strong) NSMutableDictionary *cacheMatches;
@property (nonatomic, strong) NSDate *startOfDay;
@property (nonatomic, strong) NSDate *startOfMonth;
@property (nonatomic, strong) NSDate *startOfYear;
@property (nonatomic, strong) NSString *cachedDateString;
@property (nonatomic, strong) NSString *cachedDateStringIn;
@property (nonatomic, strong) NSString *cachedDateStringOut;
@end

@implementation GeoCheckin

@synthesize uuid;
@synthesize location;
@synthesize date;
@synthesize left;
@synthesize comment;
@synthesize autoCheckin;
@synthesize useFoursquare;
@synthesize useFacebook;
@synthesize useTwitter;
@synthesize didFoursquare;

+ (GeoCheckin *) create: (GeoLocation *) loc
{
    GeoDatabase *db = [GeoDatabase sharedInstance];
    GeoCheckin *item = [[GeoCheckin alloc] init];
    [item setUuid:[GeoDatabase newUUID]];
    [item setLocation:loc];
    [item setUseFoursquare:db.useFoursquare && loc.useFoursquare];
    [item setUseFacebook  :db.useFacebook   && loc.useFacebook];
    [item setUseTwitter   :db.useTwitter    && loc.useTwitter];
    [item refresh];
    return item;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self setDate:[[DateUtils sharedInstance] date]];
        self.uuid = [GeoDatabase newUUID];
        self.autoCheckin = NO;
        self.useFoursquare = NO;
        self.useFacebook = NO;
        self.useTwitter = NO;
        self.didFoursquare = NO;
        
        self.dd = [[DateUtils sharedInstance] createFormatterDayMonthYearShort];
        self.tt = [[DateUtils sharedInstance] createFormatterHourMinute];
        self.cacheMatches = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    [coder encodeInt:8 forKey:@"version"];
    [coder encodeObject : uuid              forKey:@"uuid"];
    [coder encodeObject : location          forKey:@"location"];
    [coder encodeObject : date              forKey:@"date"];
    [coder encodeObject : left              forKey:@"left"];
    [coder encodeObject : comment           forKey:@"comment"];
    [coder encodeBool   : autoCheckin       forKey:@"autoCheckin"];
    [coder encodeBool   : useFoursquare     forKey:@"useFoursquare"];
    [coder encodeBool   : useFacebook       forKey:@"useFacebook"];
    [coder encodeBool   : useTwitter        forKey:@"useTwitter"];
    [coder encodeBool   : didFoursquare     forKey:@"didFoursquare"];
    [coder encodeObject : self.startOfDay   forKey:@"startOfDay"];
    [coder encodeObject : self.startOfMonth forKey:@"startOfMonth"];
    [coder encodeObject : self.startOfYear  forKey:@"startOfYear"];
    // Die Dictionaries müssen wir in Kopie kodieren... sonst kommt es in __NSFastEnumerationMutationHandler unter ungeklärten Umständen zur ConcurrentModificationException!
    [coder encodeObject:[NSMutableDictionary dictionaryWithDictionary:self.cacheMatches] forKey:@"cacheMatches"];
}

- initWithCoder: (NSCoder *) coder
{
	self = [self init];
    int v = [coder decodeIntForKey:@"version"];
    
    [self setLocation:[coder decodeObjectForKey:@"location"]];
    [self setDate:[coder decodeObjectForKey:@"date"]];
    [self setComment:[coder decodeObjectForKey:@"comment"]];

    if (v > 1) [self setLeft:[coder decodeObjectForKey:@"left"]];
    if (v > 2) [self setAutoCheckin:[coder decodeBoolForKey:@"autoCheckin"]];

    if (v > 3) {
        [self setUseFoursquare:[coder decodeBoolForKey:@"useFoursquare"]];
        [self setDidFoursquare:[coder decodeBoolForKey:@"didFoursquare"]];
    }

    if (v > 4) {
        [self setUseFacebook:[coder decodeBoolForKey:@"useFacebook"]];
        [self setUseTwitter:[coder decodeBoolForKey:@"useTwitter"]];
    }

    if (v > 5) {
        [self setCacheMatches:[coder decodeObjectForKey:@"cacheMatches"]];
    }

// Diesen Cache lasse ich erst mal einfach weg... er macht bei unterschiedlichen Zeitzonen eher Probleme.
// Siehe https://bitbucket.org/Da3X/geolicious/issues/1/timezone-problem-mit-der-tableview-der
//    if (v > 6) {
//        self.startOfDay   = [coder decodeObjectForKey:@"startOfDay"];
//        self.startOfMonth = [coder decodeObjectForKey:@"startOfMonth"];
//        self.startOfYear  = [coder decodeObjectForKey:@"startOfYear"];
//    }
//    else {
        [self refresh];
//    }

    if (v > 7) {
        [self setUuid:[coder decodeObjectForKey:@"uuid"]];
    }
    else {
        [self setUuid:[GeoDatabase newUUID]];
    }
    
    return self;
}

// Aus Performancegründen cachen wir einige Angaben... die dann unter bestimmten Umständen aber natürlich aktualisiert werden müssen.
// Daher ist diese Methode zu jeweils dann aufzurufen, wenn sich Daten am Objekt geändert haben können.
- (void) refresh
{
    // NSLog(@"in refresh");
    self.cachedDateString    = nil;
    self.cachedDateStringIn  = nil;
    self.cachedDateStringOut = nil;
    [self.cacheMatches removeAllObjects];
    self.startOfDay   = [[DateUtils sharedInstance] makeStartOfDay   : self.date];
    self.startOfMonth = [[DateUtils sharedInstance] makeStartOfMonth : self.date];
    self.startOfYear  = [[DateUtils sharedInstance] makeStartOfYear  : self.date];
}

- (NSDate *) dateForGrouping: (NSInteger) grouping
{
    if (grouping == 0) return self.startOfDay;
    if (grouping == 1) return self.startOfMonth;
    if (grouping == 2) return self.startOfYear;
    return self.date;
}

- (NSString *) dateString
{
    if (self.cachedDateString == nil) {
        // static int c1 = 0; NSLog(@"c1 = %i", ++c1);
        
        DateUtils *du = [DateUtils sharedInstance];
        if (self.left) {
            self.cachedDateString = [NSString stringWithFormat:@"%@ %@ - %@",
                    [self.dd stringFromDate:self.date],
                    [self.tt stringFromDate:self.date],
                    [du stringFrom:self.date to:self.left]];
        }
        else {
            self.cachedDateString = [NSString stringWithFormat:@"%@ %@",
                    [self.dd stringFromDate:self.date],
                    [self.tt stringFromDate:self.date]];
        }
    }
    return self.cachedDateString;
}

- (NSString *) dateStringCheckIn
{
    if (self.cachedDateStringIn == nil) {
        // static int c2 = 0; NSLog(@"c2 = %i", ++c2);
        self.cachedDateStringIn = [NSString stringWithFormat:@"%@ %@", [self.dd stringFromDate:self.date], [self.tt stringFromDate:self.date]];
    }
    return self.cachedDateStringIn;
}

- (NSString *) dateStringCheckOut
{
    if (self.cachedDateStringOut == nil) {
        // static int c2 = 0; NSLog(@"c2 = %i", ++c2);
        if (!self.left) {
            self.cachedDateStringOut = @"";
        }
        else {
            self.cachedDateStringOut = [NSString stringWithFormat:@"%@ %@", [self.dd stringFromDate:self.left], [self.tt stringFromDate:self.left]];
        }
    }
    return self.cachedDateStringOut;
}

// Ob ein CheckIn zu einem Filter passt, bestimmen wir über verschiedene Eigenschaften...
- (BOOL) matches: (NSString *) filter
{
    if (filter && [filter length] > 0) {
        // Das Ergebnis wird aus Performancegründen gecached...
        if ([self.cacheMatches objectForKey:filter]) return [[self.cacheMatches objectForKey:filter] isEqualToString:@"YES"];
        // Wenn wir es aber noch nicht wissen, müssen wir genauer nachschauen...
        BOOL m = NO;
        if (!m && [self.location matches:filter]) m = YES;
        if (!m && [self.uuid               rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.comment            rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.dateStringCheckIn  rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        if (!m && [self.dateStringCheckOut rangeOfString:filter options:NSCaseInsensitiveSearch|NSLiteralSearch].length > 0) m = YES;
        [self.cacheMatches setObject:(m ? @"YES" : @"NO") forKey:filter];
        return m;
    }
    return YES;
}

- (NSComparisonResult) compare: (GeoCheckin *) other
{
    return [self.date compare:other.date];
}

- (NSString *) exportGPX
{
    NSMutableString *gpx = [NSMutableString stringWithFormat:@"<wpt lat=\"%f\" lon=\"%f\">\n", self.location.latitude, self.location.longitude];
    [gpx appendFormat:@"  <time>%@</time>\n", [[DateUtils sharedInstance] stringForISO8601:self.date]];
    [gpx appendFormat:@"  <name>%@</name>\n", self.location.name];
    [gpx appendFormat:@"  <desc>%@</desc>\n", self.comment ? self.comment : @""];
    [gpx appendString:@"</wpt>\n"];
    return gpx;
}

- (NSString *) exportCSV
{
    DateUtils *du = [DateUtils sharedInstance];
    NSMutableString *csv = [NSMutableString string];
    [csv appendFormat:@"%@;%@;\"%@\";\"%@\";\"%@\";\"%@\";\"%@\";%f;%f;\"%@\";\"%@\"\n",
     self.date              ? [du stringForDateTime:self.date] : @"",
     self.left              ? [du stringForDateTime:self.left] : @"",
     self.location.name     ? [self.location.name     stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"",
     self.location.locality ? [self.location.locality stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"",
     self.location.country  ? [self.location.country  stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"",
     self.location.address  ? [self.location.address  stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"",
     self.location.extra    ? [self.location.extra    stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"",
     self.location.latitude,
     self.location.longitude,
     self.comment           ? [self.comment stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"",
     self.location.uuid];
    return csv;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"[GeoCheckin date = %@, location = %@]", self.date, self.location];
}

@end
