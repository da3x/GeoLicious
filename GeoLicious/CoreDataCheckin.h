//
//  CoreDataCheckin.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 28.05.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CoreDataLocation;

@interface CoreDataCheckin : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * left;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSNumber * useFacebook;
@property (nonatomic, retain) NSNumber * useFoursquare;
@property (nonatomic, retain) NSNumber * useTwitter;
@property (nonatomic, retain) NSNumber * autoCheckin;
@property (nonatomic, retain) NSNumber * didFoursquare;
@property (nonatomic, retain) CoreDataLocation *location;

// Diese Eigenschaften speichern Angaben, die uns einen schnellen UI Aufbau erlauben.
// Sie werden zur Laufzeit über den Getter neu gebildet und sind daher immer aktuell,
// auch dann, wenn sich die zu Grunde liegenden Daten ändern.
@property (nonatomic, retain) NSString * sectionDay;
@property (nonatomic, retain) NSString * sectionMonth;
@property (nonatomic, retain) NSString * sectionYear;

- (void) updateSections;

@end
