//
//  GeoLocationFoursquareVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.12.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocationFoursquareVC.h"
#import "GeoTableViewCellLocation.h"
#import "GeoTableView.h"
#import "FourSquareUtils.h"
#import "GeoCheckinDetailsVC.h"
#import "GeoTabVC.h"
#import "ImageUtils.h"

@interface GeoLocationFoursquareVC ()
@property (nonatomic, retain) NSArray *fourSquareLocations;
@property (nonatomic, retain) NSString *fourSquareStatus;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSTimer *timer;
@end

@implementation GeoLocationFoursquareVC

@synthesize location;

- (void) viewWillAppear:(BOOL)animated
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update:) userInfo:nil repeats:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self searchFourSquare:self.location];
    });
    
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (self.timer.isValid) [self.timer invalidate];
    [super viewWillDisappear:animated];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.fourSquareStatus = NSLocalizedString(@"Loading...", nil);
    
    if (iOS7) {
        self.view.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }
}

#pragma mark - Actions

- (IBAction) cancel: (id) sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Searching

- (void) searchFourSquare: (GeoLocation *) location
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.fourSquareLocations = [[FourSquareUtils sharedInstance] search:@""
                                                                    lat:self.location.latitude
                                                                    lon:self.location.longitude];
    self.fourSquareStatus = nil;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) update: (id) sender
{
    if (!self.fourSquareStatus && self.timer.isValid) [self.timer invalidate];
    if (self && self.tableView) [self.tableView reloadData];
}

#pragma mark - Checking in

- (void) updateWith: (GeoLocation *) loc
{
    // Wir übernehmen einige wenige Dinge...
    self.location.foursquareID = loc.foursquareID;
    self.location.icon = loc.icon;
    self.location.name = loc.name;
    self.location.useFoursquare = YES;
    [self.location refresh];
    // Dann wird gespeichert...
    [[GeoDatabase sharedInstance] save];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype1";
    
    if (indexPath.section == 0 && self.fourSquareStatus) {
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
    
    GeoLocation *loc = nil;
    if (indexPath.section == 0) loc = self.fourSquareLocations.count > indexPath.row ? [self.fourSquareLocations objectAtIndex:indexPath.row] : nil;
    if (!loc) return nil; // sicher ist sicher...

    return [self cellForTableView:tableView location:loc];
}

- (UITableViewCell *) cellForTableView: (UITableView *) tableView location: (GeoLocation *) loc
{
    static NSString *reUseID = @"GeoTableViewCellLocation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reUseID];
    if (!cell) cell = [[GeoTableViewCellLocation alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reUseID];
    
    [((GeoTableViewCellLocation *) cell) prepare:loc for:[[CLLocation alloc] initWithLatitude:self.location.latitude longitude:self.location.longitude]];
    cell.accessoryType = UITableViewCellAccessoryNone; // wir wollen da nix...
    
    if (iOS7) {
        cell.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return self.fourSquareStatus ? 1 : [self.fourSquareLocations count];
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return NSLocalizedString(@"Foursquare Venues", nil);
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) return NSLocalizedString(@"Search and select the appropriate Foursquare venue to update your existing location.", nil);
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GeoLocation *loc = nil;
    if (indexPath.section == 0) {
        if ([self.fourSquareLocations count] > indexPath.row) {
            loc = [self.fourSquareLocations objectAtIndex:indexPath.row];
        }
    }
    if (loc) [self updateWith:loc];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [searchBar resignFirstResponder];
    
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
