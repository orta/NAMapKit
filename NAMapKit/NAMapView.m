 //
// NAMapView.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

#import "NAMapView.h"
#import "NAPinAnnotationView.h"
#import "NACallOutView.h"
#import "NATiledImageView.h"
#import "UIImageView+WebCache.h"

#define NA_PIN_ANIMATION_DURATION     0.5f
#define NA_CALLOUT_ANIMATION_DURATION 0.1f
#define NA_ZOOM_STEP                  1.5f

static const CGFloat NAZoomMultiplierForDoubleTap = 2.5;

@interface NAMapView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NATiledImageView *imageView;
@property (nonatomic, strong) UIImageView *backingView;
@property (nonatomic, strong) NACallOutView *calloutView;
@property (nonatomic, strong) UIView *annotationView;
@property (nonatomic, strong) NSMapTable *annotationsMap;
@property (nonatomic, assign) CGPoint centerPoint;

@end

@implementation NAMapView

- (id)initWithFrame:(CGRect)frame tiledImageDataSource:(NSObject <NATiledImageViewDataSource> *)dataSource delegate:(NSObject <NAMapViewDelegate> *)delegate
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _dataSource = dataSource;
    _mapDelegate = delegate;
    _annotationsMap = [NSMapTable strongToStrongObjectsMapTable];

    [self viewSetup];
    [self setupGestures];

    return self;
}

- (void)viewSetup
{
    self.delegate = self;

    self.imageView = [[NATiledImageView alloc] initWithDataSource:self.dataSource];
    [self addSubview:self.imageView];

    self.annotationView = [[UIView alloc] initWithFrame:self.imageView.bounds];
    [self addSubview:self.annotationView];

    self.calloutView = [[NACallOutView alloc] initOnMapView:self];
    [self addObserver:self.calloutView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];

    [self addSubview:self.calloutView];

    [self.panGestureRecognizer addTarget:self action:@selector(mapPanGestureHandler:)];
}

- (void)setupGestures
{
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];

    [doubleTap setNumberOfTapsRequired:2];
    [twoFingerTap setNumberOfTouchesRequired:2];

    [self addGestureRecognizer:doubleTap];
    [self addGestureRecognizer:twoFingerTap];
}

#pragma mark Annotations

- (void)addAnimatedAnnontation:(NAAnnotation *)annontation
{
    [self addAnnotation:annontation animated:YES];
}


- (void)addAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate
{
    NAPinAnnotationView *annontationView = [self.mapDelegate mapView:self viewForAnnotation:annotation];
    annontationView.mapView = self;
    annontationView.annotation = annotation;
    [annontationView updatePosition];
    [annontationView addTarget:self action:@selector(showCallOut:) forControlEvents:UIControlEventTouchDown];

    [self addObserver:annontationView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];

    if (animate) {
        annontationView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0f, -annontationView.center.y);
    }

    [self.annotationView addSubview:annontationView];

    if (animate) {
//        annontationView.animating = YES;
//        [UIView animateWithDuration:NA_PIN_ANIMATION_DURATION animations:^{
//            annontationView.transform = CGAffineTransformIdentity;
//        }
//                         completion:^(BOOL finished) {
//                             annontationView.animating = NO;
//                         }];
    }

    [self.annotationsMap setObject:annontationView forKey:annotation];
    [self bringSubviewToFront:self.calloutView];
}


- (void)addAnnotations:(NSArray *)annotations animated:(BOOL)animate
{
    int i = 0;
    for (NAAnnotation *annotation in annotations) {
        if (animate) {
            [self performSelector:@selector(addAnimatedAnnontation:) withObject:annotation afterDelay:(NA_PIN_ANIMATION_DURATION * (i++ / 2.0f))];
        } else {
            [self addAnnotation:annotation animated:NO];
        }
    }
}

- (void)selectAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate
{
     [self hideCallOut];
     NAPinAnnotationView *selectedView = [self viewForAnnotation:annotation];
     [self _showCallOutForAnnontationView:selectedView animated:animate];
}

- (NAPinAnnotationView *)viewForPoint:(CGPoint)point andRepresentedObject:(id)representedObject
{
    for(NAAnnotation *annotation in self.annotations) {
        if (CGPointEqualToPoint(point, annotation.point) && [annotation.representedObject isEqual:representedObject]) {
            return [self.annotationsMap objectForKey:annotation];
        }
    }
    
    return nil;
}

- (NAPinAnnotationView *)viewForAnnotation:(NAAnnotation *)annotation
{
    return [self.annotationsMap objectForKey:annotation];
}

-(NSEnumerator *)annotationViews
{
    return [self.annotationsMap objectEnumerator];
}

-(NSEnumerator *)annotations
{
    return [self.annotationsMap keyEnumerator];
}

- (void)removeAnnotation:(NAAnnotation *)annotation
{
    [self hideCallOut];
    for (NAPinAnnotationView *annotationView in self.annotationViews) {
        if ([annotationView respondsToSelector:@selector(annotation)] && annotationView.annotation == annotation) {
            [annotationView removeFromSuperview];
            [self removeObserver:annotationView forKeyPath:@"contentSize"];
            [self.annotationsMap removeObjectForKey:annotation];
            break;
        }
    }
}

- (void)removeAnnotations:(NSArray *)annotations
{
    for(NAAnnotation *annotation in annotations){
        [self removeAnnotation:annotation];
    }
}

 #pragma mark Callouts

