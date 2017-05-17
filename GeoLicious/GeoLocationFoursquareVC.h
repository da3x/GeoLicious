//
//  GeoLocationFoursquareVC.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.12.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface GeoLocationFoursquareVC : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, retain) GeoLocation *location;

@end
