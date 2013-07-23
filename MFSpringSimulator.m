//
//  MFSpringSimulator.m
//  SpringTest
//
//  Created by Chance Hudson on 7/18/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFSpringSimulator.h"
#import "MFBatchRenderer.h"

@interface MFSpringSimulator (Private)

-(void)increaseSpringPointArrayToLength:(unsigned)length;
-(void)increaseSpringArrayToLength:(unsigned)length;

@end

@implementation MFSpringSimulator

-(id)init{
    if((self = [super init])){
        [self increaseSpringArrayToLength:BASE_SPRING_ARRAY_LENGTH];
        [self increaseSpringPointArrayToLength:BASE_SPRING_POINTS_ARRAY_LENGTH];
        springCount = 0;
        springPointsCount = 0;
        gravityAccel = MFVectorMake(0, 0);
        dragCoef = 0.0f;
    }
    return self;
}

-(int)addSpringPointAtLocation:(MFVector)location withVelocity:(MFVector)velocity withMass:(float)mass fixed:(BOOL)fixed color:(MFVector4)color{
    if(springPointsCount + 1 >= springPointsArrayLength){
        [self increaseSpringPointArrayToLength:springPointsArrayLength+BASE_SPRING_POINTS_ARRAY_LENGTH];
    }
    for(int x = 0; x < springPointsArrayLength; x++){
        MFSpringPoint s = springPointsArray[x];
        if(s.active == NO){
            s.active = YES;
            s.location = location;
            s.mass = mass;
            s.springArrayCount = 0;
            s.velocity = velocity;
            s.color = color;
            for(int y = 0; y < s.springArrayLength; y++){
                s.springs[y] = -1;
            }
            s.fixed = fixed;
            springPointsCount++;
            springPointsArray[x] = s;
            return s.tag;
        }
    }
    NSLog(@"Failed to find empty spring point");
    return -1;
}

-(int)addSpringBetweenPointOneTag:(int)tag pointTwoTag:(int)tag2 springConstant:(float)constant restLength:(float)distance damper:(float)damper{
    BOOL foundCount = 0;
    int index1 = -1;
    int index2 = -1;
    for(int x = 0; x < springPointsArrayLength; x++){
        MFSpringPoint s = springPointsArray[x];
        if(s.tag == tag || s.tag == tag2){
            foundCount++;
            if(foundCount == 1)
                index1 = s.tag;
            else
                index2 = s.tag;
        }
    }
    if(foundCount != 2){
        NSLog(@"Failed to add spring: invalid spring points listed");
        return -1;
    }
    for(int x = 0; x < springArrayLength; x++){
        MFSpring s = springsArray[x];
        if(s.active != YES){
            s.active = YES;
            s.springPoint1 = tag;
            s.springPoint2 = tag2;
            s.springConstant = constant;
            s.restLength = distance;
            s.damperConstant = damper;
            s.tag = x;
            springPointsArray[index1] = AddSpring(s.tag, springPointsArray[index1]);
            springPointsArray[index2] = AddSpring(s.tag, springPointsArray[index2]);
            springsArray[x] = s;
            springCount++;
            return s.tag;
        }
    }
    if(springCount + 1 >= springArrayLength){
        [self increaseSpringArrayToLength:springArrayLength+BASE_SPRING_ARRAY_LENGTH];
    }
    MFSpring s = EmptySpring();
    s.active = YES;
    s.springPoint1 = tag;
    s.springPoint2 = tag2;
    s.springConstant = constant;
    s.restLength = distance;
    s.damperConstant = damper;
    s.tag = springCount;
    springPointsArray[index1] = AddSpring(s.tag, springPointsArray[index1]);
    springPointsArray[index2] = AddSpring(s.tag, springPointsArray[index2]);
    springsArray[springCount] = s;
    springCount++;
    return s.tag;
}

