//
//  GeoSlidesVC.m
//  GeoLicious
//
//  Created by Daniel Bleisteiner on 06.12.13.
//  Copyright (c) 2013 Daniel Bleisteiner. All rights reserved.
//

#import "GeoSlidesVC.h"

@interface GeoSlidesVC ()
@property (nonatomic, retain) IBOutlet UIScrollView *scrollview;
@end

@implementation GeoSlidesVC

+ (GeoSlidesVC *) createWithImages: (NSArray *) imageNames
{
    return [[GeoSlidesVC alloc] initWithImages:imageNames];
}

- (id) initWithImages: (NSArray *) imageNames
{
    self = [self init];
    if (self) {
        [self handleScrollview];
        [self handleButton];
        [self handleImages:imageNames];
    }
    return self;
}

- (void) handleScrollview
{
    CGSize size = self.view.frame.size;
    self.scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 30, size.width - 40, size.height - 80)];
    self.scrollview.delegate = self;
    self.scrollview.pagingEnabled = YES;
    self.scrollview.showsHorizontalScrollIndicator = NO;
    self.scrollview.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollview];
}

- (void) handleButton
{
    CGSize size = self.view.frame.size;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.titleLabel.text = @"Alles klar – los geht's!";
    button.frame = CGRectMake(20, size.height - 50, size.width - 40, 30);
    [button addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void) handleImages: (NSArray *) imageNames
{
    float x = 0, y = 0, m = 5;
    CGSize size = self.scrollview.frame.size;
    for (NSString *imgName in imageNames) {
        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
        image.frame = CGRectMake(x+m, y+m, size.width - 2*m, size.height - 2*m);
        [self.scrollview addSubview:image];
        x += size.width;
    }
    self.scrollview.contentSize = CGSizeMake(imageNames.count * size.width, size.height);
}

#pragma mark - IBActions

- (IBAction) close: (id) sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

@end
