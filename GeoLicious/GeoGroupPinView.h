//
//  GeoGroupPinView.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoDatabase.h"
#import "GeoGroup.h"

@interface GeoGroupPinView : UIView

@property (nonatomic, retain) GeoGroup *locations;

- (id)initWithFrame:(CGRect)frame locations: (NSArray *) locs;

@end
