//
// NAPinAnnotationView.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NAAnnotation.h"
#import "NAMapView.h"

@interface NAPinAnnotationView : UIButton

@property (nonatomic, assign) BOOL animating;
@property (nonatomic, strong) NAAnnotation *annotation;
@property (nonatomic, weak) NAMapView *mapView;

-(void)updatePosition;
@end
