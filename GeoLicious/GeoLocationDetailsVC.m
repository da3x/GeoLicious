//
//  GeoLocationDetailsVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 21.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocationDetailsVC.h"
#import "GeoLocationIconSV.h"
#import "GeoTableView.h"
#import "GeoLocationFoursquareVC.h"
#import "GeoTableViewCellSwitch.h"

@interface GeoLocationDetailsVC ()
@property (nonatomic, retain) IBOutlet UITextField *inputName;
@property (nonatomic, retain) IBOutlet UITextField *inputLocality;
@property (nonatomic, retain) IBOutlet UITextField *inputCountry;
@property (nonatomic, retain) IBOutlet UITextField *inputAddress;
@property (nonatomic, retain) IBOutlet UITextField *inputExtra;
@property (nonatomic, retain) IBOutlet UISwitch *switchCheckin;
@property (nonatomic, retain) IBOutlet UISwitch *useFoursquare;
@property (nonatomic, retain) IBOutlet UISwitch *useFacebook;
@property (nonatomic, retain) IBOutlet UISwitch *useTwitter;
@property (nonatomic, retain) IBOutlet UIStepper *stepperRadius;
@property (nonatomic, retain) IBOutlet UILabel *labelRadius;
@property (nonatomic, retain) IBOutlet MKMapView *map;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonSave;
@property (nonatomic, retain) IBOutlet GeoLocationIconSV *iconScroller;
@property (nonatomic, retain) IBOutlet UITextView *inputComment;
- (IBAction)save:(id)sender;
@end

@implementation GeoLocationDetailsVC

@synthesize location;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.buttonSave;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.inputName     setText:self.location.name];
    [self.inputLocality setText:self.location.locality];
    [self.inputCountry  setText:self.location.country];
    [self.inputAddress  setText:self.location.address];
    [self.inputExtra    setText:self.location.extra];
    self.inputComment.text = self.location.comment;

    [self.switchCheckin setOn:self.location.autoCheckin];
    [self.iconScroller setSelectedIcon:self.location.icon];

    [self.location initCoords];

    self.map.mapType = [[GeoDatabase sharedInstance] useSatelliteMode] ? MKMapTypeHybrid : MKMapTypeStandard;
    [self.map addAnnotation:self.location];

    // Der Radius Stepper aktualisiert auch die Map... daher am Ende...
    self.stepperRadius.minimumValue = 50;
    self.stepperRadius.maximumValue = 100000;
    self.stepperRadius.value = self.location.radius;
    [self updateRadius:self];
    [self centerMap:self];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Wenn wir nach dem Foursquare-Verknüpfen wieder zurück kommen, muss der Slider möglicherweise wieder abgestellt werden.
    // Sonst sind wir in einer Endlos-Schleife gefangen, die immer wieder den Dialog aufruft.
    if (!self.location.foursquareID) self.useFoursquare.on = NO;
    [self verifyFoursquare:self];
    
    [self updateRadius:self];
    [self centerMap:self];
}

- (IBAction) save: (id) sender
{
    [self.navigationController popViewControllerAnimated:YES];

    [self.location setName:self.inputName.text];
    [self.location setLocality:self.inputLocality.text];
    [self.location setCountry:self.inputCountry.text];
    [self.location setAddress:self.inputAddress.text];
    [self.location setExtra:self.inputExtra.text];
    self.location.comment = self.inputComment.text;
    [self.location setAutoCheckin:self.switchCheckin.on];
    [self.location setUseFoursquare:self.useFoursquare.on];
    [self.location setUseFacebook:self.useFacebook.on];
    [self.location setUseTwitter:self.useTwitter.on];
    [self.location setIcon:self.iconScroller.selectedIcon];
    [self.location setRadius:self.stepperRadius.value];

    [self.location saveCoords];
    [self.location refresh];
    
    [self.location updateGeoFence:NO];
    [[GeoDatabase sharedInstance] save];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id<MKAnnotation>) annotation
{
    static NSString *const kID = @"MyPin";
    MKAnnotationView *pin = [mapView dequeueReusableAnnotationViewWithIdentifier:kID];
    if (pin == nil) pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kID];
    pin.annotation = annotation;
    pin.enabled = YES;
    pin.draggable = YES;
    pin.selected = YES;
    pin.canShowCallout = YES;
    return pin;
}

