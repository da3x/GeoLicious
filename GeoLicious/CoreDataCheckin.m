//
//  CoreDataCheckin.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 28.05.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import "CoreDataCheckin.h"
#import "CoreDataLocation.h"

@interface CoreDataCheckin ()
@end

@implementation CoreDataCheckin

@dynamic uuid;
@dynamic date;
@dynamic left;
@dynamic comment;
@dynamic useFacebook;
@dynamic useFoursquare;
@dynamic useTwitter;
@dynamic autoCheckin;
@dynamic didFoursquare;
@dynamic location;

#pragma mark - Transiente Eigenschaften

@dynamic  sectionDay,  sectionMonth,  sectionYear;

static NSDateFormatter *_formatDay;
static NSDateFormatter *_formatMonth;
static NSDateFormatter *_formatYear;

- (void) updateSections
{
    if (!_formatDay)   _formatDay   = [[DateUtils sharedInstance] createFormatterDayMonthYearLong];
    if (!_formatMonth) _formatMonth = [[DateUtils sharedInstance] createFormatterMonthYearLong];
    if (!_formatYear)  _formatYear  = [[DateUtils sharedInstance] createFormatterYear];
    
    self.sectionDay   = [_formatDay   stringFromDate:self.date];
    self.sectionMonth = [_formatMonth stringFromDate:self.date];
    self.sectionYear  = [_formatYear  stringFromDate:self.date];
}

@end
