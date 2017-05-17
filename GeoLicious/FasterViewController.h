//
//  FasterViewController.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 09.08.16.
//  Copyright © 2016 Daniel Bleisteiner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasterViewController : UITableViewController

// Markiert die Daten aus veraltet und löst ggf. reloadData aus.
- (void) markDirty;

// Diese Methode darf nicht überschrieben werden...
// - (void) reloadData;

// Diese Methode dagegen muss überschrieben werden. Sie führt die eigentliche Arbeit durch,
// wenn die View wirklich auf den Tisch kommt... wirklich sichtbar wird. Der Aufruf wird immer
// im Main-Thread ausgeführt... darum muss sichd der Code nicht mehr selbst kümmern.
- (void) reallyReloadData;

@end
