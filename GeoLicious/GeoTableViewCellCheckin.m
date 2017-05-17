//
//  GeoTableViewCellCheckin.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.09.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoTableViewCellCheckin.h"

@interface GeoTableViewCellCheckin ()
@property (nonatomic, retain) GeoCheckin *checkin;
@property (nonatomic, retain) UIImageView *foursquare;
@property (nonatomic, retain) UIImageView *foursquareColor;
@property (nonatomic, retain) UIImageView *facebook;
@property (nonatomic, retain) UIImageView *twitter;
@end

@implementation GeoTableViewCellCheckin

@synthesize checkin;
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

- (void) prepare: (GeoCheckin *) c
{
    self.checkin = c;
    
    if ([c.location.icon rangeOfString:@"http"].location == 0) {
        UIImage *img = [ImageCache imageForURL:c.location.icon withDelegate:self];
        [self.imageView setImage:[[img negativeImage] scaleToWidth:32 height:32]];
    }
    else if ([c.location.icon hasSuffix:@".cached"]) {
        UIImage *img = [ImageCache imageForCache:c.location.icon];
        [self.imageView setImage:[[img negativeImage] scaleToWidth:32 height:32]];
    }
    else if ([c.location.icon rangeOfString:@"/"].location == 0) {
        NSString *path = [[[GeoDatabase sharedInstance] findPathLibrary] stringByAppendingPathComponent:c.location.icon];
        [self.imageView setImage:[[[UIImage imageWithContentsOfFile:path] negativeImage] scaleToWidth:32 height:32]];
    }
    else {
        [self.imageView setImage:[UIImage imageNamed:c.location.icon]];
    }
    
    [self.textLabel setText:c.location.name];
    [self.detailTextLabel setText:c.dateString];

    // FIXME und TODO für SLC
    if ([c.location.icon isEqualToString:@"arrow 13.png"]) {
        self.textLabel.text = c.location.address;
        self.textLabel.textColor = [UIColor lightGrayColor];
        self.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    else {
        self.textLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.textColor = [UIColor blackColor];
    }

    // Das Foursuqare Icon als Markierung wird ein- oder ausgeblendet...
    // Das das in der Regel schon passiert ist, achten wr hier nicht weiter auf die globalen Einstellungen.
    [self.foursquare      setHidden:!c.useFoursquare];
    [self.foursquareColor setHidden:!c.useFoursquare || !c.didFoursquare];
    [self.facebook        setHidden:!c.useFoursquare || !c.useFacebook];
    [self.twitter         setHidden:!c.useFoursquare || !c.useTwitter];

    self.accessoryType = iOS7 ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryDetailDisclosureButton;
}

#pragma mark - ImageCacheDelegate

- (void) imageChanged: (UIImage *) img forURL: (NSString *) url orPath: (NSString *) path
{
    [self.imageView setImage:[[img negativeImage] scaleToWidth:32 height:32]];
}

@end
