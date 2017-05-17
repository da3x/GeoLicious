//
//  GeoButton.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 20.09.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoButton.h"

@implementation GeoButton

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (iOS7) {
            self.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        }
    }
    return self;
}

@end
