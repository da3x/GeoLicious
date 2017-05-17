//
//  GeoLocationsVC.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasterViewController.h"

@interface GeoLocationsVC : FasterViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIPrintInteractionControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic) SEL selector;
@end
