//
// NAPinAnnotationView.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

#import "NAPinAnnotationView.h"

#define NA_PIN_WIDTH   32.0f
#define NA_PIN_HEIGHT  39.0f
#define NA_PIN_POINT_X 8.0f
#define NA_PIN_POINT_Y 35.0f

@interface NAPinAnnotationView()
@end

@implementation NAPinAnnotationView

-(void)updatePosition
{
    CGPoint point = [self.mapView zoomRelativePoint:self.annotation.point];
    point.x       = point.x - NA_PIN_POINT_X;
    point.y       = point.y - NA_PIN_POINT_Y;
    self.frame    = CGRectMake(point.x, point.y, NA_PIN_WIDTH, NA_PIN_HEIGHT);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"contentSize"]) {
        [self updatePosition];
	}
}

@end

#undef NA_PIN_WIDTH
#undef NA_PIN_HEIGHT
#undef NA_PIN_POINT_X
#undef NA_PIN_POINT_Y
