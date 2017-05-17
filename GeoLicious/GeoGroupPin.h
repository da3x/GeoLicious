//
//  GeoGroupPin.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "GeoDatabase.h"
#import "GeoGroup.h"

@interface GeoGroupPin : MKAnnotationView

@property (nonatomic, retain) GeoGroup *locations;

+ (MKAnnotationView *) viewFor: (GeoGroup *) locs onMap: (MKMapView *) map;

@end
