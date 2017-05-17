//
//  GeoMapPinView.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocationPinView.h"

@interface GeoLocationPinView ()
@property (nonatomic, retain) UIImage *iconRed;
@property (nonatomic, retain) UIImage *iconGreen;
@property (nonatomic, retain) UIImage *iconBlue;
@end

@implementation GeoLocationPinView

@synthesize location;

- (id)initWithFrame:(CGRect)frame location: (GeoLocation *) loc
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.iconRed   = [UIImage imageNamed:@"PinRed.png"];
        self.iconGreen = [UIImage imageNamed:@"MapMarkerGreen.png"];
        self.iconBlue  = [UIImage imageNamed:@"PinBlue.png"];
        self.location = loc;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.location.autoCheckin) [self.iconRed drawInRect:self.bounds];
    else [self.iconBlue drawInRect:self.bounds];
    
    NSString *str = [NSString stringWithFormat:@"%i", self.location.countCheckins];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineBreakMode = NSLineBreakByClipping;
    style.alignment     = NSTextAlignmentCenter;
    
    NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          [UIFont boldSystemFontOfSize:9], NSFontAttributeName,
                          [UIColor blackColor], NSForegroundColorAttributeName,
                          style, NSParagraphStyleAttributeName,
                          nil];

    [str drawInRect:CGRectMake(0, 3, self.frame.size.width, self.frame.size.width) withAttributes:attr];
}

@end