-(void)removeAllSpringsAndPoints{
    for(int x = 0; x < springArrayLength; x++){
        springsArray[x].active = NO;
    }
    for(int x = 0; x < springPointsArrayLength; x++){
        springPointsArray[x].active = NO;
        for(int y = 0; y < springPointsArray[x].springArrayLength; y++){
            springPointsArray[x].springs[y] = -1;
        }
    }
    springPointsCount = springCount = 0;
}

-(void)step{
    CFTimeInterval thisFrame = CACurrentMediaTime();
    CFTimeInterval frameTime = thisFrame - previousFrame;
    previousFrame = thisFrame;
//    frameTime = 1.0/10.0;
    if(frameTime > 1.0f/20.0f)
        frameTime = 1.0f/60.0f;
    for(int x = 0; x < springPointsArrayLength; x++){
        MFSpringPoint point = springPointsArray[x];
        if(point.active != YES || point.fixed == YES)
            continue;
        float xForce = 0.0;
        float yForce = 0.0;
        for(int y = 0; y < point.springArrayCount; y++){
            MFSpring spring = springsArray[point.springs[y]];
            if(spring.active != YES)
                continue;
            int s = (spring.springPoint1 == point.tag)?spring.springPoint2:spring.springPoint1;
            MFSpringPoint point2 = springPointsArray[s];
            float dist = DistanceBetweenPoints(point.location, point2.location);
            springsArray[point.springs[y]].currentLength = dist;
            float force = (spring.springConstant*(dist - spring.restLength));
            
            float a = atan2f(point2.location.y - point.location.y, point2.location.x - point.location.x);
            xForce += force * cosf(a);
            yForce += force * sinf(a);
            
            xForce -= ((point.velocity.x - point2.velocity.x) * spring.damperConstant);
            yForce -= ((point.velocity.y - point2.velocity.y) * spring.damperConstant);
            
            xForce += point.velocity.x * dragCoef * -1;
            yForce += point.velocity.y * dragCoef * -1;
        }
        float xAccel = xForce/point.mass + gravityAccel.x;
        float yAccel = yForce/point.mass + gravityAccel.y;
        point.velocity.x += xAccel * frameTime;
        point.velocity.y += yAccel * frameTime;
        point.location.x += frameTime*point.velocity.x;
        point.location.y += frameTime*point.velocity.y;
        springPointsArray[x] = point;
    }
}

-(void)drawWithOffset:(MFVector)offset{
    for(int x = 0; x < springArrayLength; x++){
        MFSpring spring = springsArray[x];
        if(spring.active == YES){
            [[MFBatchRenderer sharedBatchRenderer] addLineFromPoint:springPointsArray[spring.springPoint1].location toPoint:springPointsArray[spring.springPoint2].location withColor:MFVector4Make((spring.currentLength > spring.restLength)?1.0f:0.0f, (spring.currentLength == spring.restLength)?1.0f:0.0f, (spring.currentLength < spring.restLength)?1.0f:0.0f, 1.0) image:springImage width:.5 offset:offset];
        }
    }
    for(int x = 0; x < springPointsArrayLength; x++){
        MFSpringPoint point = springPointsArray[x];
        if(point.active){
            [[MFBatchRenderer sharedBatchRenderer] addFrame:CGRectMake(point.location.x-pointImage.size.width/2.0f, point.location.y-pointImage.size.height/2.0, pointImage.size.width, pointImage.size.height) withColor:point.color forImage:pointImage renderAlpha:YES offset:offset];
        }
    }
}

-(void)setColor:(MFVector4)color forPoint:(int)point{
    for(int x = 0; x < springPointsArrayLength; x++){
        if(springPointsArray[x].tag == point){
            springPointsArray[x].color = color;
            return;
        }
    }
}

-(int)getSpringPointNearPoint:(CGPoint)point{
    float searchRange = 4 ;
    CGRect r = CGRectMake(point.x-searchRange, point.y-searchRange, searchRange*2, searchRange*2);
    for(int x = 0; x < springPointsArrayLength; x++){
        if(CGRectContainsPoint(r, springPointsArray[x].location)){
            return springPointsArray[x].tag;
        }
    }
    return -1;
}

