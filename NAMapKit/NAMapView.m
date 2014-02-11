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
@property (nonatomic, strong) NSMutableArray *annotationViews;

@end

@implementation NAMapView

- (id)initWithFrame:(CGRect)frame tiledImageDataSource:(NSObject <NATiledImageViewDataSource> *)dataSource delegate:(NSObject <NAMapViewDelegate> *)delegate
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _dataSource = dataSource;
    _mapDelegate = delegate;

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

    if (!self.annotationViews) {
        self.annotationViews = [[NSMutableArray alloc] init];
    }

    [self.annotationViews addObject:annontationView];
    [self bringSubviewToFront:self.calloutView];
}


- (void)addAnnotations:(NSArray *)annotations animated:(BOOL)animate
{
    int i = 0;
    for (NAAnnotation *annotation in annotations) {
        if (animate) {
            [self performSelector:@selector(addAnimatedAnnontation:) withObject:annotation afterDelay:(NA_PIN_ANIMATION_DURATION * (i++ / 2.0f))];
        }
        else {
            [self addAnnotation:annotation animated:NO];
        }
    }
}


- (void)removeAnnotation:(NAAnnotation *)annotation
{
    [self hideCallOut];
    for (NAPinAnnotationView *annotationView in self.annotationViews) {
        if (annotationView.annotation == annotation) {
            [annotationView removeFromSuperview];
            [self removeObserver:annotationView forKeyPath:@"contentSize"];
            [self.annotationViews removeObject:annotationView];
            break;
        }
    }
}

- (IBAction)showCallOut:(id)sender
{
    if (![sender isKindOfClass:[NAPinAnnotationView class]]) return;
    NAPinAnnotationView *annontationView = (NAPinAnnotationView *) sender;
    [self _showCallOutForAnnontationView:annontationView animated:YES];
}


- (void)_showCallOutForAnnontationView:(NAPinAnnotationView *)annontationView animated:(BOOL)animated
{

    if (annontationView == nil) {return;}

    NAAnnotation *annotation = annontationView.annotation;

//    if (!annotation || !annotation.title) return;

    [self hideCallOut];

    [self.calloutView setAnnotation:annotation];

    [self centreOnPoint:annotation.point animated:animated];

    CGFloat animationDuration = animated ? NA_CALLOUT_ANIMATION_DURATION : 0.0f;

    self.calloutView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4f, 0.4f);
    self.calloutView.hidden = NO;

    [UIView animateWithDuration:animationDuration animations:^{
        self.calloutView.transform = CGAffineTransformIdentity;
    }];

}


- (void)centreOnPoint:(CGPoint)point animated:(BOOL)animate
{
    CGFloat x = (point.x * self.zoomScale) - (self.frame.size.width / 2.0f);
    CGFloat y = (point.y * self.zoomScale) - (self.frame.size.height / 2.0f);
    [self setContentOffset:CGPointMake(roundf(x), roundf(y)) animated:animate];
}


- (void)selectAnnotation:(NAAnnotation *)annotation animated:(BOOL)animate
{
    [self hideCallOut];
    NAPinAnnotationView *selectedView = [self viewForAnnotation:annotation];
    [self _showCallOutForAnnontationView:selectedView animated:animate];
}


- (NAPinAnnotationView *)viewForAnnotation:(NAAnnotation *)annotation
{
    for (NAPinAnnotationView *annotationView in self.annotationViews) {
        if (annotationView.annotation == annotation) {
            return annotationView;
        }
    }
    return nil;
}


- (void)hideCallOut
{
    self.calloutView.hidden = YES;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.dragging) {
        [self hideCallOut];
    }

    [super touchesEnded:touches withEvent:event];
}


- (void)setBackingImageURL:(NSURL *)backingImageURL
{
    if(!self.backingView){
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

#pragma mark - View Layout
//
//- (void)layoutSubviews
//{
//    [super layoutSubviews];
//    if (!self.imageView) return;
//
//    CGSize boundsSize = self.bounds.size;
//    CGRect imageFrame = self.imageView.frame;
//
//    // Center horizontally
//    if (imageFrame.size.width < boundsSize.width)
//        imageFrame.origin.x = (boundsSize.width - imageFrame.size.width) / 2;
//    else
//        imageFrame.origin.x = 0;
//
//    // Center vertically
//    if (imageFrame.size.height < boundsSize.height)
//        imageFrame.origin.y = (boundsSize.height - imageFrame.size.height) / 2;
//    else
//        imageFrame.origin.y = 0;
//
//
//    self.annotationView.frame = imageFrame;
//    self.imageView.frame = imageFrame;
//    self.backingView.frame = imageFrame;
//
////    [self.annotationViews makeObjectsPerformSelector:@selector(updatePosition)];
//}

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