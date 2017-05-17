//
//  FourSquareUtils.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 10.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FourSquareUtils : NSObject

+ (FourSquareUtils *) sharedInstance;

- (NSArray *) search: (NSString *) query lat: (float) lat lon: (float) lon;

- (BOOL) sync: (GeoCheckin *) checkin facebook: (BOOL) fb twitter: (BOOL) tw;

@end
