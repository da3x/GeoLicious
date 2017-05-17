//
//  GeoSettingsVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoSettingsVC.h"
#import "GeoDatabase.h"
#import "GeoTableView.h"
#import "GeoTableViewCellSwitch.h"
#import "CoreDataMigration.h"
#import "InAppPurchaseUtils.h"
#import "CloudUtils.h"

@interface GeoSettingsVC ()
@property (nonatomic, retain) IBOutlet UISwitch *autoCheckin;
@property (nonatomic, retain) IBOutlet UISwitch *useNotifications;
@property (nonatomic, retain) IBOutlet UISwitch *useIconBadge;
@property (nonatomic, retain) IBOutlet UISwitch *clearShortEvents;
@property (nonatomic, retain) IBOutlet UISwitch *autoBackup;
@property (nonatomic, retain) IBOutlet UISwitch *groupPins;
@property (nonatomic, retain) IBOutlet UISwitch *satelliteMode;
@property (nonatomic, retain) IBOutlet UISwitch *useFoursquare;
@property (nonatomic, retain) IBOutlet UISwitch *useFacebook;
@property (nonatomic, retain) IBOutlet UISwitch *useTwitter;
@property (nonatomic, retain) IBOutlet UISwitch *reverseOrder;
@property (nonatomic, retain) IBOutlet UISwitch *zoomOnStart;
@property (nonatomic, retain) IBOutlet UISwitch *iCloudDrive;
@end

@implementation GeoSettingsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Einige Einstellungen werden asynchron verändert... z.B. Foursquare...
    // damit wir dann trotzdem den richtigen Stand anzeigen,
    // brauchen wir noch eine entsprechende Benachrichtigung.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(markDirty)
                                                 name:DB_SAVED
                                               object:[GeoDatabase sharedInstance]];
}