-(void)setSpringImage:(MFGLImage)image{
    springImage = image;
}

-(void)setPointImage:(MFGLImage)image{
    pointImage = image;
}

-(void)setGravity:(MFVector)grav{
    gravityAccel = grav;
}

-(void)setDragCoefficient:(float)drag{
    dragCoef = drag;
}

#pragma mark Array util methods

-(void)increaseSpringPointArrayToLength:(unsigned)length{
    if(length <= springPointsArrayLength)
        return;
    int deltaValue = length - springPointsArrayLength;
    springPointsArrayLength = length;
    springPointsArray = realloc(springPointsArray, springPointsArrayLength*sizeof(MFSpringPoint));
    for(int x = springPointsArrayLength-deltaValue; x < springPointsArrayLength; x++){
        springPointsArray[x] = EmptySpringPoint();
        springPointsArray[x].tag = x;
    }
}

-(void)increaseSpringArrayToLength:(unsigned)length{
    if(length <= springArrayLength)
        return;
    int deltaValue = length - springArrayLength;
    springArrayLength = length;
    springsArray = realloc(springsArray, springArrayLength*sizeof(MFSpring));
    for(int x = springArrayLength-deltaValue; x < springArrayLength; x++){
        springsArray[x] = EmptySpring();
        springsArray[x].tag = x;
    }
}

#pragma mark Exporting data

MFSpringPointData ConvertMFSpringPointToDataPoint(MFSpringPoint point){
    MFSpringPointData returnPoint;
    returnPoint.location = point.location;
    returnPoint.velocity = point.velocity;
    returnPoint.mass = point.mass;
    returnPoint.springArrayCount = point.springArrayCount;
    returnPoint.springArrayLength = point.springArrayLength;
    returnPoint.tag = point.tag;
    returnPoint.color = point.color;
    returnPoint.fixed = point.fixed;
    returnPoint.active = point.active;
    return returnPoint;
}

-(NSMutableDictionary*)exportCurrentPointsAndSpringsIgnoringVelocity:(BOOL)ignore{
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
//    MFSpring *expSprings = calloc(springCount, sizeof(MFSpring));
    NSMutableArray *expSprings = [[NSMutableArray alloc] init];
    unsigned expSpringArrayLength = springCount;
    unsigned expSpringArrayCount = 0;
    for(int x = 0; x < springArrayLength; x++){
        MFSpring spring = springsArray[x];
        if(spring.active && expSpringArrayCount < expSpringArrayLength){
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:[NSNumber numberWithInt:spring.springPoint1] forKey:KEY_SPRING_POINT_1];
            [dict setObject:[NSNumber numberWithInt:spring.springPoint2] forKey:KEY_SPRING_POINT_2];
            [dict setObject:[NSNumber numberWithFloat:spring.springConstant] forKey:KEY_SPRING_CONSTANT];
            [dict setObject:[NSNumber numberWithFloat:spring.damperConstant] forKey:KEY_SPRING_DAMPER_CONSTANT];
            [dict setObject:[NSNumber numberWithFloat:spring.restLength] forKey:KEY_SPRING_REST_LENGTH];
            [expSprings addObject:dict];
            expSpringArrayCount++;
        }
        else if(spring.active && expSpringArrayCount >= expSpringArrayLength){
            NSLog(@"Spring count is inaccurate");
        }
    }
    [returnDict setObject:expSprings forKey:KEY_SPRINGS];
    [expSprings release];
    
    NSMutableArray *dataPoints = [[NSMutableArray alloc] init];
    unsigned dataPointsArrayLength = springPointsCount;
    unsigned dataPointsArrayCount = 0;
    for(int x = 0; x < springPointsArrayLength; x++){
        MFSpringPoint point = springPointsArray[x];
        if(point.active && dataPointsArrayCount < dataPointsArrayLength){
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithFloat:point.location.x] forKey:KEY_POINT_LOCATION_X];
            [dictionary setObject:[NSNumber numberWithFloat:point.location.y] forKey:KEY_POINT_LOCATION_Y];
            [dictionary setObject:[NSNumber numberWithFloat:ignore?0:point.velocity.x] forKey:KEY_POINT_VELOCITY_X];
            [dictionary setObject:[NSNumber numberWithFloat:ignore?0:point.velocity.y] forKey:KEY_POINT_VELOCITY_Y];
            [dictionary setObject:[NSNumber numberWithFloat:point.mass] forKey:KEY_POINT_MASS];
            [dictionary setObject:[NSNumber numberWithFloat:point.color.x] forKey:KEY_POINT_COLOR_R];
            [dictionary setObject:[NSNumber numberWithFloat:point.color.y] forKey:KEY_POINT_COLOR_G];
            [dictionary setObject:[NSNumber numberWithFloat:point.color.z] forKey:KEY_POINT_COLOR_B];
            [dictionary setObject:[NSNumber numberWithFloat:point.color.w] forKey:KEY_POINT_COLOR_A];
            [dictionary setObject:[NSNumber numberWithBool:point.fixed] forKey:KEY_POINT_FIXED];
            [dictionary setObject:[NSNumber numberWithInt:point.tag] forKey:KEY_POINT_TAG];
            [dataPoints addObject:dictionary];
            dataPointsArrayCount++;
        }
        else if(point.active && dataPointsArrayCount >= dataPointsArrayLength){
            NSLog(@"Spring points count is inaccurate");
        }
    }
    [returnDict setObject:dataPoints forKey:KEY_POINTS];
    [dataPoints release];
    
    if(expSpringArrayCount != expSpringArrayLength){
        NSLog(@"Spring array count doesnt exactly fit the length");
        return nil;
    }
    if(dataPointsArrayCount != dataPointsArrayLength){
        NSLog(@"Spring point array count doesnt exactly fit the length");
        return nil;
    }
    
    return returnDict;
}

