//
//  GeoSoundsVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 14.01.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import "GeoSoundsVC.h"
#import "GeoTableView.h"
#import <AudioToolbox/AudioToolbox.h>

@interface GeoSoundsVC ()

@end

@implementation GeoSoundsVC

-(void) reallyReloadData
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 2;
    return 21;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype1";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.imageView.image = [UIImage imageNamed:@"sound 1.png"];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Silence", nil);
            cell.imageView.image = [UIImage imageNamed:@"sound.png"];
        }
        if (indexPath.row == 1) cell.textLabel.text = @"Communicator";
    }
    else {
        if (indexPath.row == 0)  cell.textLabel.text = @"Bloom";
        if (indexPath.row == 1)  cell.textLabel.text = @"Concern";
        if (indexPath.row == 2)  cell.textLabel.text = @"Connected";
        if (indexPath.row == 3)  cell.textLabel.text = @"Full";
        if (indexPath.row == 4)  cell.textLabel.text = @"Gentle Roll";
        if (indexPath.row == 5)  cell.textLabel.text = @"High Boom";
        if (indexPath.row == 6)  cell.textLabel.text = @"Hollow";
        if (indexPath.row == 7)  cell.textLabel.text = @"Hope";
        if (indexPath.row == 8)  cell.textLabel.text = @"Jump Down";
        if (indexPath.row == 9)  cell.textLabel.text = @"Jump Up";
        if (indexPath.row == 10) cell.textLabel.text = @"Looking Down";
        if (indexPath.row == 11) cell.textLabel.text = @"Looking Up";
        if (indexPath.row == 12) cell.textLabel.text = @"Nudge";
        if (indexPath.row == 13) cell.textLabel.text = @"Picked";
        if (indexPath.row == 14) cell.textLabel.text = @"Puff";
        if (indexPath.row == 15) cell.textLabel.text = @"Realization";
        if (indexPath.row == 16) cell.textLabel.text = @"Second Glance";
        if (indexPath.row == 17) cell.textLabel.text = @"Stumble";
        if (indexPath.row == 18) cell.textLabel.text = @"Suspended";
        if (indexPath.row == 19) cell.textLabel.text = @"Turn";
        if (indexPath.row == 20) cell.textLabel.text = @"Unsure";
    }
    
    NSString *sound = [[GeoDatabase sharedInstance] sound];
    cell.accessoryType =  UITableViewCellAccessoryNone;
    if ([[NSString stringWithFormat:@"%@.aif", cell.textLabel.text] isEqualToString:sound]) {
        cell.accessoryType =  UITableViewCellAccessoryCheckmark;
    }
    if (!sound && indexPath.section == 0 && indexPath.row == 0) {
        cell.accessoryType =  UITableViewCellAccessoryCheckmark;
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
    if (section == 0) return NSLocalizedString(@"Sounds",nil);
    return NSLocalizedString(@"Soothing Alerts",nil);
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
    if (section == 0) return NSLocalizedString(@"Choose your favorite sound...",nil);
    return NSLocalizedString(@"Thanks to Adam Dachis on Lifehacker for providing this nice set of soothing alerts.",nil);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) [GeoDatabase sharedInstance].sound = nil;
        if (indexPath.row == 1) [GeoDatabase sharedInstance].sound = @"Communicator.aif";
    }
    else {
        if (indexPath.row == 0)  [GeoDatabase sharedInstance].sound = @"Bloom.aif";
        if (indexPath.row == 1)  [GeoDatabase sharedInstance].sound = @"Concern.aif";
        if (indexPath.row == 2)  [GeoDatabase sharedInstance].sound = @"Connected.aif";
        if (indexPath.row == 3)  [GeoDatabase sharedInstance].sound = @"Full.aif";
        if (indexPath.row == 4)  [GeoDatabase sharedInstance].sound = @"Gentle Roll.aif";
        if (indexPath.row == 5)  [GeoDatabase sharedInstance].sound = @"High Boom.aif";
        if (indexPath.row == 6)  [GeoDatabase sharedInstance].sound = @"Hollow.aif";
        if (indexPath.row == 7)  [GeoDatabase sharedInstance].sound = @"Hope.aif";
        if (indexPath.row == 8)  [GeoDatabase sharedInstance].sound = @"Jump Down.aif";
        if (indexPath.row == 9)  [GeoDatabase sharedInstance].sound = @"Jump Up.aif";
        if (indexPath.row == 10) [GeoDatabase sharedInstance].sound = @"Looking Down.aif";
        if (indexPath.row == 11) [GeoDatabase sharedInstance].sound = @"Looking Up.aif";
        if (indexPath.row == 12) [GeoDatabase sharedInstance].sound = @"Nudge.aif";
        if (indexPath.row == 13) [GeoDatabase sharedInstance].sound = @"Picked.aif";
        if (indexPath.row == 14) [GeoDatabase sharedInstance].sound = @"Puff.aif";
        if (indexPath.row == 15) [GeoDatabase sharedInstance].sound = @"Realization.aif";
        if (indexPath.row == 16) [GeoDatabase sharedInstance].sound = @"Second Glance.aif";
        if (indexPath.row == 17) [GeoDatabase sharedInstance].sound = @"Stumble.aif";
        if (indexPath.row == 18) [GeoDatabase sharedInstance].sound = @"Suspended.aif";
        if (indexPath.row == 19) [GeoDatabase sharedInstance].sound = @"Turn.aif";
        if (indexPath.row == 20) [GeoDatabase sharedInstance].sound = @"Unsure.aif";
    }

    [self playSound:[GeoDatabase sharedInstance].sound ofType:nil];
    [tableView reloadData];
    [[GeoDatabase sharedInstance] save];
}

#pragma mark - All the rest

- (void) playSound: (NSString *) name ofType: (NSString *) ext
{
    SystemSoundID audioEffect;
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &audioEffect);
        AudioServicesPlaySystemSound(audioEffect);
    }
    else {
        NSLog(@"File not found: %@", path);
    }
}

@end
