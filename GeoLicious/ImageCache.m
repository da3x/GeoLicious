#import "ImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@implementation ImageCache

#pragma mark - Singleton

static ImageCache *singleton;;

+ (ImageCache *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[ImageCache alloc] init];
    }
    return singleton;
}

#pragma mark - Public Methods

+ (UIImage *) imageForURL: (NSString *) url withDelegate: (id<ImageCacheDelegate>) delegate
{
    ImageCache *sss = [ImageCache sharedInstance];
    if (url) {
        NSString *path = [sss pathForImage:url];
        // Wenn das Bild schon existiert, liefern wir einfach das UIImage...
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
            return [UIImage imageWithContentsOfFile:path];
        }
        // Falls es noch nicht existiert, stoßen wir den Download an und liefern einen Dummy.
        [sss startDownload:url toPath:path withDelegate:delegate];
    }
    return [sss dummyImage];
}

+ (NSString *) pathForURL: (NSString *) url withDelegate: (id<ImageCacheDelegate>) delegate;
{
    if (!url) return nil;
    ImageCache *sss = [ImageCache sharedInstance];
    NSString *path = [sss pathForImage:url];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        // Falls es noch nicht existiert, stoßen wir den Download an...
        [sss startDownload:url toPath:path withDelegate:delegate];
    }
    // Den Pfad zum Bild liefern wir trotzdem schonmal.
    return path;
}

+ (NSArray *) allCachedFiles
{
    NSString *library  = [[GeoDatabase sharedInstance] findPathLibrary];
    NSString *cache    = [library stringByAppendingPathComponent:@"ImageCache"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:nil]) {
        return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cache error:nil];
    }
    return [NSArray array];
}

+ (UIImage *) imageForCache: (NSString *) filename
{
    ImageCache *sss = [ImageCache sharedInstance];
    if (filename) {
        NSString *library  = [[GeoDatabase sharedInstance] findPathLibrary];
        NSString *cache    = [library stringByAppendingPathComponent:@"ImageCache"];
        NSString *path     = [cache stringByAppendingPathComponent:filename];
        // Wenn das Bild schon existiert, liefern wir einfach das UIImage...
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
            return [UIImage imageWithContentsOfFile:path];
        }
    }
    return [sss dummyImage];
}

+ (void) clearCache
{
    NSString *library  = [[GeoDatabase sharedInstance] findPathLibrary];
    NSString *cache    = [library stringByAppendingPathComponent:@"ImageCache"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:cache error:nil];
    }
}

+ (void) reduceCache: (int) mb
{
    // TODO: so lange die ältesten Dateien weg werfen, bis der Platz klein genug ist.
}

+ (void) storeImage: (NSString *) path
{
    NSString *library  = [[GeoDatabase sharedInstance] findPathLibrary];
    NSString *cache    = [library stringByAppendingPathComponent:@"ImageCache"];
    // Wir prüfen ob der Pfad schon existiert und legen ihn bei Bedarf an.
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    // Das Bild legen wir im Cache immer unter dem gleichen Dateinamen ab.
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:[cache stringByAppendingPathComponent:path.lastPathComponent] error:nil];
}

#pragma mark - Interne Hilfsmethoden

- (void) startDownload: (NSString *) src toPath: (NSString *) path withDelegate: (id<ImageCacheDelegate>) delegate
{
    NSURL        *url     = [NSURL URLWithString:src];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    // Wir starten den Download und reagieren, sobald der fertig ist...
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error) {
                                   // Wir speichern das Bild im Cache...
                                   [data writeToFile:path atomically:YES];
                                   // Und senden unserem Delegate die Info...
                                   if (delegate) {
                                       [delegate imageChanged:[UIImage imageWithContentsOfFile:path]
                                                       forURL:src
                                                       orPath:path];
                                   }
                               }
                               else {
                                   // TODO: Im Fehlerfall könnte man eine andere Delegate Methode aufrufen...
                                   NSLog(@"ERROR: %@", error.localizedDescription);
                               }
                           }];
}

- (NSString *) pathForImage: (NSString *) src
{
    NSString *library  = [[GeoDatabase sharedInstance] findPathLibrary];
    NSString *cache    = [library stringByAppendingPathComponent:@"ImageCache"];
    // Wir prüfen ob der Pfad schon existiert und legen ihn bei Bedarf an.
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    // Das Bild legen wir im Cache immer unter einem konstanten Dateinamen ab.
    NSString *filename = [NSString stringWithFormat:@"%@.cached", [self md5:src]];
    return [cache stringByAppendingPathComponent:filename];
}

// Wir verwenden ein einheitliches Thumbnail für alle noch nicht vorhandenen Bilder.
- (UIImage *) dummyImage
{
    return [UIImage imageNamed:@"foursquare.png"];
}

#pragma mark - Methoden, die wir uns geklaut haben...

// Diese Methode liefert uns zu einem beliebigen String eine CheckSumme,
// die wir dann als Dateiname im Cache verwenden können.
- (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    //CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    CC_MD5( cStr, (int)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

#pragma mark - ImageCacheDelegate

- (void) imageChanged: (UIImage *) img forURL: (NSString *) url orPath: (NSString *) path
{
    NSLog(@"in imageChanged:%@ forURL:%@ orPath:%@", img, url, path);
}

#pragma mark - Tests

+ (void) test
{
    NSArray *urls = [NSArray arrayWithObjects:
                     @"http://lorempixel.com/512/512/sports/ImageCache-01",
                     @"http://lorempixel.com/512/512/sports/ImageCache-02",
                     @"http://lorempixel.com/512/512/sports/ImageCache-03",
                     @"http://lorempixel.com/512/512/sports/ImageCache-04",
                     @"http://lorempixel.com/512/512/sports/ImageCache-05",
                     @"http://lorempixel.com/512/512/sports/ImageCache-06",
                     @"http://lorempixel.com/512/512/sports/ImageCache-07",
                     @"http://lorempixel.com/512/512/sports/ImageCache-08",
                     @"http://lorempixel.com/512/512/sports/ImageCache-09",
                     @"http://lorempixel.com/512/512/sports/ImageCache-10",
                     nil];
    
    NSLog(@"##############################################################");
    NSLog(@"Test starting...");
    NSLog(@"##############################################################");
    for (NSString *url in urls) {
        NSLog(@"url   = %@", url);
        NSLog(@"image = %@", [ImageCache imageForURL:url withDelegate:[ImageCache sharedInstance]]);
        NSLog(@"cache = %@", [[ImageCache sharedInstance] pathForImage:url]);
    }
    NSLog(@"##############################################################");
    NSLog(@"Test finished...");
    NSLog(@"##############################################################");
}

@end
