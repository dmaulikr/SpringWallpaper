//
//  MFStringRenderer.h
//
//  Created by Chance Hudson on 5/14/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

//this class is used in place of the number renderer

#import <Foundation/Foundation.h>
#import "MFGLImage.h"

#define FADE_TIME 1.0
#define BASE_CHARACTER_ARRAY_COUNT 20
#define MOVE_VEL 10.0
#define FADE_DELAY 0.2

#define MAX_DIGIT_COUNT 4
#define NUMBERS_ROTATION -0.5

#define BASE_CHARACTER_SET_COUNT 5 //base characterListSize value

#define BASE_STRING_COUNT 20 //base stringsArraySize value

@class MFBatchRenderer;

typedef struct _MFGLCharacterSet {
    MFGLImage *images;
    unsigned imageCount;
    NSString *characters;
    NSString *prefix;
    int listID;
} MFGLCharacterSet;

typedef struct _MFGLString{
    NSString *string;
    int characterListID;
    int characterListIndex;
    int *imageIndexes;
//    CGRect imageFrame;
    CGPoint origin;
    int tag;
    float lifetime; //determines how long the string will be displayed for; -1 indicates inifinite amount of time
    float currentLifetime;
    float alpha;
    float alphaFadeRate; //value determines how much the alpha changes in 1 second
    float xVel; //measured in points/sec
    float yVel;
    BOOL drawOffset;
    BOOL active;
} MFGLString;

@interface MFStringRenderer : NSObject{
    MFGLCharacterSet *characterLists;
    int characterListSize;
    int characterListCount;
    
    MFGLString *strings;
    int stringsArraySize;
    int stringsArrayCount;
    
    NSArray *characterSetArray;
    CFAbsoluteTime previousTime;
}

-(void)loadCharacterSetsForAtlas:(GLuint)atlas atlasDict:(NSMutableDictionary*)atlasDict atlasSize:(CGSize)atlasSize atlasScale:(float)atlasScale;
-(int)addString:(NSString*)string characterListPrefix:(NSString*)prefix origin:(CGPoint)origin alpha:(float)alpha  alphaFadeRate:(float)alphaFadeRate velocity:(CGSize)velocity lifetime:(float)lifetime drawOffset:(BOOL)drawOffset; //returns the tag of the string object
-(void)replaceStringWithTag:(int)tag withString:(NSString*)newString;
-(void)drawStringsWithBatchRenderer:(MFBatchRenderer*)batchRenderer offset:(MFVector)offset frametime:(float)frameTime;
-(void)removeStringWithTag:(int)tag;

-(MFGLString)destroyString:(MFGLString)string;

@end
