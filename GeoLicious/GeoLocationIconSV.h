//
//  GeoLocationIconSV.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 07.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeoLocationIconSV : UIScrollView <UIGestureRecognizerDelegate>

- (NSString *) selectedIcon;
- (void) setSelectedIcon: (NSString *) str;

@end
