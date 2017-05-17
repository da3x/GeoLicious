//
//  GeoMapVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 04.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoMapVC.h"
#import "GeoTabVC.h"
#import "GeoDatabase.h"
#import "GeoGroup.h"
#import "FourSquareUtils.h"
#import "GeoLocationPin.h"
#import "GeoGroupPin.h"
#import "GeoMapSearchView.h"
#import "GeoLocationDetailsVC.h"
#import "GeoCheckinsVC.h"
#import "GeoCheckInVC.h"
#import "GeoCheckinDetailsVC.h"
#import <AddressBook/AddressBook.h>

@interface GeoMapVC ()
@property (nonatomic, retain) IBOutlet MKMapView *map;
@property (nonatomic, retain) IBOutlet UISearchBar *search;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonCheckin;
@end

// Wir bringen dem MKMapItem ein wenig mehr bei...
// es kennt nämlich einen vernünftigen Namen, den wir in der
// Annotation anzeigen lassen können.
@interface MKMapItem (GeoLicious) <MKAnnotation>
- (CLLocationCoordinate2D) coordinate;
- (NSString *) title;
- (NSString *) subtitle;
@end
@implementation MKMapItem (GeoLicious)
- (CLLocationCoordinate2D) coordinate { return self.placemark.coordinate; }
- (NSString *) title { return self.name; }
- (NSString *) subtitle { return self.placemark.title; }
@end

@implementation GeoMapVC

- (void) viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addPin:)         name:LOCATION_ADDED    object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePin:)      name:LOCATION_REMOVED  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomToLocation:) name:LOCATION_SELECTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMap)       name:MAP_MODE_CHANGED  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMap)       name:DB_CHANGED        object:nil];

    [self.map addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleLongPress:)]];

    [self restoreRegion];
    [self performSelector:@selector(updateMap) withObject:nil afterDelay:1.0];

    self.search.hidden = YES;
}

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear:animated];
}

- (void) saveRegion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:self.map.region.center.latitude     forKey:@"map.region.center.latitude"];
    [defaults setFloat:self.map.region.center.longitude    forKey:@"map.region.center.longitude"];
    [defaults setFloat:self.map.region.span.latitudeDelta  forKey:@"map.region.span.latitudeDelta"];
    [defaults setFloat:self.map.region.span.longitudeDelta forKey:@"map.region.span.longitudeDelta"];
}
- (void) restoreRegion
{
    if ([[GeoDatabase sharedInstance] zoomOnStart]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        float cLat =[defaults floatForKey:@"map.region.center.latitude"];
        float cLon =[defaults floatForKey:@"map.region.center.longitude"];
        float sLat =[defaults floatForKey:@"map.region.span.latitudeDelta"];
        float sLon =[defaults floatForKey:@"map.region.span.longitudeDelta"];
        if (sLat > 0 && sLon > 0) {
            MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(cLat, cLon), MKCoordinateSpanMake(sLat, sLon));
            [self.map setRegion:region animated:NO];
        }
    }
}

