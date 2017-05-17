//
//  GeoGroup.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface GeoGroup : NSObject <MKAnnotation>

- (void) addObject: (id) o;
- (NSUInteger) count;
- (BOOL) containsObject: (id) o;
- (NSArray *) allObjects;

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D) coordinate;
- (NSString *) title;
- (NSString *) subtitle;

@end
