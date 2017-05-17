#import "DateUtils.h"

// Alle in diesem Interface definierten Properties sind privat... also nicht von außen
// lesbar oder schreibbar - und das ist gut so!
@interface DateUtils ()
@property(nonatomic, retain) NSCalendar      *calendar;
@property(nonatomic, retain) NSDateFormatter *formatDate;
@property(nonatomic, retain) NSDateFormatter *formatDateLocale;
@property(nonatomic, retain) NSDateFormatter *formatDateUS;
@property(nonatomic, retain) NSDateFormatter *formatDateEUR;
@property(nonatomic, retain) NSDateFormatter *formatDateJAP;
@property(nonatomic, retain) NSDateFormatter *formatDateTimeUS;
@property(nonatomic, retain) NSDateFormatter *formatDateTimeEUR;
@property(nonatomic, retain) NSDateFormatter *formatDateTimeJAP;
@property(nonatomic, retain) NSDateFormatter *formatTime;
@property(nonatomic, retain) NSDateFormatter *formatMinute;
@property(nonatomic, retain) NSDateFormatter *formatHour;
@property(nonatomic, retain) NSDateFormatter *formatDateTime;
@property(nonatomic, retain) NSDateFormatter *formatWeekday;
@property(nonatomic, retain) NSDateFormatter *formatMonthday;
@property(nonatomic, retain) NSDateFormatter *formatMonthday2;
@property(nonatomic, retain) NSDateFormatter *formatWeek;
@property(nonatomic, retain) NSDateFormatter *formatMonth;
@property(nonatomic, retain) NSDateFormatter *formatMonthOnly;
@property(nonatomic, retain) NSDateFormatter *formatYear;
@property(nonatomic, retain) NSDateFormatter *formatISO8601;
- (NSDateFormatter *) createFormatter: (NSString *) pattern;
- (NSDateFormatter *) createFormatterLocale;
@end


@implementation DateUtils

@synthesize timezone;
@synthesize calendar;
@synthesize formatDate;
@synthesize formatDateLocale;
@synthesize formatTime;
@synthesize formatMinute;
@synthesize formatHour;
@synthesize formatDateTime;
@synthesize formatWeekday;
@synthesize formatMonthday;
@synthesize formatMonthday2;
@synthesize formatWeek;
@synthesize formatMonth;
@synthesize formatMonthOnly;
@synthesize formatYear;
@synthesize formatISO8601;

static DateUtils *singleton;

+ (DateUtils *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[DateUtils alloc] init];
    }
    return singleton;
}

- (id) init
{
    self = [super init];
    
    [self setTimezone:[NSTimeZone systemTimeZone]];
    
    [self setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]];
    [self.calendar setTimeZone:self.timezone];
    [self.calendar setLocale:[NSLocale currentLocale]]; // Setzt auch den Wochenstart!

    [self setFormatDate:[self createFormatter:@"dd.MM.yyyy"]];
    [self setFormatDateLocale:[self createFormatterLocale]];
    [self setFormatTime:[self createFormatter:@"HH:mm:ss"]];
    [self setFormatMinute:[self createFormatter:@"HH:mm"]];
    [self setFormatHour:[self createFormatter:@"HH"]];
    [self setFormatDateTime:[self createFormatter:@"dd.MM.yyyy HH:mm"]];
    [self setFormatWeekday:[self createFormatter:@"EE"]];
    [self setFormatMonthday:[self createFormatter:@"d"]];
    [self setFormatMonthday2:[self createFormatter:@"dd"]];
    [self setFormatWeek:[self createFormatter:@"'Week' w"]];
    [self setFormatMonth:[self createFormatter:@"MMMM yyyy"]];
    [self setFormatMonthOnly:[self createFormatter:@"MMM"]];
    [self setFormatYear:[self createFormatter:@"yyyy"]];
    [self setFormatISO8601:[self createFormatter:@"yyyy-MM-dd'T'HH:mm:ssZ"]];

    return self;
}

- (NSDateFormatter *) createFormatter: (NSString *) pattern
{
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale:[NSLocale currentLocale]];
    [df setDateFormat:pattern];
    [df setTimeZone:self.timezone];
    return df;
}

