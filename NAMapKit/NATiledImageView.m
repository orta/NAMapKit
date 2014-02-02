//
//  NATiledImageView.m
//  Artsy Folio
//
//  Created by Orta Therox on 29/01/14.
//  Copyright (c) 2014 http://art.sy. All rights reserved.
//

#import "NATiledImageView.h"
#import <QuartzCore/CATiledLayer.h>

@interface NATiledImageView()
@property (nonatomic, assign) NSInteger maxLevelOfDetail;
@end

@implementation NATiledImageView

- (id)initWithDataSource:(NSObject <NATiledImageViewDataSource> *)dataSource;
{
    self = [super init];

    if (!self) return nil;

    self.backgroundColor = [UIColor blackColor];
    _dataSource = dataSource;

    CATiledLayer *layer = (id)[self layer];
    layer.tileSize = [_dataSource tileSizeForImageView:self];

    NSInteger min = [_dataSource minimumImageZoomLevelForImageView:self];
    NSInteger max = [_dataSource maximumImageZoomLevelForImageView:self];
    layer.levelsOfDetail = max - min + 1;

    self.maxLevelOfDetail = max;

    CGSize imagesize = [dataSource imageSizeForImageView:self];
    self.frame = CGRectMake(0, 0, imagesize.width, imagesize.height);

    return self;
}

// http://openradar.appspot.com/8503490

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    // get the scale from the context by getting the current transform matrix, then asking for
    // its "a" component, which is one of the two scale components. We need to also ask for the "d" component as it might not be precisely the same as the "a" component, even at the "same" scale.
    CGFloat _scaleX = CGContextGetCTM(context).a;
    CGFloat _scaleY = CGContextGetCTM(context).d;

    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    CGSize tileSize = tiledLayer.tileSize;

    // Even at scales lower than 100%, we are drawing into a rect in the coordinate system of the full
    // image. One tile at 50% covers the width (in original image coordinates) of two tiles at 100%.
    // So at 50% we need to stretch our tiles to double the width and height; at 25% we need to stretch
    // them to quadruple the width and height; and so on.
    // (Note that this means that we are drawing very blurry images as the scale gets low. At 12.5%,
    // our lowest scale, we are stretching about 6 small tiles to fill the entire original image area.
    // But this is okay, because the big blurry image we're drawing here will be scaled way down before
    // it is displayed.)

    tileSize.width /= _scaleX;
    tileSize.height /= -_scaleY;

    NSInteger firstCol = floor(CGRectGetMinX(rect) / tileSize.width);
    NSInteger lastCol = floor((CGRectGetMaxX(rect)-1) / tileSize.width);
    NSInteger firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    NSInteger lastRow = floorf((CGRectGetMaxY(rect)-1) / tileSize.height);

    NSInteger level = self.maxLevelOfDetail + roundf(log2f(_scaleX));
    for (NSInteger row = firstRow; row <= lastRow; row++) {
        for (NSInteger col = firstCol; col <= lastCol; col++) {

            UIImage *tile = [self.dataSource tiledImageView:self imageTileForLevel:level x:col y:row];

            // + 1/scale is to "fix" mystery stitches
            CGRect tileRect = CGRectMake(tileSize.width * col,
                    tileSize.height * row,
                    tileSize.width,
                    tileSize.height);
            tileRect = CGRectIntersection(self.bounds, tileRect);

            [tile drawInRect:tileRect blendMode:kCGBlendModeNormal alpha:1];

// Uncomment for debugging borders
            [[UIColor redColor] set];
            CGContextSetLineWidth(context, 6.0);
            CGContextStrokeRect(context, tileRect);
        }
    }
}

+ (Class) layerClass {
    return [CATiledLayer class];
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    [super setContentScaleFactor:1.f];
}

@end
