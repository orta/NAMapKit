//
// NAPinAnnotationView.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

#import "NAPinAnnotationView.h"


@interface NAPinAnnotationView()
@end

@implementation NAPinAnnotationView

-(void)updatePosition
{
    CGPoint point = [self.mapView zoomRelativePoint:self.annotation.point];
    point.x -= self.mapPositioningPoint.x;
    point.y -= self.mapPositioningPoint.x;
    self.frame = CGRectMake(point.x, point.y, self.bounds.size.width, self.bounds.size.height);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"contentSize"]) {
        [self updatePosition];
	}
}

@end
