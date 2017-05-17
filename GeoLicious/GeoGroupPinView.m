//
//  GeoMapPinView.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoGroupPinView.h"

@interface GeoGroupPinView ()
@property (nonatomic, retain) UIImage *icon;
@end

@implementation GeoGroupPinView

@synthesize locations;

- (id)initWithFrame:(CGRect)frame locations: (GeoGroup *) locs
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.icon = [UIImage imageNamed:@"GroupMarkerBlue.png"];
        self.locations = locs;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    int count = 0;
    for (GeoLocation *l in self.locations.allObjects) {
        count += l.countCheckins;
    }

         if (count < 10)   [self.icon drawInRect:CGRectMake( 9, 9, 18, 18)];
    else if (count < 100)  [self.icon drawInRect:CGRectMake( 6, 6, 24, 24)];
    else if (count < 1000) [self.icon drawInRect:CGRectMake( 3, 3, 30, 30)];
    else                   [self.icon drawInRect:CGRectMake( 0, 0, 36, 36)];

    NSString *str = [NSString stringWithFormat:@"%i", count];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineBreakMode = NSLineBreakByClipping;
    style.alignment     = NSTextAlignmentCenter;
    
    NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          [UIFont boldSystemFontOfSize:12], NSFontAttributeName,
                          [UIColor blackColor], NSForegroundColorAttributeName,
                          style, NSParagraphStyleAttributeName,
                          nil];
    
    [str drawInRect:CGRectMake(0, 11, 36, 36) withAttributes:attr];
}

@end
