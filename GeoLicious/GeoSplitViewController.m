//
//  GeoSplitViewController.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 27.04.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import "GeoSplitViewController.h"

@interface GeoSplitViewController ()
@property (nonatomic, weak) UIPopoverController *popOverController;
@end

@implementation GeoSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    self.popOverController = pc;
    barButtonItem.title = NSLocalizedString(@"Menu", nil);
    UIViewController *vc = ((UINavigationController*)self.viewControllers.lastObject).visibleViewController;
    [vc.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
}

-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UIViewController *vc = ((UINavigationController*)self.viewControllers.lastObject).visibleViewController;
    [vc.navigationItem setLeftBarButtonItem:nil animated:YES];
}

@end
