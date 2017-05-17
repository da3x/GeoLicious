//
//  GeoGroup.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 26.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoGroup.h"
#import "GeoDatabase.h"

@interface GeoGroup ()
@property (nonatomic, retain) NSMutableArray *array;
@end

@implementation GeoGroup

- (id) init
{
    self = [super init];
    if (self) {
        [self setArray:[NSMutableArray array]];
    }
    return self;
}

- (void) addObject: (id) o
{
    [self.array addObject:o];
}

- (NSUInteger) count
{
    return [self.array count];
}

- (BOOL) containsObject: (id) o
{
    return [self.array containsObject:o];
}

- (NSArray *) allObjects
{
    return self.array;
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D) coordinate
{
    float lat = 0;
    float lon = 0;
    for (GeoLocation *l in self.array) {
        lat += l.coordinate.latitude;
        lon += l.coordinate.longitude;
    }
    return CLLocationCoordinate2DMake(lat / self.array.count, lon / self.array.count);
}

- (NSString *) title
{
    NSString *str = @"";
    for (GeoLocation *l in self.array) {
        if ([str isEqualToString:@""] || [str isEqualToString:l.locality]) str = l.locality;
        else {
            str = @"";
            break;
        }
    }
    if ([str isEqualToString:@""]) {
        for (GeoLocation *l in self.array) {
            if ([str isEqualToString:@""] || [str isEqualToString:l.country]) str = l.country;
            else {
                str = @"";
                break;
            }
        }
    }
    if ([str isEqualToString:@""]) str = NSLocalizedString(@"Mixed",nil);
    return str;
}

- (NSString *) subtitle
{
    return [NSString stringWithFormat:NSLocalizedString(@"%i Locations",nil), self.array.count];
}

@end
