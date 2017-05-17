//
//  GeoDetailDisclosureButton.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 24.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoTableView.h"

@interface GeoDetailDisclosureButton : UIButton

+ (id) buttonForTableView: (GeoTableView *) tableView;
+ (id) button;

@end