// Die folgenden Methoden generieren per default EN und kennen zusätzlich die typische DE Notation!
- (NSDateFormatter *) createFormatterDayMonthYearLong
{
    NSString *pattern = @"EEEE, MMMM dd, yyyy";
    if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"de_"].location == 0) pattern = @"EEEE, dd. MMMM yyyy";
    return [self createFormatter:pattern];
}
- (NSDateFormatter *) createFormatterMonthYearLong
{
    NSString *pattern = @"MMMM, yyyy";
    if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"de_"].location == 0) pattern = @"MMMM yyyy";
    return [self createFormatter:pattern];
}
- (NSDateFormatter *) createFormatterYear
{
    NSString *pattern = @"yyyy";
    return [self createFormatter:pattern];
}
- (NSDateFormatter *) createFormatterDayMonthYearShort
{
    NSString *pattern = @"MM/dd/yyyy";
    if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"de_"].location == 0) pattern = @"dd.MM.yyyy";
    return [self createFormatter:pattern];
}
- (NSDateFormatter *) createFormatterDayMonthYearHourMinuteShort
{
    NSString *pattern = @"MM/dd/yyyy HH:mm";
    if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"de_"].location == 0) pattern = @"dd.MM.yyyy HH:mm";
    return [self createFormatter:pattern];
}
- (NSDateFormatter *) createFormatterDayMonthShort
{
    NSString *pattern = @"MM/dd";
    if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"de_"].location == 0) pattern = @"dd.MM.";
    return [self createFormatter:pattern];
}
- (NSDateFormatter *) createFormatterHourMinute
{
    NSString *pattern = @"HH:mm";
    return [self createFormatter:pattern];
}

- (NSDateFormatter *) createFormatterLocale
{
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale:[NSLocale currentLocale]];
    [df setDateStyle:NSDateFormatterLongStyle];
    [df setTimeStyle:NSDateFormatterNoStyle];
    [df setTimeZone:self.timezone];
    return df;
}

// Wenn die TimeZone neu gesetzt wird, müssen wir unsere Calendar Instanz anpassen!
// Also müssen wir den Setter überschreiben, der durch @property und @synthesize
// schon automatisch vorhanden ist.
- (void) setTimezone: (NSTimeZone *) tz
{
    timezone = tz;
    [self.calendar setTimeZone:self.timezone];
}



#pragma mark Methoden zum Erzeugen

static NSUInteger full = NSCalendarUnitYear | NSCalendarUnitMonth  | NSCalendarUnitDay | NSCalendarUnitWeekday |
                         NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;

- (NSDate *) date
{
    return [NSDate date];
}

- (NSDate *) dateByAddingDays: (int) days
{
    return [self date:[self date] byAddingDays:days];
}

- (NSDate *) dateForTodayAt: (int) hour
{
    NSDateComponents *comps = [calendar components:full fromDate:[self date]];
    [comps setHour:hour];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) date: (NSDate *) date at: (int) hour
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setHour:hour];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) date: (NSDate *) date at: (int) hour andMinutes:(int)minutes
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setHour:hour];
    [comps setMinute:minutes];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) dateForYear: (int) year month: (int) month day: (int) day
{
    NSDateComponents *comps = [calendar components:full fromDate:[self date]];
    [comps setYear:year];
    [comps setMonth:month];
    [comps setDay:day];
    [comps setHour:12];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) date: (NSDate *) date byAddingSeconds: (int) secs
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setSecond:secs];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}
- (NSDate *) date: (NSDate *) date byAddingDays: (int) days
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:days];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}
- (NSDate *) date: (NSDate *) date byAddingWeeks: (int) weeks
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setWeekOfYear:weeks];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}
- (NSDate *) date: (NSDate *) date byAddingMonths: (int) months
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:months];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}
- (NSDate *) date: (NSDate *) date byAddingYears: (int) years
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:years];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}


- (NSDate *) makeStartOfDay:   (NSDate *) date
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) makeStartOfWeek:  (NSDate *) date
{
    NSDate *start = nil;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&start interval:nil forDate:date];
    return start;

    /*
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setWeekday:2]; // 2 = Montag
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
     */
}

- (NSDate *) makeStartOfMonth: (NSDate *) date
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setDay:1];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
    return date;
}

