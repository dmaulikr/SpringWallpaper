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

//keys for exporting/importing data
#define KEY_POINTS @"POINTS"
#define KEY_SPRINGS @"SPRINGS"

#define KEY_SPRING_POINT_1 @"SPRING_1"
#define KEY_SPRING_POINT_2 @"SPRING_2"
#define KEY_SPRING_CONSTANT @"SPRING_CONSTANT"
#define KEY_SPRING_DAMPER_CONSTANT @"SPRING_DAMPER"
#define KEY_SPRING_REST_LENGTH @"SPRING_REST_LENGTH"

#define KEY_POINT_LOCATION_X @"POINT_LOCATION_X"
#define KEY_POINT_LOCATION_Y @"POINT_LOCATION_Y"
#define KEY_POINT_VELOCITY_X @"POINT_VELOCITY_X"
#define KEY_POINT_VELOCITY_Y @"POINT_VELOCITY_Y"
#define KEY_POINT_MASS @"POINT_MASS"
#define KEY_POINT_COLOR_R @"POINT_COLOR_R"
#define KEY_POINT_COLOR_G @"POINT_COLOR_G"
#define KEY_POINT_COLOR_B @"POINT_COLOR_B"
#define KEY_POINT_COLOR_A @"POINT_COLOR_A"
#define KEY_POINT_FIXED @"POINT_FIXED"
#define KEY_POINT_TAG @"POINT_TAG"

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
    float mass;
    int *springs;
    int springArrayCount;
    int springArrayLength;
    int tag;
    MFVector4 color;
    BOOL fixed;
    BOOL active;
} MFSpringPoint;

typedef struct _MFSpringPointData { //used for exporting data
    MFVector location;
    MFVector velocity;
    float mass;
    int springArrayCount;
    int springArrayLength;
    int tag;
    MFVector4 color;
    BOOL fixed;
    BOOL active;
} MFSpringPointData;

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
-(void)removeAllSpringsAndPoints;

-(NSMutableDictionary*)exportCurrentPointsAndSpringsIgnoringVelocity:(BOOL)ignore;
-(void)importPointsAndSprings:(NSMutableDictionary*)dictionary;

-(void)step;
-(void)drawWithOffset:(MFVector)offset;

MFSpringPointData ConvertMFSpringPointToDataPoint(MFSpringPoint point);
float DistanceBetweenPoints(MFVector p1, MFVector p2);
MFSpringPoint AddSpring(int spring, MFSpringPoint springPoint);
MFSpringPoint EmptySpringPoint();
MFSpring EmptySpring();

@end