-(void)importPointsAndSprings:(NSMutableDictionary*)dictionary{
//    unsigned newPointsCount = [[dictionary objectForKey:KEY_POINTS_COUNT] unsignedIntValue];
//    unsigned newSpringsCount = [[dictionary objectForKey:KEY_SPRINGS_COUNT] unsignedIntValue];
    
//    MFSpring *newSprings = malloc(newSpringsCount*sizeof(MFSpring));
//    [(NSData*)[dictionary objectForKey:KEY_SPRINGS] getBytes:newSprings length:newSpringsCount*sizeof(MFSpring)];
//    MFSpringPointData *newPoints = malloc(newPointsCount*sizeof(MFSpringPointData));
//    [(NSData*)[dictionary objectForKey:KEY_POINTS] getBytes:newPoints length:newPointsCount*sizeof(MFSpringPointData)];
    NSMutableArray *newSprings = [dictionary objectForKey:KEY_SPRINGS];
    NSMutableArray *newPoints = [dictionary objectForKey:KEY_POINTS];
    
    if(springPointsCount + newPoints.count >= springPointsArrayLength){
        //need to make the array bigger
        [self increaseSpringPointArrayToLength:springPointsArrayLength+(int)newPoints.count];
    }
    unsigned currentPoint = 0;
    int *newPointTags = calloc(springPointsArrayLength, sizeof(int));
    for(int x = 0; x < springPointsArrayLength; x++)
        newPointTags[x] = x;
    for(int x = 0; x < springPointsArrayLength; x++){
        MFSpringPoint point = springPointsArray[x];
        if(currentPoint >= newPoints.count)
            break;
        if(!point.active){
            NSMutableDictionary *dict = [newPoints objectAtIndex:currentPoint];
            point.location = MFVectorMake([[dict objectForKey:KEY_POINT_LOCATION_X] floatValue], [[dict objectForKey:KEY_POINT_LOCATION_Y] floatValue]);
            point.velocity = MFVectorMake([[dict objectForKey:KEY_POINT_VELOCITY_X] floatValue], [[dict objectForKey:KEY_POINT_VELOCITY_Y] floatValue]);
            point.mass = [[dict objectForKey:KEY_POINT_MASS] floatValue];
            point.color = MFVector4Make([[dict objectForKey:KEY_POINT_COLOR_R] floatValue], [[dict objectForKey:KEY_POINT_COLOR_G] floatValue], [[dict objectForKey:KEY_POINT_COLOR_B] floatValue], [[dict objectForKey:KEY_POINT_COLOR_A] floatValue]);
            point.fixed = [[dict objectForKey:KEY_POINT_FIXED] boolValue];
            point.active = YES;
            point.springArrayCount = 0;
            newPointTags[[[dict objectForKey:KEY_POINT_TAG] intValue]] = point.tag;
            for(int y = 0; y < point.springArrayLength; y++){
                point.springs[y] = -1;
            }
            springPointsArray[x] = point;
            springPointsCount++;
            currentPoint++;
        }
    }
    
    if(springCount + newSprings.count >= springArrayLength){
        [self increaseSpringArrayToLength:springCount+(int)newSprings.count];
    }
    unsigned currentSpring = 0;
    for(int x = 0; x < springArrayLength; x++){
        MFSpring spring = springsArray[x];
        if(currentSpring >= newSprings.count)
            break;
        if(spring.active != YES){
            NSMutableDictionary *dict = [newSprings objectAtIndex:currentSpring];
            spring.tag = x;
            spring.active = YES;
            spring.damperConstant = [[dict objectForKey:KEY_SPRING_DAMPER_CONSTANT] floatValue];
            spring.springConstant = [[dict objectForKey:KEY_SPRING_CONSTANT] floatValue];
            spring.restLength = [[dict objectForKey:KEY_SPRING_REST_LENGTH] floatValue];
            spring.currentLength = 0;
            spring.springPoint1 = newPointTags[[[dict objectForKey:KEY_SPRING_POINT_1] intValue]];
            spring.springPoint2 = newPointTags[[[dict objectForKey:KEY_SPRING_POINT_2] intValue]];
            springPointsArray[spring.springPoint1] = AddSpring(spring.tag, springPointsArray[spring.springPoint1]);
            springPointsArray[spring.springPoint2] = AddSpring(spring.tag, springPointsArray[spring.springPoint2]);
            springsArray[x] = spring;
            currentSpring++;
            springCount++;
        }
    }
    if(currentSpring < newSprings.count){
        NSLog(@"didn't finish adding all springs");
    }
    free(newPointTags);
}