- (NSDate *) makeStartOfYear:   (NSDate *) date
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setMonth:1];
    [comps setDay:1];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:0];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) makeEndOfDay:     (NSDate *) date
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) makeEndOfWeek:    (NSDate *) date
{
    return [self makeEndOfDay:[self date:[self makeStartOfWeek:date] byAddingDays:6]];

    /*
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setWeekday:1]; // 1 = Sonntag
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    return [calendar dateFromComponents:comps];
     */
}

- (NSDate *) makeEndOfMonth:   (NSDate *) date
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setDay:[calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date].length];
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    return [calendar dateFromComponents:comps];
}

- (NSDate *) makeEndOfYear:    (NSDate *) date
{
    NSDateComponents *comps = [calendar components:full fromDate:date];
    [comps setMonth:12];
    [comps setDay:31];
    [comps setHour:23];
    [comps setMinute:59];
    [comps setSecond:59];
    return [calendar dateFromComponents:comps];
}



#pragma mark Vergleichs-Methoden

- (BOOL) date: (NSDate *) date isSameDayAs: (NSDate *) other
{
    NSDateComponents *c1 = [calendar components:full fromDate:date];
    NSDateComponents *c2 = [calendar components:full fromDate:other];
    return c1.year == c2.year && c1.month == c2.month && c1.day == c2.day;
}

- (BOOL) date: (NSDate *) date isAfter: (NSDate *) other
{
    return [date earlierDate:other] == other;
}

- (BOOL) date: (NSDate *) date isBefore: (NSDate *) other
{
    return [date earlierDate:other] == date;
}

- (BOOL) date: (NSDate *) date isBetween: (NSDate *) start and: (NSDate *) end
{
    return [date timeIntervalSinceDate:start] >= 0 && [date timeIntervalSinceDate:end] <= 0;
}



#pragma mark String-Ausgaben

- (NSString *) stringForDate: (NSDate *) date
{
    return [self.formatDate stringFromDate:date];
}

- (NSString *) stringForDateLocale: (NSDate *) date
{
    return [self.formatDateLocale stringFromDate:date];
}


- (NSString *) stringForDateUS: (NSDate *) date
{
    return [self.formatDateUS stringFromDate:date];
}
- (NSString *) stringForDateEUR: (NSDate *) date
{
    return [self.formatDateEUR stringFromDate:date];
}
- (NSString *) stringForDateJAP: (NSDate *) date
{
    return [self.formatDateJAP stringFromDate:date];
}


- (NSString *) stringForDateTimeUS: (NSDate *) date
{
    return [self.formatDateTimeUS stringFromDate:date];
}
- (NSString *) stringForDateTimeEUR: (NSDate *) date
{
    return [self.formatDateTimeEUR stringFromDate:date];
}
- (NSString *) stringForDateTimeJAP: (NSDate *) date
{
    return [self.formatDateTimeJAP stringFromDate:date];
}


- (NSString *) stringForTime: (NSDate *) date
{
    return [self.formatTime stringFromDate:date];
}

- (NSString *) stringForMinute: (NSDate *) date
{
    return [self.formatMinute stringFromDate:date];
}

- (NSString *) stringForHour: (NSDate *) date
{
    return [self.formatHour stringFromDate:date];
}

- (NSString *) stringForDateTime: (NSDate *) date
{
    return [self.formatDateTime stringFromDate:date];
}

- (NSString *) stringForWeekday: (NSDate *) date
{
    return [self.formatWeekday stringFromDate:date];
}

- (NSString *) stringForMonthday: (NSDate *) date
{
    return [self.formatMonthday stringFromDate:date];
}

- (NSString *) stringForMonthday2: (NSDate *) date
{
    return [self.formatMonthday2 stringFromDate:date];
}

