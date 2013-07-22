//
//  MFBatchRenderer.h
//
//  Created by Chance Hudson on 3/5/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MFGLConfig.h"

#define BASE_ARRAY_COUNT 20
#define IMAGE_ID_INDEX 0
#define IMAGE_VERTEX_COUNT_INDEX 1
#define IMAGE_SHOULD_RENDER_ALPHA_INDEX 2
#define IMAGE_ARRAY_CURRENT_SIZE 3

#define BASE_FRAME_ARRAY_COUNT 2000
#define FRAME_INCREASE_COUNT 200

typedef struct {
    GLfloat posX;
    GLfloat posY;
    GLfloat texX;
    GLfloat texY;
    GLfloat r;
    GLfloat g;
    GLfloat b;
    GLfloat a;
    GLfloat alphaModifier;
} Vertex;

@interface MFBatchRenderer : NSObject {
    Vertex **framesHolder;
    int **imageDictionary; //structure: image id, frame count, should render alpha, current length
    int imageCount;
    int imageArraySize;
    int frameArrayCount;
    
    GLuint vertexBuffer;
    
    BOOL _preserveRenderOrder; //this will cause the items to be rendered in the order in which they are added - as opposed to grouping by texture --
}

-(void)addFrame:(CGRect)frame withAlpha:(float)a forImage:(GLuint)image renderAlpha:(BOOL)renderAlpha withOffset:(MFVector)offset textureFrame:(CGRect)textureFrame textureSize:(CGSize)size;
-(void)addFrame:(CGRect)frame withAlpha:(float)a forImage:(MFGLImage)image renderAlpha:(BOOL)renderAlpha offset:(MFVector)offset;
-(void)addFrame:(CGRect)frame withColor:(MFVector4)color forImage:(GLuint)image renderAlpha:(BOOL)renderAlpha withOffset:(MFVector)offset textureFrame:(CGRect)textureFrame textureSize:(CGSize)size;
-(void)addFrame:(CGRect)frame withColor:(MFVector4)color forImage:(MFGLImage)image renderAlpha:(BOOL)renderAlpha offset:(MFVector)offset;
-(void)addLineFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2 withColor:(MFVector4)color image:(MFGLImage)image width:(float)width offset:(MFVector)offset;
-(void)setShouldRenderAlpha:(BOOL)a forImage:(GLuint)image;
-(void)finishAndDrawBatch;
-(void)resetHolderArrays;

-(void)setCurrentViewOffset:(CGSize)size;

//There should only be one batch renderer in existence at a given time - thus we use a singleton patern
+(MFBatchRenderer*)sharedBatchRenderer;
+(void)initGlobalGLWithContext:(EAGLContext*)context;

@property (assign) BOOL preserveRenderOrder;

@end
