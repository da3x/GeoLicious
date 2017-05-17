//
//  GeoDetailDisclosureButton.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 24.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoDetailDisclosureButton.h"

@implementation GeoDetailDisclosureButton

+ (id) buttonForTableView: (GeoTableView *) tableView
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    button.backgroundColor = [UIColor clearColor];
    [button setImage:[UIImage imageNamed:@"DetailDisclosureRed.png"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"DetailDisclosureRedDown.png"] forState:UIControlStateHighlighted];

    // Wir müssen uns selbst darum kümmern, wenn der User auf das Teil tippt...
//    [button addTarget:tableView
//               action:@selector(accessoryButtonTapped:withEvent:)
//     forControlEvents:UIControlEventTouchUpInside];

    return button;
}

+ (id) button
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    button.backgroundColor = [UIColor clearColor];
    [button setImage:[UIImage imageNamed:@"DetailDisclosureRed.png"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"DetailDisclosureRedDown.png"] forState:UIControlStateHighlighted];

    return button;
}

@end
