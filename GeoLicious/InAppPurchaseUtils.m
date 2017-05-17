#import "InAppPurchaseUtils.h"

@interface InAppPurchaseUtils ()
@property (nonatomic, strong) SKProduct *requestedProduct;
@property (nonatomic, strong) UIAlertView *visibleAlert; // normalerweise weak (mit ARC)
@end

@implementation InAppPurchaseUtils

#define ALERT_WELCOME 1000
//#define ALERT_LIMIT   1001
#define ALERT_PAYMENT 1002
#define ALERT_NOTICE  1003
#define ALERT_GO_PRO  1004

static InAppPurchaseUtils *singleton;

+ (InAppPurchaseUtils *) sharedInstance
{
    if (singleton == nil) {
        singleton = [[InAppPurchaseUtils alloc] init];
        
        // Beim ersten Aufruf des Singleton registrieren wir uns selbst als Observer für Transactions.
        [[SKPaymentQueue defaultQueue] addTransactionObserver:singleton];
        
        [singleton initPurchasedVersion];
        [[NSNotificationCenter defaultCenter] addObserver:singleton selector:@selector(onAppStart:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    }
    return singleton;
}

#pragma mark - Unsere eigenen Methoden...

- (void) requestProduct: (NSString *) productID
{
    NSLog(@"in requestProduct:");
    self.visibleAlert = [self alertWithTitle:NSLocalizedString(@"inapp.please.wait", nil)
                                     message:NSLocalizedString(@"inapp.connecting", nil)
                                    autohide:10];
    
    NSSet *set = [NSSet setWithObject:productID];
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void) restoreProducts
{
    NSLog(@"in restoreProducts");
    self.visibleAlert = [self alertWithTitle:NSLocalizedString(@"inapp.please.wait", nil)
                                     message:NSLocalizedString(@"inapp.connecting", nil)
                                    autohide:10];

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL) verifyProduct: (NSString *) productID
{
    NSLog(@"in verifyProduct:");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:[NSString stringWithFormat:@"in.app.purchase.%@", productID]];
}

- (id) originalPurchasedVersion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"in.app.purchase.original.version"];
}

- (id) originalPurchasedDate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"in.app.purchase.original.date"];
}

#pragma mark - Private Methoden

- (void) requestPayment: (SKProduct *) product
{
    NSLog(@"in requestPayment:");
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) displayStoreUI: (SKProduct *) product
{
    if (self.visibleAlert) [self.visibleAlert dismissWithClickedButtonIndex:0 animated:YES];
    self.requestedProduct = product;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"inapp.purchase.title", nil)
                                                    message:[NSString stringWithFormat:@"%@\n%@", product.localizedTitle, product.localizedDescription]
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"inapp.button.cancel", nil)
                                          otherButtonTitles:[self formattedPrice:product], nil];
    alert.tag = ALERT_PAYMENT;
    [alert show];
}

- (NSString *) formattedPrice: (SKProduct *) product
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
    return formattedPrice;
}

- (void) activateProduct: (NSString *) productID
{
    NSLog(@"in activateProduct:");
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setBool:YES forKey:[NSString stringWithFormat:@"in.app.purchase.%@", productID]];
    [storage synchronize];
    
    [self alertWithTitle:NSLocalizedString(@"inapp.success.title", nil)
                 message:NSLocalizedString(@"inapp.success.message", nil)
                autohide:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IN_APP_PURCHASE_SUCCESS object:productID];
}

// Siehe http://stackoverflow.com/q/25508520/173689
- (void) initPurchasedVersion
{
    NSLog(@"in initPurchasedVersion");
    
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    id ov = [storage objectForKey:@"in.app.purchase.original.version"];
    id od = [storage objectForKey:@"in.app.purchase.original.date"];
    
    if (!ov || !od) {
        NSURL   *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];

        if (receiptURL) {
            NSData  *receipt    = [NSData dataWithContentsOfURL:receiptURL];
            
            if (receipt) {
                // Create the JSON object that describes the request
                NSError      *error           = nil;
                NSDictionary *requestContents = @{@"receipt-data": [receipt base64EncodedStringWithOptions:0]};
                NSData       *requestData     = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
                
                if (requestData && !error) {
                    // Create a POST request with the receipt data
                    NSURL               *storeURL     = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
                    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
                    
                    [storeRequest setHTTPMethod:@"POST"];
                    [storeRequest setHTTPBody:requestData];
                    
                    [NSURLConnection sendAsynchronousRequest:storeRequest
                                                       queue:[[NSOperationQueue alloc] init]
                                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                                if (!connectionError) {
                                                    NSError      *error        = nil;
                                                    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                    
                                                    if (jsonResponse && !error) {
                                                        id oav = [[jsonResponse objectForKey:@"receipt"] objectForKey:@"original_application_version"];
                                                        id opd = [[jsonResponse objectForKey:@"receipt"] objectForKey:@"original_purchase_date_ms"];
                                                        if (oav) [storage setObject:oav forKey:@"in.app.purchase.original.version"];
                                                        if (opd) [storage setObject:opd forKey:@"in.app.purchase.original.date"];
                                                        [storage synchronize];
                                                    }
                                                }
                                           }
                     ];
                }
            }
        }
    }
    
    // Alle Käufe vor der ersten InApp-Version werden automatisch freigeschaltet.
    if (![self verifyProduct:PRODUCT_ID_PRO]) {
        if (ov && [[ov description] compare:FIRST_INAPP_VERSION] == NSOrderedAscending) {
            [storage setBool:YES forKey:[NSString stringWithFormat:@"in.app.purchase.%@", PRODUCT_ID_PRO]];
            [storage synchronize];
        }
    }
}

