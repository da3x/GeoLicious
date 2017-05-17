//
//  CoreData.h
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 28.05.14.
//  Copyright (c) 2014 Daniel Bleisteiner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreData : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext       *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel         *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void) saveContext;
- (NSURL *) applicationDocumentsDirectory;

@end
