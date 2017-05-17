//
//  GeoCheckInVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 19.08.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoCheckInVC.h"
#import "GeoTableViewCellLocation.h"
#import "GeoTableView.h"
#import "FourSquareUtils.h"
#import "GeoCheckinDetailsVC.h"
#import "GeoTabVC.h"
#import "ImageUtils.h"

@interface GeoCheckInVC ()
@property (nonatomic, retain) NSArray *yourLocations;
@property (nonatomic, retain) NSArray *fourSquareLocations;
@property (nonatomic, retain) NSString *yourStatus;
@property (nonatomic, retain) NSString *fourSquareStatus;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) CLLocation *location;
@end

@implementation GeoCheckInVC

- (void) viewWillAppear:(BOOL)animated
{
    [self setLocationManager:[[CLLocationManager alloc] init]];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([CLLocationManager locationServicesEnabled]) [self.locationManager startUpdatingLocation];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update:) userInfo:nil repeats:YES];
    
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if ([CLLocationManager locationServicesEnabled]) [self.locationManager stopUpdatingLocation];
    if (self.timer.isValid) [self.timer invalidate];
    [super viewWillDisappear:animated];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.yourStatus = NSLocalizedString(@"Loading...", nil);
    self.fourSquareStatus = NSLocalizedString(@"Loading...", nil);
    
    if (iOS7) {
        self.view.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }
}

- (void) presentVia: (UIViewController *) vc
{
    if (iPad) {
        // Auf dem iPad präsentieren wir das ganze als PopOver. Leider habe ich es noch nicht geschafft,
        // das ganze dann in einen NavigationController zu legen, der auch beim Accessory sichtbar bleibt.
        self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self];
        self.popOverController.popoverContentSize = CGSizeMake(320, 500);
        if (vc.navigationItem.rightBarButtonItem) {
            [self.popOverController presentPopoverFromBarButtonItem:vc.navigationItem.rightBarButtonItem
                                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                                           animated:YES];
            return;
        }
    }
//    if (iPhone) {
//        [vc.navigationController pushViewController:self animated:YES];
//        return;
//    }
    // Fallback...
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    [vc presentViewController:self animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction) cancel: (id) sender
{
    if (self.popOverController) [self.popOverController dismissPopoverAnimated:YES];
    else                        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Searching

- (void) searchFourSquare: (CLLocation *) location
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    self.fourSquareLocations = [[FourSquareUtils sharedInstance] search:@""
                                                                    lat:location.coordinate.latitude
                                                                    lon:location.coordinate.longitude];
    self.fourSquareStatus = nil;

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) searchDatabase: (CLLocation *) location
{
    self.yourLocations = [[GeoDatabase sharedInstance] findNearBy:location query:nil];
    self.yourStatus = nil;
}

- (void) update: (id) sender
{
    if (!self.yourStatus && !self.fourSquareStatus && self.timer.isValid) [self.timer invalidate];
    if (self && self.tableView) [self.tableView reloadData];
}

#pragma mark - Checking in