- (IBAction)showCallOut:(NAPinAnnotationView *)sender
{
    [self.mapDelegate mapView:self tappedOnView:sender];
    if (![sender isKindOfClass:[NAPinAnnotationView class]]) return;

    NAPinAnnotationView *annontationView = (NAPinAnnotationView *) sender;
    [self _showCallOutForAnnontationView:annontationView animated:YES];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat zoomLevel = self.zoomScale / self.maximumZoomScale;
    [self.mapDelegate mapView:self hasChangedZoomLevel:zoomLevel];
}

- (void)_showCallOutForAnnontationView:(NAPinAnnotationView *)annontationView animated:(BOOL)animated
{

    if (annontationView == nil) {
        return;
    }

    NAAnnotation *annotation = annontationView.annotation;

//    if (!annotation || !annotation.title) return;

    [self hideCallOut];

    [self.calloutView setAnnotation:annotation];

    [self centreOnPoint:annotation.point animated:animated];

    CGFloat animationDuration = animated ? NA_CALLOUT_ANIMATION_DURATION : 0;

    self.calloutView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    self.calloutView.hidden = NO;

    [UIView animateWithDuration:animationDuration animations:^{
        self.calloutView.transform = CGAffineTransformIdentity;
    }];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    BOOL zoomedOut = self.zoomScale == self.minimumZoomScale;
    if (!CGPointEqualToPoint(self.centerPoint, CGPointZero) && !zoomedOut) {
        [self centreOnPoint:self.centerPoint animated:NO];
    }
}

- (void)mapPanGestureHandler:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateBegan){
        self.centerPoint = CGPointZero;
    }
}

- (void)centreOnPoint:(CGPoint)point animated:(BOOL)animate
{
    CGFloat height = self.frame.size.height ?: 240;
    CGFloat x = (point.x * self.zoomScale) - (self.frame.size.width / 2.0);
    CGFloat y = (point.y * self.zoomScale) - (height / 2.0);
    self.centerPoint = point;
    [self setContentOffset:CGPointMake(roundf(x), roundf(y)) animated:animate];
}


- (void)hideCallOut
{
     self.calloutView.hidden = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (! self.dragging) {
        [self hideCallOut];
    }

    [super touchesEnded:touches withEvent:event];
}

#pragma mark Property Overrides


- (void)setBackingImageURL:(NSURL *)backingImageURL
{
    if(! self.backingView){
        UIImageView *backingView = [[UIImageView alloc] initWithFrame:self.imageView.frame];
        [self insertSubview:backingView belowSubview:self.imageView];
        self.backingView = backingView;
    }

    _backingImageURL = backingImageURL;
    [self.backingView setImageWithURL:backingImageURL];
}

- (CGPoint)zoomRelativePoint:(CGPoint)point
{
    CGSize originalSize = [self.imageView.dataSource imageSizeForImageView:self.imageView];
    CGFloat x = (self.contentSize.width / originalSize.width) * point.x;
    CGFloat y = (self.contentSize.height / originalSize.height) * point.y;
    return CGPointMake(round(x), round(y));
}

- (void)dealloc
{
    for (NAPinAnnotationView *annotationView in self.annotationViews) {
        [self removeObserver:annotationView forKeyPath:@"contentSize"];
    }

    if (self.calloutView) {
        [self removeObserver:self.calloutView forKeyPath:@"contentSize"];
    }
}

#pragma mark - NSTiledImageViewDelegate

 - (void)tiledImageViewDidChangeZoomLevel:(NATiledImageView *)imageView
 {
     NSLog(@"Changed zoom level %i", imageView.currentZoomLevel);
 }

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark - Tap to Zoom

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.zoomScale == self.maximumZoomScale) {
        [self setZoomScale:self.minimumZoomScale animated:YES];

    } else{

        CGPoint tapCenter = [gestureRecognizer locationInView:self.imageView];
        CGFloat newScale = MIN(self.zoomScale * NAZoomMultiplierForDoubleTap, self.maximumZoomScale);
        CGRect maxZoomRect = [self rectAroundPoint:tapCenter atZoomScale:newScale];
        [self zoomToRect:maxZoomRect animated:YES];
    }
}


- (void)handleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer
{
    // two-finger tap zooms out, but returns to normal zoom level if it reaches min zoom
    float newScale = self.zoomScale <= self.minimumZoomScale ? self.maximumZoomScale : self.zoomScale / NA_ZOOM_STEP;
    [self setZoomScale:newScale animated:YES];
}


- (CGRect)rectAroundPoint:(CGPoint)point atZoomScale:(CGFloat)zoomScale {

     // Define the shape of the zoom rect.
     CGSize boundsSize = self.bounds.size;

     // Modify the size according to the requested zoom level.
     // For example, if we're zooming in to 0.5 zoom, then this will increase the bounds size
     // by a factor of two.

     CGSize scaledBoundsSize = CGSizeMake(boundsSize.width / zoomScale, boundsSize.height / zoomScale);

     return CGRectMake(point.x - scaledBoundsSize.width / 2,
             point.y - scaledBoundsSize.height / 2,
             scaledBoundsSize.width,
             scaledBoundsSize.height);
 }

@end

#undef NA_PIN_ANIMATION_DURATION
#undef NA_CALLOUT_ANIMATION_DURATION
#undef NA_ZOOM_STEP