- (void) reallyReloadData
{
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            NSString *sss = [[GeoDatabase sharedInstance] sound];
            if (sss) {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Sound : %@", nil),
                                       [sss stringByReplacingOccurrencesOfString:@".aif" withString:@""]];
            }
            else {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Sound : %@", nil),
                                       NSLocalizedString(@"Silence", nil)];
            }
        }
    }

    // Die Version lese ich inzwischen dynamisch aus...
    if (indexPath.section == 4) {
        if (indexPath.row == 2) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",
                                   NSLocalizedString(@"Version", nil),
                                   [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        }
    }
    
    // Die custom GeoTableViewCellSwitch müssen wir noch passend einrichten... das geht nicht direkt im InterfaceBuilder.
    if ([cell isKindOfClass:[GeoTableViewCellSwitch class]]) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                self.autoCheckin = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.autoCheckin.on = [[GeoDatabase sharedInstance] useAutoCheckin];
                [self.autoCheckin addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 1) {
                self.useNotifications = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useNotifications.on = [[GeoDatabase sharedInstance] useNotifications];
                [self.useNotifications addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 3) {
                self.useIconBadge = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useIconBadge.on = [[GeoDatabase sharedInstance] useIconBadge];
                [self.useIconBadge addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 4) {
                self.clearShortEvents = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.clearShortEvents.on = [[GeoDatabase sharedInstance] clearShortEvents];
                [self.clearShortEvents addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
        }
        if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                self.useFoursquare = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useFoursquare.on = [[GeoDatabase sharedInstance] useFoursquare];
                [self.useFoursquare addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 1) {
                self.useFacebook = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useFacebook.enabled = [[GeoDatabase sharedInstance] useFoursquare];
                self.useFacebook.on = [[GeoDatabase sharedInstance] useFacebook];
                [self.useFacebook addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 2) {
                self.useTwitter = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useTwitter.enabled = [[GeoDatabase sharedInstance] useFoursquare];
                self.useTwitter.on = [[GeoDatabase sharedInstance] useTwitter];
                [self.useTwitter addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
        }
        if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                self.groupPins = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.groupPins.on = [[GeoDatabase sharedInstance] groupPins];
                [self.groupPins addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 1) {
                self.satelliteMode = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.satelliteMode.on = [[GeoDatabase sharedInstance] useSatelliteMode];
                [self.satelliteMode addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 2) {
                self.reverseOrder = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.reverseOrder.on = [[GeoDatabase sharedInstance] reverseOrder];
                [self.reverseOrder addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 3) {
                self.zoomOnStart = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.zoomOnStart.on = [[GeoDatabase sharedInstance] zoomOnStart];
                [self.zoomOnStart addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
        }
        if (indexPath.section == 3) {
            if (indexPath.row == 0) {
                self.iCloudDrive = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.iCloudDrive.on = [[GeoDatabase sharedInstance] useCloudDrive];
                [self.iCloudDrive addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 1) {
                self.autoBackup = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.autoBackup.on = [[GeoDatabase sharedInstance] useAutoBackup];
                [self.autoBackup addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            }
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3) {
        if (indexPath.row == 2) {
            [[GeoDatabase sharedInstance] backup];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Safety first!",nil)
                                        message:NSLocalizedString(@"Another backup has been stored. You may access it via iTunes filesharing or restore if necessary.",nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
        }
        if (indexPath.row == 4) {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            [mc setSubject:@"GeoLicious Export"];
            [mc setMessageBody:NSLocalizedString(@"Settings.Export.Database.Body", nil) isHTML:NO];
            [mc addAttachmentData:[NSKeyedArchiver archivedDataWithRootObject:[GeoDatabase sharedInstance]]
                         mimeType:@"application/data"
                         fileName:[[[DateUtils sharedInstance] createFormatter:@"'Export-'yyyyMMdd'.db'"]
                                   stringFromDate:[[DateUtils sharedInstance] date]]];
            [mc addAttachmentData:[[[GeoDatabase sharedInstance] exportGPX] dataUsingEncoding:NSUTF8StringEncoding]
                         mimeType:@"application/gpx+xml"
                         fileName:[[[DateUtils sharedInstance] createFormatter:@"'Export-'yyyyMMdd'.gpx'"]
                                   stringFromDate:[[DateUtils sharedInstance] date]]];
            [mc addAttachmentData:[[[GeoDatabase sharedInstance] exportCSV] dataUsingEncoding:NSUTF8StringEncoding]
                         mimeType:@"text/csv"
                         fileName:[[[DateUtils sharedInstance] createFormatter:@"'Export-'yyyyMMdd'.csv'"]
                                   stringFromDate:[[DateUtils sharedInstance] date]]];
            [self presentViewController:mc animated:YES completion:NULL];
        }
    }
    if (indexPath.section == 4) {
        if (indexPath.row == 3) {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            [mc setSubject:@"GeoLicious feedback..."];
            [mc setMessageBody:@"Hi Daniel,\n\n..." isHTML:NO];
            [mc setToRecipients:[NSArray arrayWithObject:@"geolicious@da3x.de"]];
            [self presentViewController:mc animated:YES completion:NULL];
        }
        if (indexPath.row == 4) {
            NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/GeoLiciousApp"];
            NSURL *twitter  = [NSURL URLWithString:@"twitter://user?screen_name=GeoLiciousApp"];
            if ([[UIApplication sharedApplication] canOpenURL:tweetbot]) {
                [[UIApplication sharedApplication] openURL:tweetbot];
            }
            else if ([[UIApplication sharedApplication] canOpenURL:twitter]) {
                [[UIApplication sharedApplication] openURL:twitter];
            }
            else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/GeoLiciousApp"]];
            }
        }
        if (indexPath.row == 5) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:LINK_APPSTORE_FULL]];
        }
    }
    if (indexPath.section == 5) {
        if (indexPath.row == 0) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Database",nil)
                                        message:NSLocalizedString(@"Do you really want to reset the database?",nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                              otherButtonTitles:NSLocalizedString(@"Reset",nil), nil] show];
        }
        if (indexPath.row == 1) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Demo Data",nil)
                                        message:NSLocalizedString(@"Do you really want to switch to demo data?",nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                              otherButtonTitles:NSLocalizedString(@"Reset",nil), nil] show];
        }
        if (indexPath.row == 2) {
            if ([[InAppPurchaseUtils sharedInstance] verifyProduct:PRODUCT_ID_PRO]) {
                [self alertWithTitle:NSLocalizedString(@"inapp.success.title", nil)
                             message:NSLocalizedString(@"inapp.success.message", nil)
                            autohide:3];
            }
            else {
                [[InAppPurchaseUtils sharedInstance] restoreProducts];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Alerts

- (UIAlertView *) alertWithTitle: (NSString *) title message: (NSString *) msg autohide: (int) secs
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:secs > 0 ? nil : NSLocalizedString(@"inapp.button.okay", nil)
                                          otherButtonTitles:nil];
    [alert show];
    if (secs > 0) [self performSelector:@selector(hideAlert:) withObject:alert afterDelay:secs];
    return alert;
}

- (void) hideAlert: (UIAlertView *) alert
{
    if (alert) [alert dismissWithClickedButtonIndex:0 animated:YES];
}

#pragma mark - IBActions

- (IBAction) toggle:(id)sender
{
    if (sender == self.autoCheckin) {
        [[GeoDatabase sharedInstance] setUseAutoCheckin:((UISwitch *)sender).on];
        [[GeoDatabase sharedInstance] updateGeoFencesAll];
        [[GeoDatabase sharedInstance] testSettings];

        // Falls gewünscht, aktivieren wir SLC... also Significant Location Changes.
        if ([[GeoDatabase sharedInstance] useAutoCheckin]) {
            [[GeoUtils sharedInstance] startSLC];
        }
        else {
            [[GeoUtils sharedInstance] stopSLC];
        }
    }
    if (sender == self.useNotifications) {
        [[GeoDatabase sharedInstance] setUseNotifications:((UISwitch *)sender).on];
        if ([[GeoDatabase sharedInstance] useNotifications]) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            [[GeoDatabase sharedInstance] testSettings];
        }
    }
    if (sender == self.useIconBadge) {
        [[GeoDatabase sharedInstance] setUseIconBadge:((UISwitch *)sender).on];
        if ([[GeoDatabase sharedInstance] useIconBadge]) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            [[GeoDatabase sharedInstance] testSettings];
        }
    }
    if (sender == self.clearShortEvents) {
        [[GeoDatabase sharedInstance] setClearShortEvents:((UISwitch *)sender).on];
    }
    if (sender == self.iCloudDrive) {
        if (((UISwitch *)sender).on) {
            [[GeoDatabase sharedInstance] backup];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Use iCloud Drive",nil)
                                        message:NSLocalizedString(@"Where is the data you want to use for GeoLicious?",nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                              otherButtonTitles:NSLocalizedString(@"iCloud",nil),
                                                NSLocalizedString(@"Device",nil),
                                                nil] show];
        }
        else {
            [[GeoDatabase sharedInstance] setUseCloudDrive:NO];
        }
    }
    if (sender == self.autoBackup) {
        [[GeoDatabase sharedInstance] setUseAutoBackup:((UISwitch *)sender).on];
    }
    if (sender == self.groupPins) {
        [[GeoDatabase sharedInstance] setGroupPins:((UISwitch *)sender).on];
        [[NSNotificationCenter defaultCenter] postNotificationName:MAP_MODE_CHANGED object:nil];
    }
    if (sender == self.satelliteMode) {
        [[GeoDatabase sharedInstance] setUseSatelliteMode:((UISwitch *)sender).on];
        [[NSNotificationCenter defaultCenter] postNotificationName:MAP_MODE_CHANGED object:nil];
    }
    if (sender == self.useFoursquare) {
        if (((UISwitch *)sender).on) {
            // Jetzt soll authentifiziert werden...
            [[GeoDatabase sharedInstance] connectFoursquare:self];
        }
        else {
            [[GeoDatabase sharedInstance] disconnectFoursquare];
            // Wenn wir Foursquare abschalten, muss auch Facebook und Twitter aus gehen!
            [[GeoDatabase sharedInstance] setUseFacebook:NO];
            [[GeoDatabase sharedInstance] setUseTwitter:NO];
            self.useFacebook.on = NO;
            self.useTwitter.on = NO;
        }
        // Die beiden Switches sind nur dann aktiv, wenn FourSquare auch aktiv ist.
        self.useFacebook.enabled = [[GeoDatabase sharedInstance] useFoursquare];
        self.useTwitter.enabled = [[GeoDatabase sharedInstance] useFoursquare];
    }
    if (sender == self.useFacebook) {
        [[GeoDatabase sharedInstance] setUseFacebook:((UISwitch *)sender).on];
    }
    if (sender == self.useTwitter) {
        [[GeoDatabase sharedInstance] setUseTwitter:((UISwitch *)sender).on];
    }
    if (sender == self.reverseOrder) {
        [[GeoDatabase sharedInstance] setReverseOrder:((UISwitch *)sender).on];
    }
    if (sender == self.zoomOnStart) {
        [[GeoDatabase sharedInstance] setZoomOnStart:((UISwitch *)sender).on];
    }
    [[GeoDatabase sharedInstance] save];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        if ([alertView.title isEqualToString:NSLocalizedString(@"Reset Database",nil)]) {
            [[GeoDatabase sharedInstance] backup];
            [[GeoDatabase sharedInstance] reset];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Database",nil)
                                        message:NSLocalizedString(@"The database has been reset. You may restore the backup that has just been stored for your safety.",nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }
        if ([alertView.title isEqualToString:NSLocalizedString(@"Demo Data",nil)]) {
            [[GeoDatabase sharedInstance] backup];
            [[GeoDatabase sharedInstance] demo];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Demo Data",nil)
                                        message:NSLocalizedString(@"The database just loaded demo data. You may restore the backup that has just been stored for your safety.",nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }
    }
    if ([alertView.title isEqualToString:NSLocalizedString(@"Use iCloud Drive",nil)]) {
        // iCloud : In diesem Fall müssen wir die Datenbank von dort laden...
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [CloudUtils updateCloudDrive]; // Aktualisiert die Dateiliste und startet Downloads...
            [[GeoDatabase sharedInstance] setUseCloudDrive:YES];
            [GeoDatabase reload]; // lädt dann automatisch aus der Cloud...
        }
        // Device : In diesem Fall lassen wir einfach alles wie es ist und überschreiben damit automatisch die Version in der Cloud...
        if (buttonIndex == alertView.firstOtherButtonIndex + 1) {
            [[GeoDatabase sharedInstance] setUseCloudDrive:YES];
        }
        [self.tableView reloadData];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
