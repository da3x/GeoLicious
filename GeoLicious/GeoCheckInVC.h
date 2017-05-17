//
//  GeoCheckInVC.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 19.08.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface GeoCheckInVC : UIViewController <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UIPopoverController *popOverController;

- (void) presentVia: (UIViewController *) vc;

@end
