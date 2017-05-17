//
//  GeoMapPin.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "GeoDatabase.h"

@interface GeoLocationPin : MKAnnotationView <ImageCacheDelegate>

+ (MKAnnotationView *) viewFor: (GeoLocation *) loc onMap: (MKMapView *) map;

@end
