//
//  GeoLocationsVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoLocationsVC.h"
#import "GeoLocationDetailsVC.h"
#import "GeoTableViewCellLocation.h"
#import "GeoCheckinsVC.h"
#import "GeoDetailDisclosureButton.h"
#import "ImageUtils.h"
#import "GeoCache.h"
#import "GeoCheckInVC.h"

#define TAG_DELETE 1001

@interface GeoLocationsVC ()
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonEdit;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonDone;
@property (nonatomic, retain) GeoLocation *deleteLocation;
@end

@implementation GeoLocationsVC

@synthesize searchBar;
@synthesize selector;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.searchBar sizeToFit]; // iOS8 GM Fix...
    self.searchBar.selectedScopeButtonIndex = [[GeoDatabase sharedInstance] groupingLocations];
    if (self.tableView.numberOfSections > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markDirty) name:CACHE_UPDATED  object:nil];
}

- (void) reallyReloadData
{
    ((GeoTableView *)self.tableView).footer = nil;
    [self.tableView reloadData];
}

- (void) viewWillAppear: (BOOL) animated
{
    // Seit iOS10 muss ich das immer machen... sonst sieht man erst die SearchBar...
    if (self.tableView.bounds.origin.y <= 0 && self.tableView.numberOfSections > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
    
    [super viewWillAppear:animated];
}

#pragma mark - UITableViewDataSource

- (GeoLocation *) location: (NSIndexPath *) indexPath
{
    NSArray<NSString *> *segs = [[GeoCache shared] locationSegments:[[GeoDatabase sharedInstance] groupingLocations]
                                                             filter:self.searchBar.text
                                                            reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (indexPath.section >= segs.count) return nil;
    
    NSArray<GeoLocation *> *rows = [[GeoCache shared] locations:[segs objectAtIndex:indexPath.section]
                                                       grouping:[[GeoDatabase sharedInstance] groupingLocations]
                                                         filter:self.searchBar.text
                                                        reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (indexPath.row >= rows.count) return nil;
    
    return [rows objectAtIndex:indexPath.row];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
    NSArray<NSString *> *segs = [[GeoCache shared] locationSegments:[[GeoDatabase sharedInstance] groupingLocations]
                                                             filter:self.searchBar.text
                                                            reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (section >= segs.count) return 0;
    
    NSArray<GeoLocation *> *rows = [[GeoCache shared] locations:[segs objectAtIndex:section]
                                                       grouping:[[GeoDatabase sharedInstance] groupingLocations]
                                                         filter:self.searchBar.text
                                                        reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    return rows.count;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    static NSString *reUseID = @"GeoTableViewCellLocation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reUseID];
    if (!cell) cell = [[GeoTableViewCellLocation alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reUseID];
    
    [((GeoTableViewCellLocation *) cell) prepare:[self location:indexPath] for:nil];
        
    return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    NSArray<NSString *> *segs = [[GeoCache shared] locationSegments:[[GeoDatabase sharedInstance] groupingLocations]
                                                             filter:self.searchBar.text
                                                            reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    return segs.count;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section
{
    // PERFORMANCE! Wenn diese Methode nicht implementiert wird, berechnet die UITableView
    // die Höhe dynamisch anhand des Textes... und das dauert! Daher liefern wir hier einen
    // festen Wert. Die erste Section muss etwas größer sein, damit der SearchBar ausreichend
    // Platz hat.
    if (section == 0) {
        if (!self.tableView.tableHeaderView) return 16.0f;
        return 50.f;
    }
    return 30.0f;
}

//- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section
//{
//    // PERFORMANCE! Siehe heightForHeaderInSection...
//    if (section < tableView.numberOfSections - 1) return 0.0f;
//    return 60.0f;
//}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
    NSArray<NSString *> *segs = [[GeoCache shared] locationSegments:[[GeoDatabase sharedInstance] groupingLocations]
                                                             filter:self.searchBar.text
                                                            reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (section >= segs.count) return nil;
    
    return [segs objectAtIndex:section];
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
    NSInteger n = tableView.numberOfSections;
    
    // Es gibt einen Cache für den Footer...
    if (!((GeoTableView *)tableView).footer) {
        // Wir zählen die echten Objekte... das macht sich besser!
        // Da das aber teilweise viel Zeit kostet, machen wir das schön im Hintergrund...
        ((GeoTableView *)tableView).footer = NSLocalizedString(@"tmp.footer", nil);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableSet *l = [NSMutableSet set];
            for (GeoLocation *one in [[GeoDatabase sharedInstance] locations]) {
                if ([one matches:self.searchBar.text]) [l addObject:one];
            }
            if (l.count == 1) {
                ((GeoTableView *)tableView).footer = [NSString stringWithFormat:NSLocalizedString(@"locations.footer.one", nil)];
            }
            else {
                ((GeoTableView *)tableView).footer = [NSString stringWithFormat:NSLocalizedString(@"locations.footer.many", nil), l.count];
            }
            // Sobald das Ergebnis vorliegt, aktualisieren wir wieder die Darstellung.
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView reloadData];
            });
        });
    }

    // Nur die letzte Section bekommt den Footer...
    if (section < n - 1) return nil;
    return ((GeoTableView *)tableView).footer;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.deleteLocation = [self location:indexPath];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Location",nil)
                                                        message:NSLocalizedString(@"Do you really want to delete that Location? All check-ins will be deleted too!",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Delete",nil), nil];
        alert.tag = TAG_DELETE;
        [alert show];
    }
}

#pragma mark - UITableViewDelegate

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GeoLocation *location = [self location:indexPath];
    if (selector) {
        NSArray *vcs = self.navigationController.viewControllers;
        UIViewController *parent = [vcs objectAtIndex:[vcs indexOfObject:self] - 1];
        if ([parent respondsToSelector:self.selector]) [parent performSelector:self.selector withObject:location];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        GeoCheckinsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinsList"];
        controller.navigationItem.title = location.name;
        controller.tableView.tableHeaderView = nil;
        [self.navigationController pushViewController:controller animated:YES];
        controller.searchBar.text = location.uuid;
        
        // Auf dem iPad werfen wir zudem einen Event, der die Map dazu bringt, an die Stelle des Ortes zu zoomen...
        if (iPad) {
            [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_SELECTED object:location];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    GeoLocation *location = [self location:indexPath];
    GeoLocationDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LocationDetails"];
    [controller setLocation:location];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
    [self markDirty];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
    [self markDirty];
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    if (selectedScope < 2) {
        [[GeoDatabase sharedInstance] setGroupingLocations:(int) selectedScope];
        [[GeoCoreData sharedInstance] setGroupingLocations:selectedScope];
        [[GeoDatabase sharedInstance] save];
        [self markDirty];
    }
    if (selectedScope == 2) {
        self.searchBar.selectedScopeButtonIndex = [[GeoDatabase sharedInstance] groupingLocations];
        [self printContent];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == TAG_DELETE && buttonIndex == alertView.firstOtherButtonIndex) {
        [[GeoDatabase sharedInstance] removeLocation:self.deleteLocation];
        [[GeoDatabase sharedInstance] save];
        [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_REMOVED object:self.deleteLocation];
        [self markDirty];
    }
}

#pragma mark - IBActions

-(IBAction)toggleEditMode:(id)sender
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    self.navigationItem.rightBarButtonItem = self.tableView.editing ? self.barButtonDone : self.barButtonEdit;
}

- (IBAction) checkIn: (id) sender
{
    if ([[GeoDatabase sharedInstance] limitReached]) return;
    GeoCheckInVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinList"];
    [controller presentVia:self];
}

#pragma mark - AirPrint

- (void) printContent
{
    UIAlertView *alert =  [[GeoDatabase sharedInstance] alertWithTitle:NSLocalizedString(@"Working!", nil)
                                                               message:NSLocalizedString(@"Give me a second to prepare the print job...", nil)
                                                              autohide:NO];
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = @"GeoLicious";
    pic.printInfo = printInfo;
    
    // Den aufwendigen Teil machen wir im Hintergrund... der Nutzer soll kurz warten...
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableString *body = [NSMutableString stringWithString:@"<h1>GeoLicious</h1>"];
        [body appendFormat:@"<h2>%@</h2>", self.searchBar.text];
        [body appendFormat:@"<table>"];
        [body appendFormat:@"<tbody>"];
        for (int s=0; s<[self numberOfSectionsInTableView:self.tableView]; s++) {
            [body appendFormat:@"<tr><th colspan=3 class='header'>%@</th></tr>", [self tableView:self.tableView titleForHeaderInSection:s]];
            for (int r=0; r<[self tableView:self.tableView numberOfRowsInSection:s]; r++) {
                GeoLocation *ccc = [self location:[NSIndexPath indexPathForRow:r inSection:s]];
                [body appendFormat:@"<tr><td><strong>%@</strong><br/>%@ %@</td><td>%@</td><td>%@</td></tr>",
                 ccc.name,
                 ccc.address  ? ccc.address  : @"",
                 ccc.extra    ? ccc.extra    : @"",
                 ccc.locality ? ccc.locality : @"",
                 ccc.country  ? ccc.country  : @""];
            }
            [body appendFormat:@"<tr><th colspan=3 class='footer'>&nbsp;</th></tr>"];
        }
        [body appendFormat:@"</tbody>"];
        [body appendFormat:@"</table>"];
        
        NSString *css = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"print" withExtension:@"css"] encoding:NSUTF8StringEncoding error:nil];
        NSString *html = [NSString stringWithFormat:@"<html><head>%@</head><body>%@</body></html>",
                          [NSString stringWithFormat:@"<title>GeoLicious</title><style>%@</style>", css],
                          body];
        
        // Zurück in den Main-Thread...
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissWithClickedButtonIndex:0 animated:YES];
            
            UIMarkupTextPrintFormatter *htmlFormatter = [[UIMarkupTextPrintFormatter alloc]
                                                         initWithMarkupText:html];
            htmlFormatter.startPage = 0;
            htmlFormatter.contentInsets = UIEdgeInsetsMake(36, 36, 36, 36); // 1/2 inch margins
            pic.printFormatter = htmlFormatter;
            pic.showsPageRange = YES;
            
            void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
            ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
                if (!completed && error) {
                    NSLog(@"Printing could not complete because of error: %@", error);
                }
            };
            // Damit das auf dem iPad klappt, muss die View, die das auslöst sichtbar bleiben (PopOver).
            [pic presentFromRect:self.view.frame inView:self.view animated:YES completionHandler:completionHandler];
        });
    });
}

#pragma mark - UIPrintInteractionControllerDelegate

// noch nix... braucht man nicht zwingend.

@end
