//
//  GeoLocationIconSV.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 07.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocationIconSV.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageCache.h"

@interface GeoLocationIconSV ()
@property (nonatomic, retain) NSArray *icons;
@property (nonatomic, retain) NSString *selection;
@end

@implementation GeoLocationIconSV

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {

        
        NSArray *stock  = [NSArray arrayWithObjects:
                    
                      @"tree-2.png",
                      @"tree-1.png",

                      @"airfield.png",
                      @"airport.png",
                      @"bus.png",
                      @"aboveground-rail.png",
//                      @"belowground-rail.png",
//                      @"rail.png",
                      @"ferry.png",
                      @"harbor.png",
                      @"heliport.png",

                      @"commerical-building.png",
                      @"industrial-building.png",
                      @"warehouse.png",
                      @"town-hall.png",
                      @"monument.png",
                      @"museum.png",

                      @"bar.png",
                      @"beer.png",
                      @"cafe.png",
                      @"fast-food.png",
                      @"restaurant.png",

                      @"baseball.png",
                      @"basketball.png",
                      @"bicycle.png",
                      @"cricket.png",
                      @"football.png",
                      @"golf.png",
                      @"skiing.png",
                      @"soccer.png",
                      @"swimming.png",
                      @"tennis.png",

                      @"art-gallery.png",
                      @"campsite.png",
                      @"cemetery.png",
                      @"cinema.png",
                      @"college.png",
                      @"credit-card.png",
                      @"embassy.png",
                      @"fire-station.png",
                      @"fuel.png",
                      @"garden.png",
                      @"giraffe.png",
                      @"grocery-store.png",
                      @"hospital.png",
                      @"library.png",
                      @"lodging.png",
                      @"london-underground.png",
                      @"minefield.png",
                      @"pharmacy.png",

                      @"pitch.png",
                      @"school.png",
                      @"toilet.png",

                      @"police.png",
                      @"post.png",
                      @"prison.png",
                      @"roadblock.png",

                      @"religious-christian.png",
                      @"religious-islam.png",
                      @"religious-jewish.png",
                      
                      @"shop.png",
                      @"theatre.png",
                      @"trash.png",

                      nil];
        
        NSMutableArray *all = [NSMutableArray array];
        // Die Standard-Icons...
        [all addObjectsFromArray:stock];
        // Alle Icons an bekannten Locations...
        [all addObjectsFromArray:[[[GeoDatabase sharedInstance] allIconsHTTP] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
        // Alle Icons aus dem Cache...
        // [all addObjectsFromArray:[ImageCache allCachedFiles]];
        self.icons = all;
        
        float m = iOS7 ? 5 : 6;
        float x = 0;
        for (NSString *icon in self.icons) {
            
            UIImage *image;
            if ([icon hasSuffix:@".cached"]) image = [[[ImageCache imageForCache:icon] negativeImage] scaleToWidth:32 height:32];
            if ([icon hasPrefix:@"http"])    image = [[[ImageCache imageForURL:icon withDelegate:nil] negativeImage] scaleToWidth:32 height:32];
            else                             image = [UIImage imageNamed:icon];
            
            UIImageView *iv = [[UIImageView alloc] initWithImage:image];
            iv.userInteractionEnabled = YES;
            iv.bounds = CGRectMake(0, 0, 32, 32);
            iv.frame = CGRectMake(m+x, m, 32, 32);
            [iv addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)]];
            [self addSubview:iv];
            x += 32;
        }
        self.contentSize = CGSizeMake(m+x+m, m+32+m);
    }
    return self;
}

- (void) setSelectedIcon: (NSString *) str
{
    self.selection = str;
    NSInteger idx = [self.icons indexOfObject:str];
    if (idx >= 0 && idx < self.icons.count) {
        UIImageView *iv = [self.subviews objectAtIndex:idx];
        iv.backgroundColor = [UIColor colorWithRed:200/255.0 green:50/255.0 blue:0 alpha:1];
        iv.layer.cornerRadius = 3.0;
        [self scrollRectToVisible:CGRectMake((MAX(0,idx+3)*32), 0, 1, 1) animated:YES];
    }
}

- (NSString *) selectedIcon
{
    return self.selection;
}

- (void) onTap: (UITapGestureRecognizer *) sender
{
    for (UIImageView *iv in self.subviews) {;
        iv.backgroundColor = sender.view == iv ? [UIColor colorWithRed:200/255.0 green:50/255.0 blue:0 alpha:1] : [UIColor clearColor];
        iv.layer.cornerRadius = 3.0;
    }
    self.selection = [self.icons objectAtIndex:[self.subviews indexOfObject:sender.view]];
}



@end
