//
//  GeoTableViewCellSwitch.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 10.09.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoTableViewCellSwitch.h"

@interface GeoTableViewCellSwitch ()
@end

@implementation GeoTableViewCellSwitch

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.switchButton = [[UISwitch alloc] init];
        self.accessoryView = self.switchButton;
    }
    return self;
}

@end