- (void) checkin: (GeoLocation *) location withDetails: (BOOL) details
{
    if ([[GeoDatabase sharedInstance] limitReached]) return;
    GeoCheckin *checkin = [GeoCheckin create:location];
    if (details) {
        GeoCheckinDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinDetails"];
        [controller setCheckin:checkin];

        GeoTabVC *tabVC = (GeoTabVC *) self.presentingViewController;
        [[tabVC.viewControllers objectAtIndex:tabVC.selectedIndex] pushViewController:controller animated:YES];
    }
    else {
        [[[GeoDatabase sharedInstance] checkins] addObject:checkin];

        BOOL newLoc = NO;
        if (![[[GeoDatabase sharedInstance] locations] containsObject:location]) {
            [[[GeoDatabase sharedInstance] locations] addObject:location];
            newLoc = YES;
        }
        
        [[GeoDatabase sharedInstance] save];
        [[NSNotificationCenter defaultCenter] postNotificationName:CHECKIN_ADDED object:checkin];
        if (newLoc) [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_ADDED object:location];
        [[GeoDatabase sharedInstance] fireBadges:checkin];
    }
    if (self.popOverController) [self.popOverController dismissPopoverAnimated:YES];
    else                        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.location = [locations lastObject];
    if ([NSLocalizedString(@"Loading...", nil) isEqualToString:self.yourStatus]) {
        self.yourStatus = NSLocalizedString(@"Searching...", nil);
        [self performSelector:@selector(searchDatabase:) withObject:[locations lastObject]];
    }
    if ([NSLocalizedString(@"Loading...", nil) isEqualToString:self.fourSquareStatus]) {
        self.fourSquareStatus = NSLocalizedString(@"Searching...", nil);
        [self performSelectorInBackground:@selector(searchFourSquare:) withObject:[locations lastObject]];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype1";
    
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell.imageView setImage:nil];
        [cell.textLabel setText:NSLocalizedString(@"New Location", nil)];
        [cell.detailTextLabel setText:NSLocalizedString(@"Adds a new entry...", nil)];
        // Da ich auf dem iPad PopOver nutze, klappt das nicht mit den Details... daher erstmal weg damit.
        cell.accessoryType = iPad ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDetailButton;
        if (iOS7) {
            cell.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        }
        return cell;
    }

    if (indexPath.section == 1 && self.yourStatus) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell.imageView setImage:nil];
        [cell.textLabel setText:self.yourStatus];
        [cell.detailTextLabel setText:nil];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (iOS7) {
            cell.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        }
        return cell;
    }

    if (indexPath.section == 2 && self.fourSquareStatus) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell.imageView setImage:nil];
        [cell.textLabel setText:self.fourSquareStatus];
        [cell.detailTextLabel setText:nil];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (iOS7) {
            cell.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        }
        return cell;
    }
    
    GeoLocation *location = nil;
    if (indexPath.section == 1) location = self.yourLocations.count       > indexPath.row ? [self.yourLocations       objectAtIndex:indexPath.row] : nil;
    if (indexPath.section == 2) location = self.fourSquareLocations.count > indexPath.row ? [self.fourSquareLocations objectAtIndex:indexPath.row] : nil;
    if (!location) return nil; // sicher ist sicher...

    return [self cellForTableView:tableView location:location];
}

- (UITableViewCell *) cellForTableView: (UITableView *) tableView location: (GeoLocation *) location
{
    static NSString *reUseID = @"GeoTableViewCellLocation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reUseID];
    if (!cell) cell = [[GeoTableViewCellLocation alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reUseID];
    
    [((GeoTableViewCellLocation *) cell) prepare:location for:self.location];

    // Da ich auf dem iPad PopOver nutze, klappt das nicht mit den Details... daher erstmal weg damit.
    cell.accessoryType = iPad ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDetailButton;

    if (iOS7) {
        cell.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    if (section == 1) return self.yourStatus ? 1 : [self.yourLocations count];
    if (section == 2) return self.fourSquareStatus ? 1 : [self.fourSquareLocations count];
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return NSLocalizedString(@"Start something new", nil);
    if (section == 1) return NSLocalizedString(@"Your Locations", nil);
    if (section == 2) return NSLocalizedString(@"Foursquare Venues", nil);
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GeoLocation *location = nil;
    if (indexPath.section == 0) {
        location = [GeoLocation create:self.location];
        [location setName:@"..."];
        [location queryLocation];
    }
    if (indexPath.section == 1) {
        if ([self.yourLocations count] > indexPath.row) {
            location = [self.yourLocations       objectAtIndex:indexPath.row];
        }
    }
    if (indexPath.section == 2) {
        if ([self.fourSquareLocations count] > indexPath.row) {
            location = [self.fourSquareLocations objectAtIndex:indexPath.row];
        }
    }
    if (location) [self checkin:location withDetails:NO];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GeoLocation *location = nil;
    if (indexPath.section == 0) {
        location = [GeoLocation create:self.location];
        [location setName:@"..."];
        [location queryLocation];
    }
    if (indexPath.section == 1) {
        if ([self.yourLocations count] > indexPath.row) {
            location = [self.yourLocations       objectAtIndex:indexPath.row];
        }
    }
    if (indexPath.section == 2) {
        if ([self.fourSquareLocations count] > indexPath.row) {
            location = [self.fourSquareLocations objectAtIndex:indexPath.row];
        }
    }
    if (location) [self checkin:location withDetails:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [searchBar resignFirstResponder];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.yourStatus = nil;
        self.yourLocations = [[GeoDatabase sharedInstance] findNearBy:self.location query:searchBar.text];
        if ([self.yourLocations count] == 0) {
            self.yourStatus = NSLocalizedString(@"Nothing found", nil);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.fourSquareStatus = nil;
        self.fourSquareLocations = [[FourSquareUtils sharedInstance] search:searchBar.text
                                                                        lat:self.location.coordinate.latitude
                                                                        lon:self.location.coordinate.longitude];
        if ([self.fourSquareLocations count] == 0) {
            self.fourSquareStatus = NSLocalizedString(@"Nothing found", nil);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [self.tableView reloadData];
        });
    });
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

@end