-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay
{
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    if (self.switchCheckin.on) {
        circleView.strokeColor   = [UIColor redColor];
        circleView.fillColor     = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.25];
    }
    else {
        circleView.strokeColor   = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        circleView.fillColor     = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.1];
    }
    circleView.lineWidth     = 3;
    return circleView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    // Nur den Radius anpassen... kein erneutes zentrieren.
    [self updateRadius:self];
}

- (IBAction) verifyGeoFencingLimit:(id)sender
{
// Seit ich SLC nutze, kann ich darauf verzichten...
//    if (self.switchCheckin.on) {
//        if ([[GeoDatabase sharedInstance] numberOfGeoFences] >= 20) {
//            [self.switchCheckin setOn:NO animated:YES];
//            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!",nil)
//                                        message:NSLocalizedString(@"You've reached the maximum of 20 active auto check-ins. Please disable another location first.",nil)
//                                       delegate:nil
//                              cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
//        }
//    }
}

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
    if ([[GeoDatabase sharedInstance] useFoursquare] && self.useFoursquare.on) {
        if (!self.location.foursquareID) {
            GeoLocationFoursquareVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"FoursquareList"];
            controller.location = self.location;
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

- (IBAction) updateRadius:(id)sender
{
    float radius = self.stepperRadius.value;
    
    // Stepper neu justieren...
         if (radius <=  100) self.stepperRadius.stepValue = 10;
    else if (radius <=  500) self.stepperRadius.stepValue = 50;
    else if (radius <= 1000) self.stepperRadius.stepValue = 100;
    else                     self.stepperRadius.stepValue = 1000;

    // Radius korrigieren...
         if (radius <=  100) radius = radius - ((int)radius % 10);
    else if (radius <=  500) radius = radius - ((int)radius % 50);
    else if (radius <= 1000) radius = radius - ((int)radius % 100);
    else                     radius = radius - ((int)radius % 1000);

    self.stepperRadius.value = radius;
    
    [self.map removeOverlays:self.map.overlays];
    for (id<MKAnnotation> anno in self.map.annotations) {
        [self.map addOverlay:[MKCircle circleWithCenterCoordinate:[anno coordinate] radius:radius]];
    }
    // NOTE: Nicht neu zentrieren!!! Sonst geht das DnD der Pin wieder kaputt!

    [self updateLabelRadius];
}

- (void) updateLabelRadius
{
    float v = self.stepperRadius.value;
    if (v < 1000) self.labelRadius.text = [NSString stringWithFormat:@"%.0f m",  v];
    else          self.labelRadius.text = [NSString stringWithFormat:@"%.0f km", v / 1000];
}

- (IBAction) centerMap:(id)sender
{
    float radius = self.stepperRadius.value;
    for (id<MKAnnotation> anno in self.map.annotations) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([anno coordinate], radius * 2.25, radius * 2.25);
        [self.map setRegion:region animated:YES];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]
                     atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]
                     atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - UITableViewDataSource
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Die custom GeoTableViewCellSwitch müssen wir noch passend einrichten... das geht nicht direkt im InterfaceBuilder.
    if ([cell isKindOfClass:[GeoTableViewCellSwitch class]]) {
        if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                self.useFoursquare = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useFoursquare.on = [self.location useFoursquare];
                [self.useFoursquare addTarget:self action:@selector(verifyFoursquare:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 1) {
                self.useFacebook = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useFacebook.enabled = [self.location useFoursquare];
                self.useFacebook.on = [self.location useFacebook];
                [self.useFacebook addTarget:self action:@selector(verifyFoursquare:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 2) {
                self.useTwitter = ((GeoTableViewCellSwitch *)cell).switchButton;
                self.useTwitter.enabled = [self.location useFoursquare];
                self.useTwitter.on = [self.location useTwitter];
                [self.useTwitter addTarget:self action:@selector(verifyFoursquare:) forControlEvents:UIControlEventValueChanged];
            }
            // Ist das Feature vielleicht global abgeschaltet? Dann DISABLED... aber nicht verändern.
            if (![[GeoDatabase sharedInstance] useFoursquare]) {
                self.useFoursquare.enabled = NO;
                self.useFacebook.enabled = NO;
                self.useTwitter.enabled = NO;
            }
       }
    }
    
    return cell;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSLog(@"1");
    textView.enablesReturnKeyAutomatically = NO;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [textView becomeFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSLog(@"2");
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

@end
