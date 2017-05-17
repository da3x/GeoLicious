//
//  GeoTableView.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.03.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoTableView.h"
#import "GeoDatabase.h"

@interface GeoTableView ()
@end

@implementation GeoTableView

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {

        // Ab 50 Einträgen blenden wir den Index ein... falls es einen solchen gibt...
        self.sectionIndexMinimumDisplayRowCount = 50;
        
        // Wir wollen einen eingen Background setzen...
        [self setBackgroundView:nil];
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WhiteLeather.png"]];
    }
    return self;
}

- (void) hideKeyboard: (id) sender
{
    [self endEditing:YES];
}

// Für unsere eigenen UIButtons als AccessoryView benötigen wir eine Methode, die den Event an das Delegate weiter gibt!
- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
{
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:[[[event touchesForView: button] anyObject] locationInView: self]];
    if (indexPath == nil) return;    
    [self.delegate tableView:self accessoryButtonTappedForRowWithIndexPath:indexPath];
}

@end