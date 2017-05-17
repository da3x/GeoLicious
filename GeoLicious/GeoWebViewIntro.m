//
//  GeoWebViewIntro.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 16.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoWebViewIntro.h"

@implementation GeoWebViewIntro

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WhiteLeather.png"]];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"intro" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self loadRequest:request];
    }
    return self;
}

@end
