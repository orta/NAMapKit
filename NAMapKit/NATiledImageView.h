//
// NATiledImageView
// Created by orta on 30/01/2014.
//
//  Copyright (c) 2014 http://artsy.net. All rights reserved.

@class NATiledImageView;

@protocol NATiledImageViewDataSource
- (UIImage *)tiledImageView:(NATiledImageView *)imageView imageTileForLevel:(NSInteger)level x:(NSInteger)x y:(NSInteger)y;
- (CGSize)tileSizeForImageView:(NATiledImageView *)imageView;
- (CGSize)imageSizeForImageView:(NATiledImageView *)imageView;
- (NSInteger)minimumImageZoomLevelForImageView:(NATiledImageView *)imageView;
- (NSInteger)maximumImageZoomLevelForImageView:(NATiledImageView *)imageView;

@optional
- (NSURL *)tiledImageView:(NATiledImageView *)imageView urlForImageTileAtLevel:(NSInteger)level x:(NSInteger)x y:(NSInteger)y;
@end

@interface NATiledImageView : UIView
- (id)initWithDataSource:(NSObject <NATiledImageViewDataSource> *)dataSource;
@property (nonatomic, weak) NSObject <NATiledImageViewDataSource> *dataSource;

- (void)cancelConcurrentDownloads;
@end