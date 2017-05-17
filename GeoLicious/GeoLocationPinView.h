//
//  GeoMapPinView.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoDatabase.h"

@interface GeoLocationPinView : UIView

@property (nonatomic, retain) GeoLocation *location;

- (id)initWithFrame:(CGRect)frame location: (GeoLocation *) loc;

@end
