//
//  GeoTableViewCellLocation.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.09.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeoTableViewCellLocation : UITableViewCell <ImageCacheDelegate>

- (void) prepare: (GeoLocation *) l for: (CLLocation *) cl;

@end
