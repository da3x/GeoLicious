//
//  GeoGroupPin.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoGroup.h"
#import "GeoGroupPin.h"
#import "GeoGroupPinView.h"

@interface GeoGroupPin ()
@property (nonatomic, retain) GeoGroupPinView *pinView;
@end

@implementation GeoGroupPin

@synthesize locations;

+ (MKAnnotationView *) viewFor: (GeoGroup *) locs onMap: (MKMapView *) map
{
    static NSString *const kID = @"GeoGroupPin";
    MKAnnotationView *pin = [map dequeueReusableAnnotationViewWithIdentifier:kID];
    if (pin == nil) pin = [[GeoGroupPin alloc] initWithAnnotation:locs reuseIdentifier:kID];
    
    // Update... sonst sehen wir womöglich was altes...
    [(GeoGroupPin*)pin setLocations:locs];
    [((GeoGroupPin*)pin).pinView setLocations:locs];
    [((GeoGroupPin*)pin).pinView setNeedsDisplay];
    
    return pin;
}

- (id)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        if ([annotation isKindOfClass:[GeoGroup class]]) {
            self.image = nil;
            self.enabled = YES;
            self.canShowCallout = NO;
            self.rightCalloutAccessoryView = nil;
            
            self.centerOffset  = CGPointMake(0,0);
            self.calloutOffset = CGPointMake(0,0);
            self.bounds = CGRectMake(0,0,36,36);
            
            self.pinView = [[GeoGroupPinView alloc] initWithFrame:CGRectMake(0,0,36,36) locations:annotation];
            [self addSubview:self.pinView];
        }
    }
    return self;
}

@end
