//
//  MFParticleGenerator.h
//  Test
//
//  Created by Chance Hudson on 3/18/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>
#import "MFGLConfig.h"
#import "MFGLImage.h"

//#define MAX_QUAD_COUNT 10000

typedef struct {
    float redColor;
    float blueColor;
    float greenColor;
    float alpha;
    float velX;
    float velY;
    float accelX;
    float accelY;
    float posX;
    float posY;
    float width;
    float height;
    float maxLifetime;
    float lifetime;
    BOOL active;
    float alphaDelta;
    float alphaDeltaDelay;
    float colorDelta;
    float colorDeltaDelay;
    MFGLImage sprite;
    int tag;
} Particle;

typedef struct {
    GLfloat posX;
    GLfloat posY;
    GLfloat rColor;
    GLfloat gColor;
    GLfloat bColor;
    GLfloat aColor;
} ParticleVertex;

typedef struct {
    int tag;
    bool active;
    MFGLImage sprite;
    
    float birthrate;               //number of particles created per second
    float birthrateEntropy;
    float velocity;           //base velocity - all speed values are in points/sec
    float velocityEntropy;         //amount each velocity can vary
    CGPoint emissionPoint;
    float emittingAngleDirection; //radians
    float emittingAngleSize;      //also radians
    MFVector4 color;
    float alphaEntropy;
    float colorEntropy;
    float lifetime;
    float lifetimeEntropy;
    float width;
    float height;
    float sizeEntropy;
    MFVector acceleration; //on the y axis positive is down
    float accelerationEntropy;
    
    float alphaDelta;
    float alphaDeltaDelay;
    float alphaDeltaEntropy;
    float colorDelta;
    float colorDeltaDelay;
    float colorDeltaEntropy;
    
    float particleCreationInterval;
    float timeSincePreviousParticleCreation;
} ParticleEmitter;

enum {
    PARTICLE_VERTEX,
    PARTICLE_COLOR,
    PARTICLE_TEX
};

@class MFBatchRenderer;

@interface MFParticleGenerator : NSObject {
    Particle *particleArray;
    ParticleVertex *vertexArray;
    ParticleEmitter *particleEmittersArray;
    
    int particleCount;
    int particleMaxCount;
    int particleEmitterCount;
    int particleEmitterArrayLength;
    
    NSOpenGLContext *context;
    
    float vertexStride;
    float textureStride;
    GLuint vertexBuffer;
//    GLuint textureBuffer;
//    GLuint indiceBuffer;
    CFTimeInterval previousFrame;
    
    MFVector previousRenderOffset;
    
    GLuint particleProgram;
    
    BOOL stepping;
}

-(id)initWithContext:(NSOpenGLContext*)c;

-(void)addParticleEmitter:(ParticleEmitter)emitter;
-(void)removeParticleEmitterWithTag:(int)emitter;
-(void)removeAllEmitters;
-(ParticleEmitter*)particleEmitters; //be careful with this - only use this to get tags for removal of objects with 

-(void)setColor:(NSColor*)color forEmittersWithTag:(int)tag;
-(void)setImage:(MFGLImage)image forEmittersWithTag:(int)tag;

-(void)renderAndStepWithOffset:(MFVector)offset batchRenderer:(MFBatchRenderer*)batchRenderer;
-(void)step;

-(void)updateParticleEmitterBirthRate;
-(void)updateBuffers;

+(ParticleEmitter)emptyParticleEmitter;

ParticleEmitter ParticleEmitterSetColorWithColor(NSColor *color, ParticleEmitter p);
ParticleVertex makeParticleVertex(MFVector p, MFVector4 c);
float normalizeAngle(float angle);
float randomEntropyValue(float entropy);
float clampValue(float val, float maxVal, float minVal);

@end
