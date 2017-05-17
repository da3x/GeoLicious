//
//  GeoRestoreVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.04.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoRestoreVC.h"
#import "GeoDatabase.h"
#import "DateUtils.h"
#import "GeoTableView.h"

@interface GeoRestoreVC ()

@end

@implementation GeoRestoreVC

-(void) reallyReloadData
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[GeoDatabase sharedInstance] backups] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype1";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSDateFormatter *df = [[DateUtils sharedInstance] createFormatterDayMonthYearHourMinuteShort];
    NSArray *backups = [[GeoDatabase sharedInstance] backups];
    NSDictionary *dict = [[GeoDatabase sharedInstance] backupDetails:[backups objectAtIndex:indexPath.row]];
    
    cell.textLabel.text = [backups objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ – %i kB",
                                    [df stringFromDate:[dict objectForKey:@"NSFileCreationDate"]],
                                    [[dict objectForKey:@"NSFileSize"] intValue] / 1024];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[GeoDatabase sharedInstance] delete:[[[GeoDatabase sharedInstance] backups] objectAtIndex:indexPath.row]];
        [self markDirty];
    }
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
    return NSLocalizedString(@"BackUps",nil);
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
    if ([[[GeoDatabase sharedInstance] backups] count] == 0) {
        return NSLocalizedString(@"You have no backups yet. You may create as many backups as you wish and restore them later.",nil);
    }
    return NSLocalizedString(@"These are all you backups. Tap one to restore or swipe to delete.",nil);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Restore BackUp?",nil)
                                                    message:NSLocalizedString(@"Do you really want to restore this backup? It will replace your current database!",nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"Restore",nil), nil];
    alert.tag = indexPath.row;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        if ([alertView.title isEqualToString:NSLocalizedString(@"Restore BackUp?",nil)]) {
            [[GeoDatabase sharedInstance] restore:[[[GeoDatabase sharedInstance] backups] objectAtIndex:alertView.tag]];
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
    }
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:alertView.tag inSection:0]
                                  animated:YES];
}

@end
