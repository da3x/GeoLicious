#import <Foundation/Foundation.h>

@interface DateUtils : NSObject {}

// Wenn die TimeZone nicht per Hand überschrieben wird, arbeiten die DateUtils mit der
// System TimeZone - was zu empfehlen ist. So passen die Strings und das Parsen immer
// zu den normalerweise erwarteten Ergebnissen. Bei Bedarf kann man die TimeZone aber auch
// neu setzen... das sollte aber gleich zu Beginn geschehen!
@property(nonatomic, retain) NSTimeZone *timezone;

// Liefert eine initialisierte Instanz der Utils, die mit der aktuellen System TimeZone arbeitet.
// Es ist sehr wichtig, dass alle Operationen mit Datums-Angaben über die gleiche Instanz getätigt
// werden. Es darf niemals einfach irgendwo irgendwie ein Datum erzeugt, verändert oder verglichen
// werden - alles muss über diese Instanz laufen.
+ (DateUtils *) sharedInstance;

- (NSDateFormatter *) createFormatter: (NSString *) pattern;

// Die folgenden Methoden generieren per default EN und kennen zusätzlich die typische DE Notation!
- (NSDateFormatter *) createFormatterDayMonthYearLong;            // 13. Januar 2013
- (NSDateFormatter *) createFormatterMonthYearLong;               // Januar 2013
- (NSDateFormatter *) createFormatterYear;                        // 2013
- (NSDateFormatter *) createFormatterDayMonthYearShort;           // 13.01.2013
- (NSDateFormatter *) createFormatterDayMonthYearHourMinuteShort; // 13.01.2013 14:32
- (NSDateFormatter *) createFormatterDayMonthShort;               // 13.01.
- (NSDateFormatter *) createFormatterHourMinute;                  // 14:32

#pragma mark - Methoden zum Erzeugen

// Erzeugt ein aktuelles Datum zum JETZT.
- (NSDate *) date;

- (NSDate *) dateByAddingDays: (int) days;

// Liefert ein Datum für den aktuellen Tag und stellt die Uhrzeit exakt auf HH:00:00. Das kann
// hier und da nützlich sein, wenn man ein Datum immer exakt auf bspw. 12:00:00 legen möchte.
- (NSDate *) dateForTodayAt: (int) hour;

- (NSDate *) date: (NSDate *) date at: (int) hour;
- (NSDate *) date: (NSDate *) date at: (int) hour andMinutes:(int)minutes;

// Erzeugt ein neues Datum für ein gewünschtes Jahr (4-stellig), den Monat (1-12) und den Tag (1-31).
// Das Datum wird auf exakt 12:00:00 in der verwendeten TimeZone gesetzt.
- (NSDate *) dateForYear: (int) year month: (int) month day: (int) day;

// Addiert zum übergebenen Datum eine Anzahl von Tagen (auch negativ) und liefert das so entstandene
// Datum als neue Instanz zurück.
- (NSDate *) date: (NSDate *) date byAddingSeconds: (int) secs;
- (NSDate *) date: (NSDate *) date byAddingDays: (int) days;
- (NSDate *) date: (NSDate *) date byAddingWeeks: (int) weeks;
- (NSDate *) date: (NSDate *) date byAddingMonths: (int) months;
- (NSDate *) date: (NSDate *) date byAddingYears: (int) years;

// Hier einige Methoden, die ein Datum exakt auf den Start oder das Ende einer Periode setzen.
- (NSDate *) makeStartOfDay:   (NSDate *) date;
- (NSDate *) makeStartOfWeek:  (NSDate *) date;
- (NSDate *) makeStartOfMonth: (NSDate *) date;
- (NSDate *) makeStartOfYear:  (NSDate *) date;
- (NSDate *) makeEndOfDay:     (NSDate *) date;
- (NSDate *) makeEndOfWeek:    (NSDate *) date;
- (NSDate *) makeEndOfMonth:   (NSDate *) date;
- (NSDate *) makeEndOfYear:    (NSDate *) date;

#pragma mark - Vergleichs-Methoden

// Vergleicht das erste Datum mit dem zweiten und liefert YES, wenn sich beide am selben Tag befinden.
- (BOOL) date: (NSDate *) date isSameDayAs: (NSDate *) other;

- (BOOL) date: (NSDate *) date isAfter: (NSDate *) other;
- (BOOL) date: (NSDate *) date isBefore: (NSDate *) other;

// Prüft, ob ein Datum zwischen zwei anderen liegt - Start und Ende inbegriffen.
- (BOOL) date: (NSDate *) date isBetween: (NSDate *) start and: (NSDate *) end;

#pragma mark - String-Ausgaben

// Liefert einen formatierten String zum Datum in der für das aktuelle System Locale typischen Art.
// Es wird nur der aktuelle Tag bspw. als "23.08.2011" oder "Aug. 23., 2011" ausgegeben.
- (NSString *) stringForDate: (NSDate *) date;
- (NSString *) stringForDateLocale: (NSDate *) date;

// Liefert einen formatierten String zum Datum in der für das aktuelle System Locale typischen Art.
// Es wird nur die Uhrzeit wie bspw. 12:23:54 ausgegeben.
- (NSString *) stringForTime: (NSDate *) date;
- (NSString *) stringForMinute: (NSDate *) date;
- (NSString *) stringForHour: (NSDate *) date;

// Liefert einen formatierten String zum Datum in der für das aktuelle System Locale typischen Art.
// Es werden Tag und Uhrzeit bspw. als "23.08.2011 12:23:54" oder "Aug. 23., 2011, 12:23:54" ausgegeben.
- (NSString *) stringForDateTime: (NSDate *) date;

- (NSString *) stringForWeekday: (NSDate *) date;
- (NSString *) stringForMonthday: (NSDate *) date;
- (NSString *) stringForMonthday2: (NSDate *) date;

- (NSString *) stringForWeek: (NSDate *) date;
- (NSString *) stringForMonth: (NSDate *) date;
- (NSString *) stringForMonthOnly: (NSDate *) date;
- (NSString *) stringForYear: (NSDate *) date;

- (NSString *) stringForISO8601: (NSDate *) date;

- (NSString *) stringFrom: (NSDate *) one to: (NSDate *) two;
- (NSString *) stringForDuration: (NSTimeInterval) secs;

#pragma mark - Test Methoden

// Hier werden einige Tests gemacht und LOG Ausgaben erzeugt, um die korrekte Funktion zu prüfen.
- (void) test;

@end
