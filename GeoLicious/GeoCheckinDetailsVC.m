//
//  GeoCheckinDetailsVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 29.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoCheckinDetailsVC.h"
#import "DateUtils.h"
#import "GeoLocationsVC.h"
#import "GeoLocationDetailsVC.h"
#import "GeoDetailDisclosureButton.h"
#import "ImageUtils.h"
#import "GeoTableView.h"
#import "GeoTableViewCellSwitch.h"
#import "GeoLocationFoursquareVC.h"

@interface GeoCheckinDetailsVC ()
@property (nonatomic, retain) IBOutlet UITableViewCell *cellLocation;
@property (nonatomic, retain) IBOutlet UITableViewCell *cellDateIn;
@property (nonatomic, retain) IBOutlet UITableViewCell *cellDateOut;
@property (nonatomic, retain) IBOutlet UIDatePicker *datePickerIn;
@property (nonatomic, retain) IBOutlet UIDatePicker *datePickerOut;
@property (nonatomic, retain) IBOutlet UITextView *inputComment;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonSave;
@property (nonatomic, retain) IBOutlet UISwitch *useFoursquare;
@property (nonatomic, retain) IBOutlet UISwitch *useFacebook;
@property (nonatomic, retain) IBOutlet UISwitch *useTwitter;

@property (nonatomic, retain) NSDateFormatter *ff1;
@property (nonatomic, retain) NSDateFormatter *ff2;

@property (nonatomic, retain) NSDate *dateIn;
@property (nonatomic, retain) NSDate *dateOut;

@property (nonatomic, retain) GeoCheckin *selectedCheckin;
@property (nonatomic, retain) GeoLocation *selectedLocation;

@property (nonatomic) BOOL initialized;
@property (nonatomic) BOOL datePickerInShown;
@property (nonatomic) BOOL datePickerOutShown;

@end

@implementation GeoCheckinDetailsVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.buttonSave;
    
    self.ff1 = [[DateUtils sharedInstance] createFormatterDayMonthYearShort];
    self.ff2 = [[DateUtils sharedInstance] createFormatterHourMinute];

    self.initialized = NO;
    
    if (iOS7) {
        self.cellLocation.tintColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
    }
    
    self.datePickerInShown  = NO;
    self.datePickerOutShown = NO;
    
    UITapGestureRecognizer *gr1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    UITapGestureRecognizer *gr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    gr1.numberOfTapsRequired = 2;
    gr2.numberOfTapsRequired = 2;
    [self.datePickerIn  addGestureRecognizer:gr1];
    [self.datePickerOut addGestureRecognizer:gr2];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLocation) name:DB_SAVED object:nil];
}

- (void) handleTap: (UIGestureRecognizer *) gr
{
    if (gr.state == UIGestureRecognizerStateEnded) {
        if (gr.view == self.datePickerIn) {
            self.datePickerIn.datePickerMode = self.datePickerIn.datePickerMode == UIDatePickerModeDate ? UIDatePickerModeDateAndTime : UIDatePickerModeDate;
        }
        if (gr.view == self.datePickerOut) {
            self.datePickerOut.datePickerMode = self.datePickerOut.datePickerMode == UIDatePickerModeDate ? UIDatePickerModeDateAndTime : UIDatePickerModeDate;
        }
    }
}
    
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Wenn wir nach dem Foursquare-Verknüpfen wieder zurück kommen, muss der Slider möglicherweise wieder abgestellt werden.
    // Sonst sind wir in einer Endlos-Schleife gefangen, die immer wieder den Dialog aufruft.
    if (!self.selectedLocation.foursquareID) self.useFoursquare.on = NO;
    [self verifyFoursquare:self];
}

// Wenn wir die Location erst noch ermitteln, ändert sich noch mal die erste TableCell...
- (void) reloadLocation
{
    GeoLocation *loc = self.selectedLocation;
    if (!loc) loc = self.selectedCheckin.location;
    self.cellLocation.textLabel.text = loc.name;
    self.cellLocation.detailTextLabel.text = loc.detail;

    if ([loc.icon rangeOfString:@"http"].location == 0) {
        UIImage *img = [ImageCache imageForURL:loc.icon withDelegate:self];
        self.cellLocation.imageView.image = [[img negativeImage] scaleToWidth:32 height:32];
    }
    else if ([loc.icon rangeOfString:@"/"].location == 0) {
        NSString *path = [[[GeoDatabase sharedInstance] findPathLibrary] stringByAppendingPathComponent:loc.icon];
        self.cellLocation.imageView.image = [[[UIImage imageWithContentsOfFile:path] negativeImage] scaleToWidth:32 height:32];
    }
    else {
        self.cellLocation.imageView.image = [UIImage imageNamed:loc.icon];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateGUI];
    [self reloadLocation];

    [super viewWillAppear:animated];
}

