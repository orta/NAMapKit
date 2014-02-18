//
// NAAnnotation.h
// NAMapKit
//
// Created by Neil Ang on 21/07/10.
// Copyright 2010 neilang.com. All rights reserved.
//

#import "NAAnnotation.h"

@implementation NAAnnotation

+ (id)annotationWithPoint:(CGPoint)point representedObject:(id)representedObject
{
    return [[[self class] alloc] initWithPoint:point representedObject:representedObject];
}

- (id)initWithPoint:(CGPoint)point representedObject:(id)representedObject
{
    self = [super init];
    if (!self) return nil;

    _point = point;
    _representedObject = representedObject;

    return self;
}

-(id)copyWithZone: (NSZone *)zone
{
    return [[NAAnnotation allocWithZone:zone] initWithPoint:self.point representedObject:self.representedObject];
}

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:self.class]){
        return CGPointEqualToPoint(self.point , [object point]) && [self.representedObject isEqual:[object representedObject]];
    }
    return [super isEqual:object];
}

@end
