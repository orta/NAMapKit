//
// NAAnnotation.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

@interface NAAnnotation : NSObject

@property (nonatomic, assign) CGPoint     point;
@property (nonatomic, strong) id representedObject;

+ (id)annotationWithPoint:(CGPoint)point representedObject:(id)representedObject;
- (id)initWithPoint:(CGPoint)point representedObject:(id)representedObject;

@end