- (BOOL) isEarlyUser
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    id ov = [storage objectForKey:@"in.app.purchase.original.version"];
    return ov && [[ov description] compare:FIRST_INAPP_VERSION] == NSOrderedAscending;
}

#pragma mark - User Dialoge

- (void) onAppStart: (id) sender
{
    // IDEE: Vielleicht verlegen wir diesen Dialog noch in UIApplicationDidBecomeActiveNotification...?
    if (![[InAppPurchaseUtils sharedInstance] verifyProduct:PRODUCT_ID_PRO]) {
        NSString *key = @"in.app.purchase.welcome.shown";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:key]) {
            [defaults setBool:YES forKey:key];
            [defaults synchronize];
            // Nicht beim ersten Start... [self welcomeAlert];
        }
        else {
            // Das nerft bei jedem Start... [self goProAlert];
        }
    }
}

- (void) welcomeAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"inapp.welcome.title", nil)
                                                    message:NSLocalizedString(@"inapp.welcome.message", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"inapp.welcome.later", nil)
                                          otherButtonTitles:NSLocalizedString(@"inapp.welcome.gopro", nil), nil];
    alert.tag = ALERT_WELCOME;
    [alert show];
}

- (void) goProAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"inapp.gopro.title", nil)
                                                    message:NSLocalizedString(@"inapp.gopro.message", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"inapp.gopro.later", nil)
                                          otherButtonTitles:NSLocalizedString(@"inapp.gopro.gopro", nil), nil];
    alert.tag = ALERT_GO_PRO;
    [alert show];
}

- (void) trialOverAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"inapp.gopro.title", nil)
                                                    message:NSLocalizedString(@"inapp.trial.over.message", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"inapp.gopro.later", nil)
                                          otherButtonTitles:NSLocalizedString(@"inapp.gopro.gopro", nil), nil];
    alert.tag = ALERT_GO_PRO;
    [alert show];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"in productsRequest:didReceiveResponse:");
    NSArray *products = response.products;
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        NSLog(@"invalidIdentifier : %@", invalidIdentifier);
    }
    [self displayStoreUI:products.firstObject];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"in paymentQueue:updatedTransactions:");
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchased:
                [self activateProduct:transaction.payment.productIdentifier];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self activateProduct:transaction.payment.productIdentifier];
                break;
                
            case SKPaymentTransactionStateFailed:
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"inapp.purchase.title", nil)
                                            message:transaction.error.localizedDescription
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"inapp.button.close", nil)
                                  otherButtonTitles:nil] show];
                break;
            default:
                // Direkt abbrechen... ignorieren...
                return;
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"in alertView:clickedButtonAtIndex:");
    if (alertView.tag == ALERT_WELCOME || alertView.tag == ALERT_GO_PRO) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self requestProduct:PRODUCT_ID_PRO];
        }
    }
    if (alertView.tag == ALERT_PAYMENT) {
        if (self.requestedProduct) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self requestPayment:self.requestedProduct];
            }
        }
    }
}

#pragma mark - Alerts

- (UIAlertView *) alertWithTitle: (NSString *) title message: (NSString *) msg autohide: (int) secs
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:secs > 0 ? nil : NSLocalizedString(@"inapp.button.okay", nil)
                                          otherButtonTitles:nil];
    alert.tag = ALERT_NOTICE;
    [alert show];
    if (secs > 0) [self performSelector:@selector(hideAlert:) withObject:alert afterDelay:secs];
    return alert;
}

- (void) hideAlert: (UIAlertView *) alert
{
    if (alert) [alert dismissWithClickedButtonIndex:0 animated:YES];
}

@end
