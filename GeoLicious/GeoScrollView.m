//
//  GeoScrollView.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 21.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoScrollView.h"

@interface GeoScrollView ()
@end

@implementation GeoScrollView

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WhiteLeather.png"]];
    }
    return self;
}

@end
