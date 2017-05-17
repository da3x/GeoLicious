//
//  FourSquareUtils.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 10.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "FourSquareUtils.h"
#import "GeoLocation.h"
#import "GeoDatabase.h"

@implementation NSString (NSString_Extended)

- (NSString *) urlencode
{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        }
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        }
        else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end

@implementation FourSquareUtils

static FourSquareUtils *singleton;

+ (FourSquareUtils *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[FourSquareUtils alloc] init];
    }
    return singleton;
}

// Diese Methode liefert uns alle bei FourSquare bekannten Locations in einem Umkreis von 1000m um die angegebene Location. Das Ergebnis wird sinnvoller Weise gleich GeoLocations verpackt, in die man dann einchecken kann.
- (NSArray *) search: (NSString *) query lat: (float) lat lon: (float) lon
{
    NSMutableArray *results = [NSMutableArray array];
    NSString *base          = @"https://api.foursquare.com/v2/venues/search";
    NSString *clientID      = FOURSQUARE_CLIENT_ID;
    NSString *clientSecret  = FOURSQUARE_CLIENT_SECRET;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&intend=browse&radius=1000&v=20130310",
                                       base, lat, lon, clientID, clientSecret, [query urlencode]]];
    
    NSError      *error = nil;
    NSData       *data  = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error || !data) return nil;

    NSDictionary *json  = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

    if (!error) {
        for (NSDictionary *venue in [[json objectForKey:@"response"] objectForKey:@"venues"]) {
            [results addObject:[GeoLocation createWithFourSquare:venue]];
        }
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    return [results sortedArrayUsingComparator:^NSComparisonResult(GeoLocation *a, GeoLocation *b) {
        float m1 = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:a.latitude longitude:a.longitude]];
        float m2 = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:b.latitude longitude:b.longitude]];
        if (m1 < m2) return NSOrderedAscending;
        if (m1 > m2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

// Diese Methode synchronisiert einen CheckIn nach Foursquare...
- (BOOL) sync: (GeoCheckin *) checkin facebook: (BOOL) fb twitter: (BOOL) tw
{
    NSString *base = @"https://api.foursquare.com/v2/checkins/add";
    
    NSString *ccc = checkin.comment && checkin.comment.length > 0 ? checkin.comment : @"";
    if (ccc.length > 140) ccc = [NSString stringWithFormat:@"%@...", [ccc substringToIndex:137]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?venueId=%@&ll=%f,%f&oauth_token=%@&v=20131203&broadcast=public%@%@&shout=%@",
                                       base, checkin.location.foursquareID,
                                       checkin.location.latitude, checkin.location.longitude,
                                       [[GeoDatabase sharedInstance] oauthFoursquare],
                                       [[GeoDatabase sharedInstance] useFacebook] && checkin.useFacebook ? @",facebook" : @"",
                                       [[GeoDatabase sharedInstance] useTwitter] && checkin.useTwitter  ? @",twitter"  : @"",
                                       [ccc urlencode]]];
    
    NSError             *error    = nil;
    NSURLResponse       *response = nil;
    NSMutableURLRequest *request  = [NSMutableURLRequest requestWithURL:url];

    // Es muss ein POST Request sein!
    [request setHTTPMethod:@"POST"];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (!data || error) return NO;
    
    NSDictionary *json  = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (!error) {
        if ([[[json objectForKey:@"meta"] objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:200]]) {
            // Code 200 sehen wir als OK an... der Rest ist uns erst mal egal!
            return YES;
        }
    }
    
    return NO;
}

@end
