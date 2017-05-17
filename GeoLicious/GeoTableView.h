//
//  GeoTableView.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeoTableView : UITableView

@property (nonatomic, retain) NSString *footer;

- (void) hideKeyboard: (id) sender;

@end
