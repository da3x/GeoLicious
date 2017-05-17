//
//  GeoWebViewFAQ.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 16.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoWebViewFAQ.h"

@implementation GeoWebViewFAQ

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WhiteLeather.png"]];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"faq" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self loadRequest:request];
    }
    return self;
}

@end
