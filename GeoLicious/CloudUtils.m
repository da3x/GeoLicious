//
//  CloudUtils.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 05.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import "CloudUtils.h"

@interface CloudUtils ()
@property(nonatomic, strong) NSMetadataQuery *query;
@end

@implementation CloudUtils

static CloudUtils *singleton;

+ (CloudUtils *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[CloudUtils alloc] init];
    }
    return singleton;
}

+ (void) updateCloudDrive
{
    NSLog(@"in updateCloudDrive");

    CloudUtils *utils = [CloudUtils sharedInstance];
    
    // Wichtig: Das Query muss STRONG gebunden sein... sonst ist das zu früh wieder weg!
    utils.query              = [[NSMetadataQuery alloc] init];
    utils.query.searchScopes = [NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope,nil];
    utils.query.predicate    = [NSPredicate predicateWithFormat:@"%K like[cd] %@", NSMetadataItemFSNameKey, @"*.db"];
    
    [[NSNotificationCenter defaultCenter] addObserver:utils
                                             selector:@selector(queryDidFinishGathering:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:utils.query];

    [[NSNotificationCenter defaultCenter] addObserver:utils
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:utils.query];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Das scheitert, falls schon ein solches Query läuft... was aber nicht schlimm ist.
        [utils.query startQuery];
    });
}

// Diese Methode kommt ins Spiel, wenn es zu viele Ergebnisse auf einmal sind...
// Dann werden einige davon schon gemeldet, bevor das Query ganz fertig ist...
- (void) queryDidUpdate: (NSNotification *) notification
{
    NSLog(@"in queryDidUpdate:");
    
    NSMetadataQuery *query = [notification object];
    [query disableUpdates];
    NSError *error = nil;
    for (NSMetadataItem *item in [query results]) {
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        NSString *status = nil;
        if ([url getResourceValue:&status forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] == YES) {
            if ([status isEqualToString:NSURLUbiquitousItemDownloadingStatusNotDownloaded] == YES) {
                // NSLog(@"starting download of %@", url);
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error];
            }
        }
    }
    [query enableUpdates];
}

- (void) queryDidFinishGathering: (NSNotification *) notification
{
    NSLog(@"in queryDidFinishGathering:");
    
    NSMetadataQuery *query = [notification object];
    [query disableUpdates];
    [query stopQuery];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:query];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification          object:query];
    
    NSError *error = nil;
    for (NSMetadataItem *item in [query results]) {
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        // NSLog(@"starting download of %@", url);
        [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error];
    }
}

@end
