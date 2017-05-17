//
//  GeoTableViewCellLocation.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.09.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoTableViewCellLocation.h"

@interface GeoTableViewCellLocation ()
@property (nonatomic, retain) GeoLocation *location;
@property (nonatomic, retain) UIImageView *foursquare;
@property (nonatomic, retain) UIImageView *foursquareColor;
@property (nonatomic, retain) UIImageView *facebook;
@property (nonatomic, retain) UIImageView *twitter;
@end

@implementation GeoTableViewCellLocation

@synthesize location;
@synthesize foursquare;
@synthesize foursquareColor;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    self.foursquare            = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"foursquare.png"]];
    self.foursquareColor       = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"foursquareColor.png"]];
    self.foursquare.frame      = iOS7 ? CGRectMake(6, 17, 10, 10) : CGRectMake(6, 17, 10, 10);
    self.foursquareColor.frame = iOS7 ? CGRectMake(6, 17, 10, 10) : CGRectMake(6, 17, 10, 10);
    [self addSubview:self.foursquare];
    [self addSubview:self.foursquareColor];

    self.facebook            = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"facebook.png"]];
    self.facebook.frame      = iOS7 ? CGRectMake(6, 8, 10, 10) : CGRectMake(6, 8, 10, 10);
    self.facebook.alpha      = 0.5f;
    [self addSubview:self.facebook];

    self.twitter            = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"twitter.png"]];
    self.twitter.frame      = iOS7 ? CGRectMake(6, 27, 10, 10) : CGRectMake(6, 27, 10, 10);
    self.twitter.alpha      = 0.5f;
    [self addSubview:self.twitter];

    if (iOS7) {
        self.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }

    return self;
}

- (void) prepare: (GeoLocation *) l for: (CLLocation *) cl
{
    self.location = l;

    if ([l.icon rangeOfString:@"http"].location == 0) {
        UIImage *img = [ImageCache imageForURL:l.icon withDelegate:self];
        [self.imageView setImage:[[img negativeImage] scaleToWidth:32 height:32]];
    }
    else if ([l.icon hasSuffix:@".cached"]) {
        UIImage *img = [ImageCache imageForCache:l.icon];
        [self.imageView setImage:[[img negativeImage] scaleToWidth:32 height:32]];
    }
    else if ([l.icon rangeOfString:@"/"].location == 0) {
        NSString *path = [[[GeoDatabase sharedInstance] findPathLibrary] stringByAppendingPathComponent:l.icon];
        [self.imageView setImage:[[[UIImage imageWithContentsOfFile:path] negativeImage] scaleToWidth:32 height:32]];
    }
    else {
        [self.imageView setImage:[UIImage imageNamed:l.icon]];
    }

    [self.textLabel setText:l.name];
    [self.detailTextLabel setText:l.detail];

    // Das Foursuqare Icon als Markierung wird ein- oder ausgeblendet...
    // Die globale Einstellung sollte hier aber beachtet werden... sie beeinflusst ja zukünftige CheckIns.
    GeoDatabase *db = [GeoDatabase sharedInstance];
    [self.foursquare      setHidden:!db.useFoursquare || l.foursquareID == nil];
    [self.foursquareColor setHidden:!db.useFoursquare || l.foursquareID == nil || !l.useFoursquare];
    [self.facebook        setHidden:!db.useFacebook   || l.foursquareID == nil || !l.useFacebook];
    [self.twitter         setHidden:!db.useTwitter    || l.foursquareID == nil || !l.useTwitter];
    
    if (cl) {
        float meters = [cl distanceFromLocation:[[CLLocation alloc] initWithLatitude:l.latitude
                                                                           longitude:l.longitude]];
        [self.detailTextLabel setText:[NSString stringWithFormat:@"%.0fm @ %@", meters, l.detail]];
    }
    
    self.accessoryType = iOS7 ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryDetailDisclosureButton;
}

#pragma mark - ImageCacheDelegate

- (void) imageChanged: (UIImage *) img forURL: (NSString *) url orPath: (NSString *) path
{
    [self.imageView setImage:[[img negativeImage] scaleToWidth:32 height:32]];
}

@end
