//
//  GeoTabVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoTabVC.h"

@interface GeoTabVC ()

@end

@implementation GeoTabVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    if (iOS7) {
        self.tabBar.translucent = NO;
        self.tabBar.barTintColor = [UIColor whiteColor];
        self.tabBar.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedIndex = [defaults integerForKey:@"GeoTabVC.last.selected.index"];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    // Wenn der gleiche Tab ein 2. mal selektiert wird, will ich, dass TableViews immer
    // abwechselnd nach ganz oben oder ganz unten scrollen. Das ganze aber nur dann, wenn
    // wir gerade auf der Root des NavigationControllers sind.
    if (self.selectedIndex == [self.viewControllers indexOfObject:viewController]) {
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nc = (UINavigationController *) viewController;
            if (nc.viewControllers.count == 1) {
                if ([nc.visibleViewController isKindOfClass:[UITableViewController class]]) {
                    UITableViewController *tc = (UITableViewController *)nc.visibleViewController;
                    float top = tc.tableView.tableHeaderView.bounds.size.height;
                    if (tc.tableView.bounds.origin.y > top) {
                        [tc.tableView scrollRectToVisible:CGRectMake(0, top, 1, 1)
                                                 animated:YES];
                    }
                    else {
                        [tc.tableView scrollRectToVisible:CGRectMake(0, tc.tableView.contentSize.height - 1, 1, 1)
                                                 animated:YES];
                    }
                }
            }
        }
    }
    return YES;
}

- (void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.selectedIndex forKey:@"GeoTabVC.last.selected.index"];
}

#pragma mark - UIViewController

// Im Landscape Mode wollen wir den TabBar verstecken und auch den StatusBar ausblenden...
// also einfach ein wenig Platz sparen.
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    BOOL landscape = orientation == UIInterfaceOrientationLandscapeLeft ||
                     orientation == UIInterfaceOrientationLandscapeRight;

    [[UIApplication sharedApplication] setStatusBarHidden:landscape withAnimation:UIStatusBarAnimationFade];
//    self.tabBar.hidden = landscape;
}

// Nach dem iOS automatisch gedreht hat, müssen wir den zusätzlichen Platz ausnutzen.
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation
{
//    float w = [UIScreen mainScreen].bounds.size.width;
//    float h = [UIScreen mainScreen].bounds.size.height;
//    UIView *transView = [self.view.subviews objectAtIndex:0];
//
//    if (self.tabBar.hidden) {
//        [transView setFrame:CGRectMake(0.0f, 0.0f, h, w)];
//    }
//    else {
//        [transView setFrame:CGRectMake(0.0f, 0.0f, w, h - self.tabBar.bounds.size.height)];
//    }
}

@end
