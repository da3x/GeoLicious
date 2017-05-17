//
//  GeoMapSearchView.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 22.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoMapSearchView.h"
#import "GeoDetailDisclosureAddButton.h"

// Wir bringen dem MKMapItem ein wenig mehr bei...
// es kennt nämlich einen vernünftigen Namen, den wir in der
// Annotation anzeigen lassen können.
@interface MKMapItem (GeoLicious) <MKAnnotation>
- (CLLocationCoordinate2D) coordinate;
- (NSString *) title;
- (NSString *) subtitle;
@end
@implementation MKMapItem (GeoLicious)
- (CLLocationCoordinate2D) coordinate { return self.placemark.coordinate; }
- (NSString *) title { return self.name; }
- (NSString *) subtitle { return self.placemark.title; }
@end

@implementation GeoMapSearchView

+ (MKAnnotationView *) viewFor: (MKMapItem *) loc onMap: (MKMapView *) map
{
    static NSString *const kID = @"GeoMapSearchView";
    MKAnnotationView *pin = [map dequeueReusableAnnotationViewWithIdentifier:kID];
    if (pin == nil) {
        pin = [[GeoMapSearchView alloc] initWithAnnotation:loc reuseIdentifier:kID];
//        pin.image = [UIImage imageNamed:@"SearchMarkerRed.png"];
        pin.enabled = YES;
        pin.canShowCallout = YES;
//        pin.centerOffset = CGPointMake(0, 0);
//        pin.calloutOffset = CGPointMake(0, 0);
//        pin.bounds = CGRectMake(0,0,25,25);
        pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeContactAdd];
        if (iOS7) {
            pin.rightCalloutAccessoryView.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        }
//        pin.rightCalloutAccessoryView = [GeoDetailDisclosureAddButton button];

    }
    return pin;
}

@end
