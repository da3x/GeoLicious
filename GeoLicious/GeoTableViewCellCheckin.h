//
//  GeoTableViewCellCheckin.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.09.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeoTableViewCellCheckin : UITableViewCell <ImageCacheDelegate>

- (void) prepare: (GeoCheckin *) c;

@end
