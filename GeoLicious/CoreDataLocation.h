//
//  CoreDataLocation.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 28.05.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CoreDataLocation : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * foursquareID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * locatlity;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * extra;
@property (nonatomic, retain) NSString * icon;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSNumber * autoCheckin;
@property (nonatomic, retain) NSNumber * useFoursquare;
@property (nonatomic, retain) NSNumber * useTwitter;
@property (nonatomic, retain) NSNumber * useFacebook;
@property (nonatomic, retain) NSManagedObject *checkins;

@end
