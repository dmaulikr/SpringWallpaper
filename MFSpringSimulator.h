//
//  MFSpringSimulator.h
//  SpringTest
//
//  Created by Chance Hudson on 7/18/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFGLConfig.h"

#define BASE_SPRING_POINTS_ARRAY_LENGTH 10
#define BASE_SPRING_ARRAY_LENGTH 10
#define BASE_SPRING_POINT_SPRING_ARRAY_LENGTH 5 //length for the internal array of springs in each spring point

typedef struct _MFSpring{
    int springPoint1;
    int springPoint2;
    float springConstant;
    float damperConstant;
    float restLength;
    float currentLength;
    BOOL active;
    int tag;
} MFSpring;

typedef struct _MFSpringPoint{
    MFVector location;
    MFVector velocity;
    float mass;             //setting this to zero will result in a division by zero - destroying position coords
    int *springs;
    int springArrayCount;
    int springArrayLength;
    int tag;
    MFVector4 color;
    BOOL fixed;
    BOOL active;
} MFSpringPoint;

@class MFBatchRenderer;

@interface MFSpringSimulator : NSObject {
    MFSpringPoint *springPointsArray;
    unsigned int springPointsCount;
    unsigned int springPointsArrayLength;
    MFSpring *springsArray;
    unsigned int springCount;
    unsigned int springArrayLength;
    
    MFGLImage springImage;
    MFGLImage pointImage;
    
    MFVector gravityAccel;
    float dragCoef;
    
    CFTimeInterval previousFrame;
}

-(id)init;

-(int)addSpringPointAtLocation:(MFVector)location withVelocity:(MFVector)velocity withMass:(float)mass fixed:(BOOL)fixed color:(MFVector4)color;
-(int)addSpringBetweenPointOneTag:(int)tag pointTwoTag:(int)tag2 springConstant:(float)constant restLength:(float)distance damper:(float)damper;

-(void)setSpringImage:(MFGLImage)image;
-(void)setPointImage:(MFGLImage)image;
-(void)setGravity:(MFVector)grav;
-(void)setDragCoefficient:(float)drag;
-(void)setColor:(MFVector4)color forPoint:(int)point;
-(int)getSpringPointNearPoint:(CGPoint)point;

-(void)step;
-(void)drawWithOffset:(MFVector)offset;

MFSpringPoint EmptySpringPoint();
MFSpring EmptySpring();
MFSpringPoint AddSpring(int spring, MFSpringPoint springPoint);
float DistanceBetweenPoints(MFVector p1, MFVector p2);

@end
