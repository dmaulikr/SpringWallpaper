//
//  MFOpenGLView.h
//  SpringTest
//
//  Created by Chance Hudson on 7/17/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MFGLImage.h"
#import <QuartzCore/QuartzCore.h>

@class MFShaderLoader, MFSpringSimulator;

@interface MFOpenGLController : NSObject <GLKViewDelegate>{
    MFShaderLoader *shaderLoader;
    MFSpringSimulator *springSimulator;
    MFGLImage image;
    MFGLImage clearImage;
    
    GLuint program;
    
    MFGLImage bufferImage;
    GLuint textureFrameBuffer;
    
    GLuint postShader;
    GLuint postTextureUniform;
    GLuint postOffsetUniform;
   
    GLKView *_view;
	EAGLContext *context;
    CADisplayLink *displayLink;
    
    int currentSelected;
    
    MFVector currentOffset;
    MFVector offsetDelta;
	CFTimeInterval previousFrame;
    
    NSMutableDictionary *springData;
}

@property (nonatomic, retain) GLKView *view;

-(void)setupGL;
-(void)setupSprings;
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect;
-(void)stopAnimation;
-(void)resetAnimation;

@end
