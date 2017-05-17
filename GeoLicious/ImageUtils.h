//
//  ImageUtils.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 24.08.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (NegativeImage)
- (UIImage *)negativeImage;
- (UIImage *) scaleToWidth: (float) w height: (float) h;
@end

@interface ImageUtils : NSObject

@end
