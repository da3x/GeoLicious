//
//  GeoWebViewVersions.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 17.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoWebViewVersions.h"

@implementation GeoWebViewVersions

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WhiteLeather.png"]];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"versions" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self loadRequest:request];
    }
    return self;
}

@end
