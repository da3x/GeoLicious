//
//  GeoCheckinsVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoCheckinsVC.h"
#import "GeoTableViewCellCheckin.h"
#import "DateUtils.h"
#import "GeoCheckinDetailsVC.h"
#import "GeoDetailDisclosureButton.h"
#import "ImageUtils.h"
#import "GeoCheckInVC.h"
#import "GeoCache.h"

@interface GeoCheckinsVC ()
@property (nonatomic, strong) NSDateFormatter *formatHeader;
@end

@implementation GeoCheckinsVC

@synthesize searchBar;
@synthesize formatHeader;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.searchBar sizeToFit]; // iOS8 GM Fix...
    self.searchBar.selectedScopeButtonIndex = [GeoDatabase sharedInstance].groupingCheckins;
    if (self.tableView.numberOfSections > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markDirty) name:DID_FOURSQUARE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markDirty) name:CACHE_UPDATED  object:nil];
    
    if ([[GeoDatabase sharedInstance] groupingCheckins] == 0) formatHeader = [[DateUtils sharedInstance] createFormatterDayMonthYearLong];
    if ([[GeoDatabase sharedInstance] groupingCheckins] == 1) formatHeader = [[DateUtils sharedInstance] createFormatterMonthYearLong];
    if ([[GeoDatabase sharedInstance] groupingCheckins] == 2) formatHeader = [[DateUtils sharedInstance] createFormatterYear];
}

- (void) reallyReloadData
{
    ((GeoTableView *)self.tableView).footer = nil;
    [self.tableView reloadData];
}

- (void) viewWillAppear: (BOOL) animated
{
    // Wenn wir auf Grund des festen Filters den SearchBar wieder raus genommen haben,
    // müssen wir noch mal neu nach oben scrollen... sonst passt das nicht.
    // Außerdem ermöglichen wir dann den direkten CheckIn!
    // Seit iOS10 muss ich das immer machen... sonst sieht man erst die SearchBar...
    if (self.tableView.bounds.origin.y <= 0 && self.tableView.numberOfSections > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }

    [super viewWillAppear:animated];
}

#pragma mark - UITableViewDataSource

