//
//  GeoCheckinDetailsVC.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 29.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoDatabase.h"

@interface GeoCheckinDetailsVC : UITableViewController <UITextFieldDelegate, UITextViewDelegate, ImageCacheDelegate>

@property (nonatomic, strong) UIPopoverController *popOverController;

- (void) setCheckin:(GeoCheckin *)c;

@end
