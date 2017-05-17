//
//  GeoMapSearchView.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 22.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface GeoMapSearchView : MKPinAnnotationView

+ (MKAnnotationView *) viewFor: (MKMapItem *) loc onMap: (MKMapView *) map;

@end
