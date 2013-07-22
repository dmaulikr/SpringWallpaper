//
//  MFOpenGLView.m
//  SpringTest
//
//  Created by Chance Hudson on 7/17/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFOpenGLController.h"
#import "MFBatchRenderer.h"
#import "MFShaderLoader.h"
#import "MFSpringSimulator.h"

#define IMAGE_PATH @"/var/mobile/Library/SpringWallpaper/image.png"

@implementation MFOpenGLController
@synthesize view=_view;

GLfloat postVerts[8];

-(id)initWithFrame:(CGRect)frame{
    if((self = [super init])){
		NSLog(@"Began loading");
        shaderLoader = [[MFShaderLoader alloc] initWithShaderPath:@"/var/mobile/Library/SpringWallpaper/" name:@"Shader"];
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _view = [[GLKView alloc] initWithFrame:frame context:context];
        _view.opaque = NO;
        _view.userInteractionEnabled = NO;
        _view.alpha = 1.0;
        [self setupGL];
        [EAGLContext setCurrentContext:[(GLKView*)self.view context]];
        UIImage *i = [UIImage imageWithContentsOfFile:IMAGE_PATH];
        image = MFGLImageCreateWithImage(i);
        [(GLKView*)self.view setDelegate:self];
    	currentOffset = offsetDelta = MFVectorZero;
        
    	springSimulator = [[MFSpringSimulator alloc] init];
    	[springSimulator setPointImage:image];
    	[springSimulator setSpringImage:image];
    	[springSimulator setGravity:MFVectorMake(0, 0.0)];
    	[springSimulator setDragCoefficient:0.0];
        [self setupSprings];
   		
		displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        displayLink.frameInterval = 1.5;
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
	return self;
}

-(void)setupSprings{
	[springSimulator addSpringPointAtLocation:MFVectorMake(50,50) withVelocity:MFVectorMake(0,0) withMass:1 fixed:NO color:MFVector4Make(1,1,1,1)];
}

-(void)setupGL{
	[EAGLContext setCurrentContext:context];
    [MFBatchRenderer initGlobalGLWithContext:context];
    program = [shaderLoader loadShadersWithBindingCode:^(GLuint programID) {
        glBindAttribLocation(programID, ATTRIB_VERTEX, "position");
        glBindAttribLocation(programID, ATTRIB_COLOR, "color");
        glBindAttribLocation(programID, ATTRIB_TEX, "texPosIn");
        glBindAttribLocation(programID, ATTRIB_ALPHA_MODIFIER, "alphaModifier");
    }];
    glTextureUniform = glGetUniformLocation(program, "Texture");
    glUseProgram(program);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glEnableVertexAttribArray(ATTRIB_TEX);
    glEnableVertexAttribArray(ATTRIB_ALPHA_MODIFIER);
	NSLog(@"Loaded first shader");
    glScreenWidth = self.view.frame.size.width;
    glScreenHeight = self.view.frame.size.height;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    [shaderLoader setupForNewShaderLoadPath:@"/var/mobile/Library/SpringWallpaper/" name:@"PostShader"];
    postShader = [shaderLoader loadShadersWithBindingCode:^(GLuint programID) {
        glBindAttribLocation(programID, ATTRIB_VERTEX, "position");
        glBindAttribLocation(programID, ATTRIB_TEX, "texPosIn");
        glBindAttribLocation(programID, ATTRIB_COLOR, "color");
    }];
    postTextureUniform = glGetUniformLocation(postShader, "Texture");
    glUseProgram(postShader);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEX);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    [[MFBatchRenderer sharedBatchRenderer] setCurrentViewOffset:self.view.frame.size];
    
    // create framebuffer
    glGenFramebuffers(1, &textureFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, textureFrameBuffer);
    
    bufferImage = MFGLImageCreateRenderable(self.view.frame.size, 1.0);
    
    // unbind frame buffer
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    postVerts[0] = 0;
    postVerts[1] = self.view.frame.size.height;
    postVerts[2] = self.view.frame.size.width;
    postVerts[3] = self.view.frame.size.height;
    postVerts[4] = 0;
    postVerts[5] = 0;
    postVerts[6] = self.view.frame.size.width;
    postVerts[7] = 0;
    for(int x = 0; x < 8; x+=2){
        CGPoint f = MFGLCoordsConvertUIKit(CGPointMake(postVerts[x], postVerts[x+1]), CGSizeMake(self.view.frame.size.width/2.0, self.view.frame.size.height/2.0));
        postVerts[x] = f.x;
        postVerts[x+1] = f.y;
    }
    glUseProgram(program);
}

-(void)update{
	CFTimeInterval thisFrame = CACurrentMediaTime();
	CFTimeInterval frameTime = thisFrame - previousFrame;
    if(frameTime < (1.0f/45.0f))
		return;
	previousFrame = thisFrame;
    [self.view display];
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //GLint defaultFBO;
    //glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
    //glUseProgram(program);
    //glBindFramebuffer(GL_FRAMEBUFFER, textureFrameBuffer);
    glClearColor(0.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    currentOffset.x += offsetDelta.x;
    currentOffset.y += offsetDelta.y;
    
//    [particleGenerator renderAndStepWithOffset:0 batchRenderer:[MFBatchRenderer sharedBatchRenderer]];
    [springSimulator step];
    [springSimulator drawWithOffset:CGPointMake(0,0)];
    [[MFBatchRenderer sharedBatchRenderer] finishAndDrawBatch];
    //glUseProgram(postShader);
    //glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);
    //glClearColor(0.0, 0.0, 0.0, 0.0);
    //glClear(GL_COLOR_BUFFER_BIT);
    
    //run the image thru the post processing shader
    //glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //GLfloat colors[] = {
    //    1.0,1.0,1.0,1.0,
    //    0.0,1.0,1.0,1.0,
    //    1.0,0.0,1.0,1.0,
    //    1.0,1.0,0.0,1.0
    //};
    
    //glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, postVerts);
    //glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, 0, colors);
    
    //glVertexAttribPointer(ATTRIB_TEX, 2, GL_FLOAT, GL_FALSE, 0, bufferImage.textureCoords);
    
    //BIND_TEXTURE_IF_NEEDED(bufferImage.imageID);
    
    //glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
}

@end
