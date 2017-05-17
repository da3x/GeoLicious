#import <Foundation/Foundation.h>

@protocol ImageCacheDelegate <NSObject>

// Wenn ein angefragtes Bild sich änder (z.B. weil es herunter geladen wurde),
// informieren wir unser Delegate darüber und liefern das neue Bild gleich mit.
- (void) imageChanged: (UIImage *) img forURL: (NSString *) url orPath: (NSString *) path;

@end

@interface ImageCache : NSObject <ImageCacheDelegate>

// Liefert ein UIImage... das kann auch ein temporäres Bild sein, welches später aktualisiert wird.
+ (UIImage *) imageForURL: (NSString *) url withDelegate: (id<ImageCacheDelegate>) delegate;

// Liefert den vollen Pfad zum Image im Dateisystem... das kann auch ein temporäres Bild sein,
// welches später aktualisiert wird.
+ (NSString *) pathForURL: (NSString *) url withDelegate: (id<ImageCacheDelegate>) delegate;

// Liefert alle bisher geladenen Cache Dateien als Dateinamen.
+ (NSArray *) allCachedFiles;
// Liefert zu einer Cache Datei das daraus resultierende Image.
+ (UIImage *) imageForCache: (NSString *) filename;

// Hier wird der gesamte Cache verworfen.
+ (void) clearCache;

// Wenn der Cache auf eine bestimmte Größe reduziert werden soll,
// dann ist diese Methode die richige. Die maximale Größe wird in MB übergeben.
+ (void) reduceCache: (int) mb;

// Um die OFFLINE Bilder aus dem Bundle in den Cache zu legen.
+ (void) storeImage: (NSString *) path;

// Ein einfacher Test...
+ (void) test;

@end
