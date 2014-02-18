//
// NAMapView.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Updated by Orta Therox on 05/01/14.
// Copyright 2010 neilang.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NAAnnotation.h"

@class NAMapView, NAPinAnnotationView;

@protocol NAMapViewDelegate
- (NAPinAnnotationView *)mapView:(NAMapView *)imageView viewForAnnotation:(NAAnnotation *)annotation;

@optional
- (void)mapView:(NAMapView *)imageView tappedOnView:(NAPinAnnotationView *)annotation;
- (void)mapView:(NAMapView *)imageView hasChangedZoomLevel:(CGFloat)level;
@end

@protocol NATiledImageViewDataSource;

@interface NAMapView : UIScrollView

- (id)initWithFrame:(CGRect)frame tiledImageDataSource:(NSObject <NATiledImageViewDataSource> *)dataSource delegate:(NSObject <NAMapViewDelegate> *)delegate;

@property (nonatomic, weak) NSObject <NATiledImageViewDataSource> *dataSource;
@property (nonatomic, weak) NSObject <NAMapViewDelegate> *mapDelegate;

@property (readonly, nonatomic, strong) NSMapTable *annotationViews;

@property (nonatomic, strong) NSURL *backingImageURL;

- (void)selectAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate;
- (void)addAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate;
- (void)addAnnotations:(NSArray *)annotations animated:(BOOL)animate;
- (void)removeAnnotation:(NAAnnotation *)annotation;
- (void)removeAnnotations:(NSArray *)annotations;
- (NAPinAnnotationView *)viewForAnnotation:(NAAnnotation *)annotation;

- (void)centreOnPoint:(CGPoint)point animated:(BOOL)animate;
- (CGPoint)zoomRelativePoint:(CGPoint)point;

@end


