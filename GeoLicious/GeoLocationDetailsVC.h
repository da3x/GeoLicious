//
//  GeoLocationDetailsVC.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 21.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoDatabase.h"

@interface GeoLocationDetailsVC : UITableViewController <MKMapViewDelegate, UITextFieldDelegate>
@property (nonatomic, retain) GeoLocation *location;
@end