// Sucht passend zum IndexPath den richtigen CheckIn raus...
- (GeoCheckin *) checkin: (NSIndexPath *) indexPath
{
    NSArray<NSDate *> *segs = [[GeoCache shared] checkinsSegments:[[GeoDatabase sharedInstance] groupingCheckins]
                                                           filter:self.searchBar.text
                                                          reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (indexPath.section >= segs.count) return nil;
    
    NSArray<GeoCheckin *> *rows = [[GeoCache shared] checkins:[segs objectAtIndex:indexPath.section]
                                                     grouping:[[GeoDatabase sharedInstance] groupingCheckins]
                                                       filter:self.searchBar.text
                                                      reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (indexPath.row >= rows.count) return nil;

    return [rows objectAtIndex:indexPath.row];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
    NSArray<NSDate *> *segs = [[GeoCache shared] checkinsSegments:[[GeoDatabase sharedInstance] groupingCheckins]
                                                           filter:self.searchBar.text
                                                          reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (section >= segs.count) return 0;

    NSArray<GeoCheckin *> *rows = [[GeoCache shared] checkins:[segs objectAtIndex:section]
                                                     grouping:[[GeoDatabase sharedInstance] groupingCheckins]
                                                       filter:self.searchBar.text
                                                      reverse:[[GeoDatabase sharedInstance] reverseOrder]];

    return rows.count;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    static NSString *reUseID = @"GeoTableViewCellCheckin";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reUseID];
    if (!cell) cell = [[GeoTableViewCellCheckin alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reUseID];
    
    [((GeoTableViewCellCheckin *) cell) prepare:[self checkin:indexPath]];
    
    return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    NSArray<NSDate *> *segs = [[GeoCache shared] checkinsSegments:[[GeoDatabase sharedInstance] groupingCheckins]
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
    NSArray<NSDate *> *segs = [[GeoCache shared] checkinsSegments:[[GeoDatabase sharedInstance] groupingCheckins]
                                                           filter:self.searchBar.text
                                                          reverse:[[GeoDatabase sharedInstance] reverseOrder]];
    
    // Falls ein GeoCache#update dazwischen funkt, kann das passieren...
    if (section >= segs.count) return nil;
    
    return [formatHeader stringFromDate:[segs objectAtIndex:section]];
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
            NSMutableSet *c = [NSMutableSet set];
            NSMutableSet *l = [NSMutableSet set];
            NSTimeInterval secs = 0;
            for (GeoCheckin *one in [[GeoDatabase sharedInstance] checkins]) {
                if ([one matches:self.searchBar.text]) {
                    [c addObject:one];
                    [l addObject:one.location];
                    if (one.left) secs += one.left.timeIntervalSinceReferenceDate - one.date.timeIntervalSinceReferenceDate;
                }
            }
            if (c.count == 1 && l.count == 1) {
                ((GeoTableView *)tableView).footer = [NSString stringWithFormat:NSLocalizedString(@"checkins.footer.one", nil)];
            }
            else if (l.count == 1) {
                ((GeoTableView *)tableView).footer = [NSString stringWithFormat:NSLocalizedString(@"checkins.footer.single", nil),
                                                      c.count,
                                                      [[DateUtils sharedInstance] stringForDuration:secs]];
            }
            else {
                ((GeoTableView *)tableView).footer = [NSString stringWithFormat:NSLocalizedString(@"checkins.footer.many", nil),
                                                      c.count,
                                                      l.count,
                                                      [[DateUtils sharedInstance] stringForDuration:secs]];
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
        GeoCheckin *checkin = [self checkin:indexPath];
        [[[GeoDatabase sharedInstance] checkins] removeObject:checkin];
        [[GeoDatabase sharedInstance] save];

        [[NSNotificationCenter defaultCenter] postNotificationName:CHECKIN_REMOVED object:checkin];

        // Falls es der letzte CheckIn war, sollte auch dessen GeoFence wieder verschwinden!
        [checkin.location updateGeoFence:NO];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GeoCheckin *checkin = [self checkin:indexPath];

    // Wenn wir einen festen Filter haben und daher der SearchBar aus dem Header genommen wurde,
    // ändern wir das Verhalten der Cell ein wenig... und daher auch ihre Optik.
    if (!self.tableView.tableHeaderView) {
        GeoCheckinDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinDetails"];
        [controller setCheckin:checkin];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else {
        GeoCheckinsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinsList"];
        controller.navigationItem.title = checkin.location.name;
        controller.tableView.tableHeaderView = nil;
        [self.navigationController pushViewController:controller animated:YES];
        controller.searchBar.text = checkin.location.uuid;
        
        // Auf dem iPad werfen wir zudem einen Event, der die Map dazu bringt, an die Stelle des Ortes zu zoomen...
        if (iPad) {
            [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_SELECTED object:checkin.location];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    GeoCheckin *checkin = [self checkin:indexPath];
    GeoCheckinDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinDetails"];
    [controller setCheckin:checkin];
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

#define RANGE_THIS_WEEK  2001
#define RANGE_LAST_WEEK  2002
#define RANGE_THIS_MONTH 2003
#define RANGE_LAST_MONTH 2004
#define RANGE_EVERYTHING 2005

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    if (selectedScope < 3) {
        [[GeoDatabase sharedInstance] setGroupingCheckins:(int) selectedScope];
        [[GeoCoreData sharedInstance] setGroupingCheckins:selectedScope];
        
        if ([[GeoDatabase sharedInstance] groupingCheckins] == 0) formatHeader = [[DateUtils sharedInstance] createFormatterDayMonthYearLong];
        if ([[GeoDatabase sharedInstance] groupingCheckins] == 1) formatHeader = [[DateUtils sharedInstance] createFormatterMonthYearLong];
        if ([[GeoDatabase sharedInstance] groupingCheckins] == 2) formatHeader = [[DateUtils sharedInstance] createFormatterYear];

        [[GeoDatabase sharedInstance] save];

        [self markDirty];
    }
    if (selectedScope == 3) {
        self.searchBar.selectedScopeButtonIndex = [[GeoDatabase sharedInstance] groupingCheckins];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Print", nil)
                                                        message:NSLocalizedString(@"What timerange do you want to print?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"This Week", nil),
                                                                NSLocalizedString(@"Last Week", nil),
                                                                NSLocalizedString(@"This Month", nil),
                                                                NSLocalizedString(@"Last Month", nil),
                                                                NSLocalizedString(@"Everything", nil),
                                                                nil];
        alert.delegate = self;
        [alert show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex + 0) [self printContent:RANGE_THIS_WEEK];
    if (buttonIndex == alertView.firstOtherButtonIndex + 1) [self printContent:RANGE_LAST_WEEK];
    if (buttonIndex == alertView.firstOtherButtonIndex + 2) [self printContent:RANGE_THIS_MONTH];
    if (buttonIndex == alertView.firstOtherButtonIndex + 3) [self printContent:RANGE_LAST_MONTH];
    if (buttonIndex == alertView.firstOtherButtonIndex + 4) [self printContent:RANGE_EVERYTHING];
}

#pragma mark - IBActions

- (IBAction) checkIn: (id) sender
{
    if ([[GeoDatabase sharedInstance] limitReached]) return;
    GeoLocation *location = [[GeoDatabase sharedInstance] locationByUUID:self.searchBar.text];
    if (location) {
        GeoCheckinDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinDetails"];
        [controller setCheckin:[GeoCheckin create:location]];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else {
        GeoCheckInVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinList"];
        [controller presentVia:self];
    }
}

#pragma mark - AirPrint

- (void) printContent: (int) range
{
    UIAlertView *alert =  [[GeoDatabase sharedInstance] alertWithTitle:NSLocalizedString(@"Working!", nil)
                                                               message:NSLocalizedString(@"Give me a second to prepare the print job...", nil)
                                                              autohide:NO];

    DateUtils *du = [DateUtils sharedInstance];
    NSDate *min = nil;
    NSDate *max = nil;
    NSDate *now = [du date];
    if (range == RANGE_THIS_WEEK) {
        min = [du makeStartOfWeek:now];
        max = [du makeEndOfWeek  :now];
    }
    if (range == RANGE_LAST_WEEK) {
        min = [du makeStartOfWeek:[du date:now byAddingWeeks:-1]];
        max = [du makeEndOfWeek  :[du date:now byAddingWeeks:-1]];
    }
    if (range == RANGE_THIS_MONTH) {
        min = [du makeStartOfMonth:now];
        max = [du makeEndOfMonth  :now];
    }
    if (range == RANGE_LAST_MONTH) {
        min = [du makeStartOfMonth:[du date:now byAddingMonths:-1]];
        max = [du makeEndOfMonth  :[du date:now byAddingMonths:-1]];
    }
    
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
            NSMutableDictionary *locs = [NSMutableDictionary dictionary];

            NSString       *title = [self tableView:self.tableView titleForHeaderInSection:s];
            NSMutableArray *items = [NSMutableArray array];

            for (int r=0; r<[self tableView:self.tableView numberOfRowsInSection:s]; r++) {
                GeoCheckin *ccc = [self checkin:[NSIndexPath indexPathForRow:r inSection:s]];
                if (min && [du date:ccc.date isBefore:min]) continue;
                if (max && [du date:ccc.date isAfter :max]) continue;
                [items addObject:ccc];
            }

            // Wir drucken den Block nur, wenn wir auch was zu drucken haben!
            if (items.count > 0) {
                [body appendFormat:@"<tr><th colspan=3 class='header'>%@</th></tr>", title];
                for (GeoCheckin *ccc in items) {
                    [locs setObject:@"" forKey:ccc.location.uuid];
                    [body appendFormat:@"<tr><td><strong>%@</strong><br/>%@ %@ %@ %@</td><td>%@</td><td>%@</td></tr>",
                            ccc.location.name,
                            ccc.location.locality ? ccc.location.locality : @"",
                            ccc.location.country  ? ccc.location.country  : @"",
                            ccc.location.address  ? ccc.location.address  : @"",
                            ccc.location.extra    ? ccc.location.extra    : @"",
                            ccc.dateStringCheckIn,
                            ccc.dateStringCheckOut];
                }
                NSString *footer = [NSString stringWithFormat:NSLocalizedString(@"checkins.footer", nil), items.count, locs.count];
                [body appendFormat:@"<tr><th colspan=3 class='footer'>%@</th></tr>", footer];
                [body appendFormat:@"<tr><th colspan=3 class='footer'>&nbsp;</th></tr>"];
            }
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

