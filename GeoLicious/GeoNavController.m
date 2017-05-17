//
//  GeoNavController.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 07.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoNavController.h"

@interface GeoNavController ()

@end

@implementation GeoNavController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (iOS7) {
        self.navigationBar.translucent = NO;
        self.navigationBar.barTintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        self.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil];
    }

}

@end