- (void) setCheckin:(GeoCheckin *)c
{
    self.selectedCheckin = c;
    [self updateGUI];
}

- (void) updateGUI
{
    // Das machen wir nur 1x nach dem ersten Laden!
    if (self.initialized) return;
    
    self.initialized = YES;

    GeoLocation *loc = self.selectedLocation;
    if (!loc) {
        loc = self.selectedCheckin.location;
        self.selectedLocation = loc;
    }
        
    self.cellLocation.textLabel.text = loc.name;
    self.cellLocation.detailTextLabel.text = loc.detail;
    self.cellLocation.imageView.image = [UIImage imageNamed:loc.icon];
    self.cellLocation.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    self.cellDateIn.textLabel.text        = [self.ff1 stringFromDate:self.selectedCheckin.date];
    self.cellDateIn.detailTextLabel.text  = [self.ff2 stringFromDate:self.selectedCheckin.date];
    // Das Space ist wichtig, damit spätere Updates sichtbar werden!
    self.cellDateOut.textLabel.text       = self.selectedCheckin.left ? [self.ff1 stringFromDate:self.selectedCheckin.left] : @" ";
    self.cellDateOut.detailTextLabel.text = self.selectedCheckin.left ? [self.ff2 stringFromDate:self.selectedCheckin.left] : @" ";
    
    self.dateIn  = self.selectedCheckin.date;
    self.dateOut = self.selectedCheckin.left;
    
    self.inputComment.text = self.selectedCheckin.comment;
}

- (void) selectLocation: (GeoLocation *) location
{
    self.selectedLocation = location;
    self.useFoursquare.on = location.useFoursquare;
    self.useFacebook.on   = location.useFacebook;
    self.useTwitter.on    = location.useTwitter;
    [self verifyFoursquare:self];
}

