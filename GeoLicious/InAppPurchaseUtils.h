#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// --------------------------------------------------------------
// Diese ID muss immer an das jeweilige Produkt angepasst werden!
// Hier ist der InAppPurchase aus iTunes Connect einzutragen!
// --------------------------------------------------------------
#define PRODUCT_ID_PRO @"GeoLiciousPro"

// Ab welcher Version wurde von PAID auf INAPP umgestellt?
#define FIRST_INAPP_VERSION @"1.7"

// Hier steuern wir zentral das Limit für die freie Test-Version...
// auch wenn das in den Utils selbst nicht direkt gebraucht wird.
#define TRIAL_LIMIT 10

// Das ist ein EVENT / Notification, auf die man reagieren kann, wenn man das möchte.
#define IN_APP_PURCHASE_SUCCESS @"IN_APP_PURCHASE_SUCCESS"

@interface InAppPurchaseUtils : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// Damit alles funktioniert, muss man beim Application Start immer auch einmal auf dieses Singleton zugreifen!
// Dabei werden ein paar Dinge initialisiert, die man unbedingt benötigt.

+ (InAppPurchaseUtils *) sharedInstance;

- (void) requestProduct: (NSString *) productID;
- (void) restoreProducts;

- (BOOL) verifyProduct: (NSString *) productID;

- (id) originalPurchasedVersion;
- (id) originalPurchasedDate;

- (BOOL) isEarlyUser;

- (void) goProAlert;
- (void) trialOverAlert;

@end