- (void) viewWillAppear: (BOOL) animated
{
    self.map.showsUserLocation = YES;
    [self.search setHidden:YES];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear: (BOOL) animated
{
    self.map.showsUserLocation = NO;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) checkIn: (id) sender
{
    GeoCheckInVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinList"];
    [controller presentVia:self];
}

- (IBAction)search:(id)sender
{
    self.search.hidden = NO;
    [self.search becomeFirstResponder];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    for (id<MKAnnotation> anno in self.map.annotations) {
        if ([anno isKindOfClass:[MKUserLocation class]]) continue;
        if ([anno isKindOfClass:[MKMapItem class]]) {
            [self.map removeAnnotation:anno];
        }
    }
    searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
    self.search.hidden = YES;

    // Wir entfernen alle Markierungen, die zur Suche gehören.
    for (id<MKAnnotation> a in self.map.annotations) {
        if ([a isKindOfClass:[MKUserLocation class]]) continue;
        if ([a isKindOfClass:[MKMapItem class]]) {
            [self.map removeAnnotation:a];
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    MKLocalSearchRequest *req = [[MKLocalSearchRequest alloc] init];
    req.region = self.map.region;
    req.naturalLanguageQuery = searchBar.text;
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:req];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){

        if (error || [response.mapItems count] == 0) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Results",nil)
                                        message:nil
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return;
        }

        // Wir entfernen alle Markierungen, die zur Suche gehören.
        for (id<MKAnnotation> a in self.map.annotations) {
            if ([a isKindOfClass:[MKUserLocation class]]) continue;
            if ([a isKindOfClass:[MKMapItem class]]) {
                [self.map removeAnnotation:a];
            }
        }
        // Dann setzen wir die neuen.
        for (MKMapItem *item in response.mapItems) {
            [self.map addAnnotation:item];
        }
        [self zoomToFit:response.mapItems];

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void) addPin: (NSNotification *) event
{
    [self.map addAnnotation:event.object];
}

- (void) removePin: (NSNotification *) event
{
    [self.map removeAnnotation:event.object];
}

- (void) updateMap
{
    // Wir versuchen, das Update so weit es geht zu parallelisieren... dabei müssen wir immer
    // wieder zwischen Background- und Main-Thread wechseln.
    @synchronized(self) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            GeoDatabase *db = [GeoDatabase sharedInstance];

            if ( [db useSatelliteMode] && self.map.mapType != MKMapTypeHybrid)   self.map.mapType = MKMapTypeHybrid;
            if (![db useSatelliteMode] && self.map.mapType != MKMapTypeStandard) self.map.mapType = MKMapTypeStandard;
            
            // Wir entfernen alle Markierungen, die wir selbst auch hier setzen...
            // SYNC... nicht ASYNC! Sonst nimmt er parallel wieder Pins raus, wir schon wieder rein setzen.
//            dispatch_sync(dispatch_get_main_queue(), ^{
                for (id<MKAnnotation> a in self.map.annotations) {
                    if ([a isKindOfClass:[GeoLocation class]] && (db.groupPins || ![[db locations] containsObject:a])) [self.map removeAnnotation:a];
                    if ([a isKindOfClass:[GeoGroup class]]) [self.map removeAnnotation:a];
                }
                [self.map removeOverlays:self.map.overlays];
//            });
        
            float span = self.map.region.span.latitudeDelta;
            float diff = db.groupPins ? (span / 10.0) : 0.0;

            // Jetzt wird's etwas heikel... ich muss die Locations, die zu
            // eng zusammen liegen, zu einer Gruppe zusammenlegen. Dazu gehe
            // ich für jede Location das gesamte Array einmal durch und nehme
            // alle weiteren Locations, die dicht dran liegen, mit in die Gruppe
            // auf. Wenn die Gruppe am Ende nur ein Element hat, dann kommt die
            // Location direkt rein.
            NSMutableArray *known  = [NSMutableArray arrayWithArray:db.locations];
            NSMutableArray *placed = [NSMutableArray array];
            for (int i=0; i<known.count; i++) {
                
                // Dem UI kurz Zeit zum rendern geben... aber nur ohne Gruppierung!
//                if (!db.groupPins) [NSThread sleepForTimeInterval:0.005];
                
                GeoGroup *group = [[GeoGroup alloc] init];
                GeoLocation *loc = [known objectAtIndex:i];
                if ([placed containsObject:loc]) continue;
                [group addObject:loc];
                [placed addObject:loc];
                for (int k=i+1; k<known.count; k++) {
                    GeoLocation *nxt = [known objectAtIndex:k];
                    if ([placed containsObject:nxt]) continue;
                    float dLat = MAX(loc.latitude,  nxt.latitude)  - MIN(loc.latitude, nxt.latitude);
                    float dLon = MAX(loc.longitude, nxt.longitude) - MIN(loc.longitude, nxt.longitude);
                    if (dLat < (diff) && dLon < (diff)) {
                        [group addObject:nxt];
                        [placed addObject:nxt];
                    }
                }
                
                if ([group count] <= 1) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.map addAnnotation:loc];
                        if (loc.autoCheckin) {
                            [self.map addOverlay:[MKCircle circleWithCenterCoordinate:loc.coordinate radius:loc.radius]];
                        }
//                    });
                }
                else {
//                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.map addAnnotation:group];
//                    });
                }
                
            }
//        });
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

#pragma mark - MapDropPin

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) return;
    
    CGPoint point = [gestureRecognizer locationInView:self.map];
    CLLocationCoordinate2D coords = [self.map convertPoint:point toCoordinateFromView:self.map];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coords.latitude longitude:coords.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error) {
        if ([placemarks count] > 0) {
            // Die neue Markierung erstellen und rein...
            CLPlacemark *pm = [placemarks objectAtIndex:0];
            MKMapItem *annot = [[MKMapItem alloc] initWithPlacemark:
                                [[MKPlacemark alloc] initWithCoordinate:pm.location.coordinate
                                                      addressDictionary:pm.addressDictionary]];
            annot.name = pm.name;
            [self.map addAnnotation:annot];
            [self.map selectAnnotation:annot animated:YES];
        }
    }];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id<MKAnnotation>) annotation
{
    if ([annotation isKindOfClass:[GeoLocation class]]) {
        return [GeoLocationPin viewFor:annotation onMap:mapView];
    }
    if ([annotation isKindOfClass:[GeoGroup class]]) {
        return [GeoGroupPin viewFor:annotation onMap:mapView];
    }
    if ([annotation isKindOfClass:[MKMapItem class]]) {
        return [GeoMapSearchView viewFor:annotation onMap:mapView];
    }
    return nil;
}

