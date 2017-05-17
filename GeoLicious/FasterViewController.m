//
//  FasterViewController.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 09.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import "FasterViewController.h"

@interface FasterViewController ()
@property (atomic) BOOL dirty;
@property (atomic) BOOL active;
@property (atomic) BOOL visible;
@end

@implementation FasterViewController

- (void) debug
{
    NSLog(@"%@.dirty   = %i!", self.class, self.dirty);
    NSLog(@"%@.active  = %i!", self.class, self.active);
    NSLog(@"%@.visible = %i!", self.class, self.visible);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)  name:UIApplicationDidEnterBackgroundNotification  object:nil];

    self.dirty   = YES;
    self.active  = YES;
    self.visible = NO;
}

- (void) viewWillAppear: (BOOL) animated
{
    self.visible = YES;
    [self reloadData];

    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // NSLog(@"%@.viewDidAppear - TIMING?", self.class);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    self.visible = NO;
}

- (void) willEnterForeground
{
    self.active = YES;
    [self reloadData];
}

- (void) didEnterBackground
{
    self.active = NO;
}

- (void) markDirty
{
    self.dirty = YES;
    [self reloadData];
}

- (void) reloadData
{
    // NSLog(@"%@.reload... ?", self.class);
    // [self debug];
    if (self.dirty && self.active && self.visible) {
        // NSLog(@"%@.reload... YES!", self.class);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reallyReloadData];
            self.dirty = NO;
        });
    }
}

- (void) reallyReloadData
{
    NSLog(@"in FasterViewController.reallyReloadData()");
    NSLog(@"ACHTUNG! Diese Methode muss von der Subklasse überschrieben werden!");
}

@end