- (NSString *) stringForWeek: (NSDate *) date
{
    return [self.formatWeek stringFromDate:date];
}
- (NSString *) stringForMonth: (NSDate *) date
{
    return [self.formatMonth stringFromDate:date];
}
- (NSString *) stringForMonthOnly: (NSDate *) date
{
    return [self.formatMonthOnly stringFromDate:date];
}
- (NSString *) stringForYear: (NSDate *) date
{
    return [self.formatYear stringFromDate:date];
}
- (NSString *) stringForISO8601: (NSDate *) date
{
    return [self.formatISO8601 stringFromDate:date];
}
- (NSString *) stringFrom: (NSDate *) one to: (NSDate *) two
{
    return [self stringForDuration:[two timeIntervalSinceDate:one]];
}
- (NSString *) stringForDuration: (NSTimeInterval) secs
{
    // Ich runde jeweils ab 75% auf... nicht ab der Hälfte... es ist natürlicher.
    if (secs > 60*60*24*365 * 0.75) {
        int i = secs / (60*60*24*365.0) + 0.25;
        if (i == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 year",   nil), i];
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f years",   nil), secs / (60*60*24*365)];
    }
    if (secs > 60*60*24*30 * 0.75) {
        int i = secs / (60*60*24*30.0) + 0.25;
        if (i == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 month",   nil), i];
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f months",  nil), secs / (60*60*24*30)];
    }
    if (secs > 60*60*24*7 * 0.75) {
        int i = secs / (60*60*24*7.0) + 0.25;
        if (i == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 week",   nil), i];
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f weeks",   nil), secs / (60*60*24*7)];
    }
    if (secs > 60*60*24 * 0.75) {
        int i = secs / (60*60*24.0) + 0.25;
        if (i == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 day",   nil), i];
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f days",    nil), secs / (60*60*24)];
    }
    if (secs > 60*60 * 0.75) {
        int i = secs / (60*60.0) + 0.25;
        if (i == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 hour",   nil), i];
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f hours",   nil), secs / (60*60)];
    }
    if (secs > 60 * 0.75) {
        int i = secs / (60.0) + 0.25;
        if (i == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 minute",   nil), i];
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f minutes", nil), secs / (60)];
    }
    if ((int)secs == 1) return [NSString stringWithFormat:NSLocalizedString(@"1 second", nil), secs];
    return [NSString stringWithFormat:NSLocalizedString(@"%.0f seconds", nil), secs];
}

#pragma mark Test Methoden

- (void) test
{
    DateUtils *du = [DateUtils sharedInstance];
    
    NSDate *now       = [du date];
    NSDate *tomorrow  = [du date:now byAddingDays:1];
    NSDate *yesterday = [du date:now byAddingDays:-1];

    NSLog(@"Zeitzone          = %@", [du timezone]);

    NSLog(@"Jetzt             = %@", [du stringForDateTime:now]);
    NSLog(@"Heute 12:00       = %@", [du stringForDateTime:[du dateForTodayAt:12]]);
    NSLog(@"04.06.1975 12:00  = %@", [du stringForDateTime:[du dateForYear:1975 month:6 day:4]]);
    NSLog(@"Morgen            = %@", [du stringForDateTime:tomorrow]);
    NSLog(@"Gestern           = %@", [du stringForDateTime:yesterday]);
    
    NSLog(@"Anfang des Tages  = %@", [du stringForDateTime:[du makeStartOfDay:now]]);
    NSLog(@"Anfang der Woche  = %@", [du stringForDateTime:[du makeStartOfWeek:now]]);
    NSLog(@"Anfang des Monats = %@", [du stringForDateTime:[du makeStartOfMonth:now]]);
    NSLog(@"Anfang des Jahres = %@", [du stringForDateTime:[du makeStartOfYear:now]]);

    NSLog(@"Ende des Tages    = %@", [du stringForDateTime:[du makeEndOfDay:now]]);
    NSLog(@"Ende der Woche    = %@", [du stringForDateTime:[du makeEndOfWeek:now]]);
    NSLog(@"Ende des Monats   = %@", [du stringForDateTime:[du makeEndOfMonth:now]]);
    NSLog(@"Ende des Jahres   = %@", [du stringForDateTime:[du makeEndOfYear:now]]);
    
    NSLog(@"Gestern == Morgen              = %i", [du date:yesterday isSameDayAs:tomorrow]);
    NSLog(@"Heute (01:00) == Heute (23:00) = %i", [du date:[du dateForTodayAt:1] isSameDayAs:[du dateForTodayAt:23]]);
    NSLog(@"Gestern < Heute < Morgen       = %i", [du date:now isBetween:yesterday and:tomorrow]);
}

@end
