//
//  GeoMapPin.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocationPin.h"
#import "GeoLocationPinView.h"
#import "GeoDetailDisclosureButton.h"
#import "ImageUtils.h"

@interface GeoLocationPin ()
@property (nonatomic, retain) GeoLocationPinView *pinView;
@end

@implementation GeoLocationPin

+ (MKAnnotationView *) viewFor: (GeoLocation *) loc onMap: (MKMapView *) map
{
    static NSString *const kID = @"GeoLocationPin";
    MKAnnotationView *pin = [map dequeueReusableAnnotationViewWithIdentifier:kID];
    if (pin == nil) pin = [[GeoLocationPin alloc] initWithAnnotation:loc reuseIdentifier:kID];

    // Update... sonst sehen wir womöglich was altes...
    [((GeoLocationPin*)pin).pinView setLocation:loc];
    [((GeoLocationPin*)pin).pinView setNeedsDisplay];

    UIImage *image;

    if ([loc.icon rangeOfString:@"http"].location == 0) {
        image = [ImageCache imageForURL:loc.icon withDelegate:(GeoLocationPin*)pin];
        if (iOS7) image = [image negativeImage];
        image = [image scaleToWidth:32 height:32];
    }
    else if ([loc.icon rangeOfString:@"/"].location == 0) {
        NSString *path = [[[GeoDatabase sharedInstance] findPathLibrary] stringByAppendingPathComponent:loc.icon];
        image = [UIImage imageWithContentsOfFile:path];
        if (iOS7) image = [image negativeImage];
        image = [image scaleToWidth:32 height:32];
    }
    else {
        image = [UIImage imageNamed:loc.icon];
        if (!iOS7) image = [image negativeImage];
    }

    pin.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:image];

    return pin;
}

#define PIN_WIDTH  20
#define PIN_HEIGHT 28

- (id)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        if ([annotation isKindOfClass:[GeoLocation class]]) {
            self.image = nil;
            self.enabled = YES;
            self.canShowCallout = YES;
            self.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            if (iOS7) {
                self.rightCalloutAccessoryView.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
            }

            float w = PIN_WIDTH;
            float h = PIN_HEIGHT;

            // Das funktioniert noch nicht gut... zum einen, muss dann der Text anders positioniert werden...
            // zum anderen müssen die Pins dann bei Wiederverwendung auch passend vergrößert oder verkleinert werden.
            // if (((GeoLocation*)annotation).countCheckins >= 10)  { w *= 1.2; h *= 1.2; }
            // if (((GeoLocation*)annotation).countCheckins >= 100) { w *= 1.2; h *= 1.2; }
            
            // self.rightCalloutAccessoryView = [GeoDetailDisclosureButton button];
            self.centerOffset  = CGPointMake(1, -h/2.0);
            self.calloutOffset = CGPointMake(0, 0);
            self.bounds = CGRectMake(0,0,w,h);
            
            self.pinView = [[GeoLocationPinView alloc] initWithFrame:CGRectMake(0, 0, w, h) location:annotation];
            [self addSubview:self.pinView];
        }
    }
    return self;
}

#pragma mark - ImageCacheDelegate

- (void) imageChanged: (UIImage *) img forURL: (NSString *) url orPath: (NSString *) path
{
    if (iOS7) img = [img negativeImage];
    img = [img scaleToWidth:32 height:32];
    self.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:img];
}

@end