#pragma mark Math

float DistanceBetweenPoints(MFVector p1, MFVector p2){
    float d1 = p1.x-p2.x;
    float d2 = p1.y-p2.y;
    return sqrtf(d1*d1+d2*d2);
}

#pragma mark Struct creators

MFSpringPoint AddSpring(int spring, MFSpringPoint springPoint){
    if(springPoint.springArrayCount + 1 >= springPoint.springArrayLength){
        springPoint.springArrayLength += BASE_SPRING_POINT_SPRING_ARRAY_LENGTH;
        springPoint.springs = realloc(springPoint.springs, springPoint.springArrayLength*sizeof(int));
    }
    springPoint.springs[springPoint.springArrayCount] = spring;
    springPoint.springArrayCount++;
    return springPoint;
}

MFSpringPoint EmptySpringPoint(){
    return (MFSpringPoint){.location = MFVectorMake(0, 0), .velocity = MFVectorMake(0, 0), .mass = 0, .springs = calloc(BASE_SPRING_POINT_SPRING_ARRAY_LENGTH, sizeof(int)), .springArrayCount = 0, .springArrayLength = BASE_SPRING_POINT_SPRING_ARRAY_LENGTH, .tag = 0, .active = NO, .fixed = NO, .color = MFVector4Make(1, 1, 1, 1)};
}

MFSpring EmptySpring(){
    return (MFSpring){.springPoint1 = 0, .springPoint2 = 0, .springConstant = 0, .restLength = 0, .active = NO, .tag = 0, .currentLength = 0.0};
}

@end