-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay
{
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.strokeColor   = [UIColor redColor];
    circleView.fillColor     = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.25];
    circleView.lineWidth     = 3;
    return circleView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view isKindOfClass:[GeoLocationPin class]]) {
        GeoLocation *location = view.annotation;
        GeoCheckinsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinsList"];
        controller.navigationItem.title = location.name;
        controller.tableView.tableHeaderView = nil;
        [self.navigationController pushViewController:controller animated:YES];
        controller.searchBar.text = location.uuid;
        return;
    }
    
    if ([view isKindOfClass:[GeoMapSearchView class]]) {
        if ([[GeoDatabase sharedInstance] limitReached]) return;
        GeoLocation *location = [GeoLocation createWithName:view.annotation.title // schon mal korrekt setzen!
                                                        lat:view.annotation.coordinate.latitude
                                                        lon:view.annotation.coordinate.longitude];
        [location performSelectorInBackground:@selector(queryLocation) withObject:nil];
        GeoCheckin *checkin = [GeoCheckin create:location];
        GeoCheckinDetailsVC *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckinDetails"];
        [controller setCheckin:checkin];
        [self.navigationController pushViewController:controller animated:YES];
        return;
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[GeoGroupPin class]]) {
        [self zoomToFit:[((GeoGroupPin *)view).locations allObjects]];
    }
//    self.barButtonCheckin.tintColor = [view isKindOfClass:[GeoLocationPin class]] ? [UIColor colorWithRed:160.0/255.0 green:20.0/255.0 blue:0 alpha:1] : nil;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
//    self.barButtonCheckin.tintColor = nil;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if ([[GeoDatabase sharedInstance] groupPins]) [self updateMap];
    [self saveRegion];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
}

#pragma mark - Zoom

- (IBAction) zoomIn: (id) sender
{
    if (self.map.showsUserLocation) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.map.userLocation.location.coordinate, 1000, 1000);
        [self.map setRegion:region animated:YES];
    }
}

- (IBAction) zoomOut: (id) sender
{
    if ([[[GeoDatabase sharedInstance] locations] count] > 0) {
        [self.map setRegion:[[GeoDatabase sharedInstance] bestFit] animated:YES];
    }
}

- (void) zoomToLocation: (NSNotification *) event
{
    if ([event.object isKindOfClass:[GeoLocation class]]) {
        [self zoomToFit:[NSArray arrayWithObject:event.object]];
    }
}

- (void) zoomToFit:(NSArray *)mapItems
{
    if ([mapItems count] == 0) return;
    
    CLLocationCoordinate2D tlc; // TOP LEFT COORD
    tlc.latitude = -90;
    tlc.longitude = 180;
    
    CLLocationCoordinate2D brc; // BOTTOM RIGHT COORD
    brc.latitude = 90;
    brc.longitude = -180;

    if ([[mapItems lastObject] isKindOfClass:[MKMapItem class]]) {
        for (MKMapItem *item in mapItems) {
            tlc.longitude = fmin(tlc.longitude, item.placemark.coordinate.longitude);
            tlc.latitude  = fmax(tlc.latitude,  item.placemark.coordinate.latitude);
            brc.longitude = fmax(brc.longitude, item.placemark.coordinate.longitude);
            brc.latitude  = fmin(brc.latitude,  item.placemark.coordinate.latitude);
        }
    }
    if ([[mapItems lastObject] isKindOfClass:[GeoLocation class]]) {
        for (GeoLocation *item in mapItems) {
            tlc.longitude = fmin(tlc.longitude, item.coordinate.longitude);
            tlc.latitude  = fmax(tlc.latitude,  item.coordinate.latitude);
            brc.longitude = fmax(brc.longitude, item.coordinate.longitude);
            brc.latitude  = fmin(brc.latitude,  item.coordinate.latitude);
        }
    }
    
    float min = mapItems.count > 1 ? 0 : 0.25;
    
    MKCoordinateRegion region;
    region.center.latitude = tlc.latitude - (tlc.latitude - brc.latitude) * 0.5;
    region.center.longitude = tlc.longitude + (brc.longitude - tlc.longitude) * 0.5;
    region.span.latitudeDelta = fabs(tlc.latitude - brc.latitude + min) * 1.2;
    region.span.longitudeDelta = fabs(brc.longitude - tlc.longitude + min) * 1.2;
    
    [self.map setRegion:[self.map regionThatFits:region] animated:YES];
}

@end
