//
//  GeoSlidesVC.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.12.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeoSlidesVC : UIViewController <UIScrollViewDelegate>

+ (GeoSlidesVC *) createWithImages: (NSArray *) imageNames;

@end
