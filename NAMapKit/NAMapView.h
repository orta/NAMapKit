//
// NAAnnotation.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NAAnnotation.h"

@protocol NATiledImageViewDataSource;

@interface NAMapView : UIScrollView

- (id)initWithFrame:(CGRect)frame dataSource:(NSObject <NATiledImageViewDataSource> *)dataSource;
@property (nonatomic, strong) NSObject <NATiledImageViewDataSource> *dataSource;

- (void)displayMap:(UIImage *)map;

- (void)selectAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate;
- (void)addAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate;
- (void)addAnnotations:(NSArray *)annotations animated:(BOOL)animate;
- (void)removeAnnotation:(NAAnnotation *)annotation;

- (void)centreOnPoint:(CGPoint)point animated:(BOOL)animate;
- (CGPoint)zoomRelativePoint:(CGPoint)point;

@end