- (IBAction)save:(id)sender
{
    if (self.dateOut && [[self.dateOut earlierDate:self.dateIn] isEqualToDate:self.dateOut]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!",nil)
                                    message:NSLocalizedString(@"The date of your checkout must be after your checkin!",nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
        return;
    }
    
    if (self.selectedLocation) self.selectedCheckin.location = self.selectedLocation;
    self.selectedCheckin.date    = self.dateIn;
    self.selectedCheckin.left    = self.dateOut;
    self.selectedCheckin.comment = self.inputComment.text;

    self.selectedCheckin.useFoursquare = self.useFoursquare.on;
    self.selectedCheckin.useFacebook   = self.useFacebook.on;
    self.selectedCheckin.useTwitter    = self.useTwitter.on;

    // Wir kopieren die letzten Einstellungen auch in den Ort rein...
    self.selectedCheckin.location.useFoursquare = self.useFoursquare.on;
    self.selectedCheckin.location.useFacebook   = self.useFacebook.on;
    self.selectedCheckin.location.useTwitter    = self.useTwitter.on;

    [self.selectedCheckin refresh];
    
    // Der Checkin könnte noch temporär sein... muss dann noch hinzugefügt werden.
    BOOL newChk = NO;
    if (![[[GeoDatabase sharedInstance] checkins] containsObject:self.selectedCheckin]) {
        [[[GeoDatabase sharedInstance] checkins] addObject:self.selectedCheckin];
        [[GeoDatabase sharedInstance] fireBadges:self.selectedCheckin];
        newChk = YES;
    }
    BOOL newLoc = NO;
    if (![[[GeoDatabase sharedInstance] locations] containsObject:self.selectedCheckin.location]) {
        [[[GeoDatabase sharedInstance] locations] addObject:self.selectedCheckin.location];
        newLoc = YES;
    }

    [self.navigationController popViewControllerAnimated:YES];

    [[GeoDatabase sharedInstance] save];
    if (newChk) [[NSNotificationCenter defaultCenter] postNotificationName:CHECKIN_ADDED object:self.selectedCheckin];
    if (newLoc) [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_ADDED object:self.selectedCheckin.location];
}

#define TAG_DATE_IN  1001
#define TAG_DATE_OUT 1002

- (IBAction)selectDate:(id)sender
{
    if ([sender isEqual:self.datePickerIn]) {
        self.dateIn = self.datePickerIn.date;
        self.cellDateIn.textLabel.text        = [self.ff1 stringFromDate:self.datePickerIn.date];
        self.cellDateIn.detailTextLabel.text  = [self.ff2 stringFromDate:self.datePickerIn.date];
    }
    if ([sender isEqual:self.datePickerOut]) {
        self.dateOut = self.datePickerOut.date;
        self.cellDateOut.textLabel.text        = [self.ff1 stringFromDate:self.datePickerOut.date];
        self.cellDateOut.detailTextLabel.text  = [self.ff2 stringFromDate:self.datePickerOut.date];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            GeoLocationsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LocationsList"];
            controller.selector = @selector(selectLocation:);
            controller.title = NSLocalizedString(@"Select", nil);
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
    if (indexPath.section == 1) {
        // Wir präsentieren den DatePicker durch eine minimierte TableViewCell...
        if (indexPath.row == 0) {
            self.datePickerInShown  = !self.datePickerInShown;
            self.datePickerOutShown = NO;
            if (self.dateIn) [self.datePickerIn setDate:self.dateIn animated:NO];
            self.datePickerIn.datePickerMode = UIDatePickerModeDateAndTime;
        }
        if (indexPath.row == 2) {
            self.datePickerInShown  = NO;
            self.datePickerOutShown = !self.datePickerOutShown;
            if (self.dateOut) [self.datePickerOut setDate:self.dateOut animated:NO];
            self.datePickerOut.datePickerMode = UIDatePickerModeDateAndTime;
        }
        [tableView beginUpdates];
        [tableView endUpdates];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]
                     atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        GeoLocationDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LocationDetails"];
        [controller setLocation:self.selectedLocation];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController pushViewController:controller animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]
                     atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

#pragma mark - UITableViewDataSource
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Die custom GeoTableViewCellSwitch müssen wir noch passend einrichten... das geht nicht direkt im InterfaceBuilder.
    if ([cell isKindOfClass:[GeoTableViewCellSwitch class]]) {
        if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                self.useFoursquare = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useFoursquare.on = [self.selectedCheckin useFoursquare];
                [self.useFoursquare addTarget:self action:@selector(verifyFoursquare:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 1) {
                self.useFacebook = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useFacebook.enabled = [self.selectedCheckin useFoursquare];
                self.useFacebook.on = [self.selectedCheckin useFacebook];
                [self.useFacebook addTarget:self action:@selector(verifyFoursquare:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 2) {
                self.useTwitter = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useTwitter.enabled = [self.selectedCheckin useFoursquare];
                self.useTwitter.on = [self.selectedCheckin useTwitter];
                [self.useTwitter addTarget:self action:@selector(verifyFoursquare:) forControlEvents:UIControlEventValueChanged];
            }
            // Ist das Feature vielleicht global abgeschaltet? Dann DISABLED... aber nicht verändern.
            if (![[GeoDatabase sharedInstance] useFoursquare]) {
                self.useFoursquare.enabled = NO;
                self.useFacebook.enabled = NO;
                self.useTwitter.enabled = NO;
            }
            // Wenn der CheckIn schon bei Foursquare ist, kann ich nix mehr ändern...
            if (self.selectedCheckin.didFoursquare) {
                self.useFoursquare.enabled = NO;
                self.useFacebook.enabled = NO;
                self.useTwitter.enabled = NO;
            }
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            return self.datePickerInShown ? self.datePickerIn.frame.size.height : 0.0;
        }
        if (indexPath.row == 3) {
            return self.datePickerOutShown ? self.datePickerOut.frame.size.height : 0.0;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 2) return YES;
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 1 && indexPath.row == 2) {
        self.dateOut = nil;
        // Das Space ist wichtig, damit spätere Updates sichtbar werden!
        self.cellDateOut.textLabel.text       = @" ";
        self.cellDateOut.detailTextLabel.text = @" ";
        [tableView setEditing:NO animated:YES];
    }
}

#pragma mark - Foursquare

- (IBAction) verifyFoursquare:(id)sender
{
    // Ist das Feature vielleicht global abgeschaltet? Dann DISABLED... aber nicht verändern.
    if (![[GeoDatabase sharedInstance] useFoursquare]) {
        self.useFoursquare.enabled = NO;
    }
    // Ohne Foursquare geht auch kein Facebook oder Twitter.
    if (!self.useFoursquare.on) {
        self.useFacebook.on = NO;
        self.useTwitter.on = NO;
    }
    // Wenn Foursquare aktiviert ist - auch global - dann prüfen wir den Link und aktivieren die Slider.
    if ([[GeoDatabase sharedInstance] useFoursquare] && self.useFoursquare.on && !self.selectedCheckin.didFoursquare) {
        if (!self.selectedLocation.foursquareID) {
            GeoLocationFoursquareVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"FoursquareList"];
            controller.location = self.selectedLocation;
            controller.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:controller animated:YES completion:nil];
        }
        self.useFacebook.enabled = YES;
        self.useTwitter.enabled = YES;
    }
    // Andernfalls noch mal DISABLED steuern.
    else {
        self.useFacebook.enabled = NO;
        self.useTwitter.enabled = NO;
    }
}


#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    textView.enablesReturnKeyAutomatically = NO;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - ImageCacheDelegate

- (void) imageChanged: (UIImage *) img forURL: (NSString *) url orPath: (NSString *) path
{
    self.cellLocation.imageView.image = [[img negativeImage] scaleToWidth:32 height:32];
}

@end
