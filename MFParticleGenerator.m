//
//  MFParticleGenerator.m
//
//  Created by Chance Hudson on 3/18/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFParticleGenerator.h"
// #import <QuartzCore/QuartzCore.h>
#import "MFBatchRenderer.h"
#import "MFStructs.h"

@implementation MFParticleGenerator

float unitCircleValues[] = {
    1, -1,
    -1,-1,
    -1,1,
    1,1
};

-(id)initWithContext:(NSOpenGLContext*)c{
    if((self = [super init])){
        context = c;
        [context makeCurrentContext];
//        vertexStride = sizeof(ParticleVertex);
//        glGenBuffers(1, &vertexBuffer);
        [self addObserver:self forKeyPath:@"birthrate" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"lifetime" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self updateBuffers];
//        [self createTextureBuffer];
        particleEmittersArray = calloc(10, sizeof(ParticleEmitter));
        particleEmitterArrayLength = 10;
    }
    return self;
}

-(void)renderAndStepWithOffset:(MFVector)offset batchRenderer:(MFBatchRenderer *)batchRenderer{
    if(particleCount <= 0){
        [self step];
        return;
    }
    previousRenderOffset = offset;
    for(int x = 0; x < particleCount; x++){
        Particle p = particleArray[x];
        if(p.posX+p.width+offset.x > 0 && p.posX+offset.x < glScreenWidth && p.posY+offset.y < glScreenHeight && p.posY+p.height+offset.y > 0){
            [batchRenderer addFrame:CGRectMake(p.posX, p.posY, p.width, p.height) withAlpha:p.alpha forImage:p.sprite renderAlpha:YES offset:offset];
        }
    }
    [self step];
}

-(void)renderAndStep{
    if(particleCount <= 0){
        [self step];
        return;
    }
    glUseProgram(particleProgram);
    glEnable(GL_BLEND);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIndiceBuffer);
    
    GLuint renderedParticles[particleEmitterCount];
    for (int z = 0; z < particleEmitterCount; z++){
        ParticleEmitter emitter = particleEmittersArray[z];
        BOOL needsToRender = YES;
        for(int x = 0; x < particleEmitterCount; x++){
            needsToRender = (renderedParticles[x] != emitter.sprite.imageID);
            if(!needsToRender)
                break;
        }
        if(!needsToRender)
            continue;
        renderedParticles[z] = emitter.sprite.imageID;
        int vertexCounter = 0;
        
        for (int x = 0; x < particleCount; x++) {
            Particle p = particleArray[x];
            if(p.sprite.imageID == emitter.sprite.imageID && (p.posX+p.width > 0 && p.posX < glScreenWidth && p.posY < glScreenHeight && p.posY+p.height > 0)){
                MFVector4 c = MFVector4Make(p.redColor, p.greenColor, p.blueColor, p.alpha);
                vertexArray[vertexCounter] = makeParticleVertex(MFVectorMake(p.posX, p.posY+p.height), c);
                vertexArray[vertexCounter+1] = makeParticleVertex(MFVectorMake(p.posX+p.width, p.posY+p.height), c);
                vertexArray[vertexCounter+2] = makeParticleVertex(MFVectorMake(p.posX, p.posY), c);
                vertexArray[vertexCounter+3] = makeParticleVertex(MFVectorMake(p.posX+p.width, p.posY), c);
                
                vertexCounter += 4;
            }
        }
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferSubData(GL_ARRAY_BUFFER, 0, (sizeof(ParticleVertex)*vertexCounter), vertexArray);
        
        glVertexAttribPointer(PARTICLE_VERTEX, 2, GL_FLOAT, GL_FALSE, vertexStride, 0);
        glVertexAttribPointer(PARTICLE_COLOR, 4, GL_FLOAT, GL_FALSE, vertexStride, (void*)(sizeof(GLfloat)*2));
        
        glBindBuffer(GL_ARRAY_BUFFER, glDefaultTextureCoordsBuffer);
        glVertexAttribPointer(PARTICLE_TEX, 2, GL_FLOAT, GL_FALSE, glDefaultTextureCoordsStride, 0);
        
        BIND_TEXTURE_IF_NEEDED(emitter.sprite.imageID);
        
        if(vertexCounter/4 > MAX_QUAD_COUNT)
            vertexCounter = MAX_QUAD_COUNT*4;
        
        glDrawElements(GL_TRIANGLES, 6*(vertexCounter/4), GL_UNSIGNED_INT, 0);
        //        NSLog(@"%i", particleCount);
    }
    glUseProgram(glGLProgram);
    [self step];
}

-(void)step{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if(!stepping){
            stepping = YES;
        }
        else return;
        CFTimeInterval thisFrame = CACurrentMediaTime();
        CFTimeInterval frameTime = thisFrame - previousFrame;
        previousFrame = thisFrame;
        if(frameTime > 1)
            frameTime = 0.01;
        
        for (int x = 0; x < particleMaxCount; x++) {
            Particle p = particleArray[x];
            if(p.active){
                p.active = (p.lifetime <= p.maxLifetime) && !(p.alpha == 0.0 && p.alphaDelta <= 0);
                if(!p.active){
                    if(particleCount > 0){
                        particleArray[x] = particleArray[particleCount-1];
                        particleCount--;
                        x--;
                        particleArray[particleCount].active = NO;
                    }
                    else
                        particleArray[x] = p;
                }
                else{
                    p.velX += p.accelX*frameTime;
                    p.velY += p.accelY*frameTime;
                    p.posX += p.velX*frameTime;
                    p.posY += p.velY*frameTime;
                    p.lifetime += frameTime;
                    if(p.lifetime > p.alphaDeltaDelay && p.alphaDelta != 0){
                        p.alpha += p.alphaDelta;
                        p.alpha = clampValue(p.alpha, 1, 0);
                    }
                    if(p.lifetime > p.colorDeltaDelay && p.colorDelta != 0){
                        p.redColor += p.colorDelta;
                        p.redColor = clampValue(p.redColor, 1, 0);
                        p.greenColor += p.colorDelta;
                        p.greenColor = clampValue(p.greenColor, 1, 0);
                        p.blueColor += p.colorDelta;
                        p.blueColor = clampValue(p.blueColor, 1, 0);
                    }
                    particleArray[x] = p;
                }
            }
        }
        
        for (int z = 0; z < particleEmitterCount; z++){
            ParticleEmitter emitter = particleEmittersArray[z];
            if(emitter.emissionPoint.y+previousRenderOffset.y < -400)
                continue;
            emitter.timeSincePreviousParticleCreation += frameTime;
            int numberOfNewParticles = floorf(emitter.timeSincePreviousParticleCreation/emitter.particleCreationInterval);
            emitter.timeSincePreviousParticleCreation -= numberOfNewParticles*emitter.particleCreationInterval;
            particleEmittersArray[z] = emitter;
            
            for (int x = particleCount; x < particleMaxCount; x++){
                Particle p = particleArray[x];
                if(!p.active && numberOfNewParticles > 0){
                    numberOfNewParticles--;
                    particleCount++;
                    p.active = YES;
                    p.sprite = emitter.sprite;
                    
                    p.tag = emitter.tag;
                    
                    p.width = emitter.width+randomEntropyValue(emitter.sizeEntropy);
                    p.height = emitter.height+randomEntropyValue(emitter.sizeEntropy);
                    
                    p.posX = emitter.emissionPoint.x-(p.width/2.0f);
                    p.posY = emitter.emissionPoint.y-(p.height/2.0f);
                    
                    p.accelX = emitter.acceleration.x+randomEntropyValue(emitter.accelerationEntropy);
                    p.accelY = emitter.acceleration.y+randomEntropyValue(emitter.accelerationEntropy);
                    
                    float direction = emitter.emittingAngleDirection+randomEntropyValue(emitter.emittingAngleSize/2.0f);
                    direction = normalizeAngle(direction);
                    float vel = emitter.velocity+randomEntropyValue(emitter.velocityEntropy);
                    int quad = floor(direction/(M_PI/2.0f));
                    direction -= quad*(M_PI/2.0f);
                    if(quad % 2 == 1){
                        p.velX = sin(direction)*vel*unitCircleValues[quad*2];
                        p.velY = cos(direction)*vel*unitCircleValues[(quad*2)+1];
                    }
                    else{
                        p.velY = sin(direction)*vel*unitCircleValues[(quad*2)+1];
                        p.velX = cos(direction)*vel*unitCircleValues[quad*2];
                    }
                    
                    //have to use the v[] format because aparently theos/logos/whatever uses strict ansi
                    p.redColor = emitter.color.x+randomEntropyValue(emitter.colorEntropy);
                    p.greenColor = emitter.color.y+randomEntropyValue(emitter.colorEntropy);
                    p.blueColor = emitter.color.z+randomEntropyValue(emitter.colorEntropy);
                    p.alpha = emitter.color.w+randomEntropyValue(emitter.alphaEntropy);
                    
                    p.alphaDelta = emitter.alphaDelta+randomEntropyValue(emitter.alphaDeltaEntropy);
                    p.alphaDeltaDelay = emitter.alphaDeltaDelay;
                    
                    p.colorDelta = emitter.colorDelta+randomEntropyValue(emitter.colorDeltaEntropy);
                    p.colorDeltaDelay = emitter.colorDeltaDelay;
                    
                    p.maxLifetime = emitter.lifetime+randomEntropyValue(emitter.lifetimeEntropy);
                    p.lifetime = 0;
                    particleArray[x] = p;
                }
                if(numberOfNewParticles <= 0)
                    break;
            }
        }
        stepping = NO;
//    });
}

-(void)addParticleEmitter:(ParticleEmitter)emitter{
    if(particleEmitterArrayLength < particleEmitterCount+1){
        particleEmittersArray = realloc(particleEmittersArray, sizeof(ParticleEmitter)*(particleEmitterArrayLength+10));
        particleEmitterArrayLength += 10;
    }
    emitter.active = YES;
    particleEmittersArray[particleEmitterCount] = emitter;
    particleEmitterCount++;
    
    [self updateParticleEmitterBirthRate];
}

-(void)removeParticleEmitterWithTag:(int)emitter{
    int a = particleEmitterCount;
    for(int x = 0; x < a; x++){
        if(particleEmittersArray[x].tag == emitter){
            particleEmittersArray[x].active = NO;
        }
    }
    for (int x = 0; x < a; x++) {
        if(!particleEmittersArray[x].active && x < particleEmitterCount){
            particleEmittersArray[x] = particleEmittersArray[particleEmitterCount-1];
            particleEmittersArray[particleEmitterCount].active = NO;
            particleEmittersArray[x].active = YES;
            particleEmitterCount--;
        }
    }
}

-(void)removeAllEmitters{
    for(int x = 0; x < particleEmitterCount; x++) {
        particleEmittersArray[x].active = NO;
    }
    particleEmitterCount = 0;
}

-(ParticleEmitter*)particleEmitters{
    return particleEmittersArray;
}

-(void)setColor:(NSColor*)color forEmittersWithTag:(int)tag{
    for(int x = 0; x < particleEmitterCount; x++){
        if(particleEmittersArray[x].tag == tag){
            particleEmittersArray[x] = ParticleEmitterSetColorWithColor(color, particleEmittersArray[x]);
        }
    }
}

-(void)setImage:(MFGLImage)image forEmittersWithTag:(int)tag{
    for(int x = 0; x < particleEmitterCount; x++){
        if(particleEmittersArray[x].tag == tag){
            particleEmittersArray[x].sprite = image;
        }
    }
}

-(void)updateParticleEmitterBirthRate{
    for(int x = 0; x < particleEmitterCount; x++){
        ParticleEmitter emitter = particleEmittersArray[x];
        emitter.particleCreationInterval = 1.0f/emitter.birthrate;
        emitter.timeSincePreviousParticleCreation = emitter.particleCreationInterval;
        particleEmittersArray[x] = emitter;
    }
}

float normalizeAngle(float angle){
    if(angle < 0)
        angle += floorf(abs(angle)/(M_PI*2.0))*(M_PI*2.0)+(M_PI*2.0);
    else
        angle -= (floorf(angle/(M_PI*2.0)))*(M_PI*2.0);
    return angle;
}

float randomEntropyValue(float entropy){
    if(entropy == 0)
        return 0;
    float r = (arc4random() % 100)*.01f;
    int r2 = arc4random() % 100;
    return (entropy * r)*((r2 > 50)?1.0:-1.0);
}

float clampValue(float val, float maxVal, float minVal){
    val = (val > maxVal)?maxVal:val;
    val = (val < minVal)?minVal:val;
    return val;
}

//static float wrapValue(float val, float maxVal, float minVal){
//    val = (val > maxVal)?fmod(val, maxVal):val;
//    
//    return val;
//}

ParticleVertex makeParticleVertex(MFVector p, MFVector4 c){
    ParticleVertex v;
    v.posX = p.x;
    v.posY = p.y;
    v.rColor = c.x;
    v.gColor = c.y;
    v.bColor = c.z;
    v.aColor = c.w;
    return v;
}

-(void)updateBuffers{
//    int newMaxCount = (ceil((_birthrate+_birthrateEntropy)*(1.0/60.0))*60.0)*(_lifetime+_lifetimeEntropy);
    int newMaxCount = MAX_QUAD_COUNT;
    if(newMaxCount <= 0)
        newMaxCount = 1;
    if(newMaxCount >= particleMaxCount){
        particleMaxCount = newMaxCount;
        particleArray = realloc(particleArray, sizeof(Particle)*newMaxCount);
        vertexArray = realloc(vertexArray, (sizeof(ParticleVertex)*6)*newMaxCount);
    }
//    [EAGLContext setCurrentContext:context];
//    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
//    glBufferData(GL_ARRAY_BUFFER, (sizeof(ParticleVertex)*6)*particleMaxCount, vertexArray, GL_STREAM_DRAW);
}

-(void)createTextureBuffer{
//    if(textureBuffer != 0){
//        NSLog(@"Buffer already exists, destroy it first");
//        return;
//    }
//    GLshort defaultTextureAndAlpha[] = {
//        0,0, //texture coords
//        1,0,
//        0,1,
//        1,1
//    };
//    textureStride = sizeof(GLshort)*2;
//    int count = MAX_QUAD_COUNT*8;
//    GLshort *finalArray = malloc(sizeof(GLshort)*count);
//    for(int x = 0; x < count; x++){
//        int i = floorf((float)x/8.0);
//        i = x - i*8.0;
//        finalArray[x] = defaultTextureAndAlpha[i];
//    }
//    
//    glGenBuffers(1, &textureBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, textureBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(GLshort)*count, finalArray, GL_STATIC_DRAW);
//    free(finalArray);
//    
//    GLuint indices[] =
//    {0,2,3, // first triangle (bottom left - top left - top right)
//    0,3,1}; // second triangle (bottom left - top right - bottom right)
//    
//    int indiceCount = MAX_QUAD_COUNT*6;
//    
//    GLuint *finalIndices = malloc(sizeof(GLuint)*indiceCount);
//    for(int x = 0; x < indiceCount; x++){
//        int i = floorf((float)x/6.0);
//        int ii = x - i*6;
//        finalIndices[x] = indices[ii]+(4*i);
//    }
//    
//    glGenBuffers(1, &indiceBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiceBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint)*indiceCount, finalIndices, GL_STATIC_DRAW);
//    free(finalIndices);
}

-(void)destroyTextureBuffer{
//    glDeleteBuffers(1, &textureBuffer);
//    glDeleteBuffers(1, &indiceBuffer);
}

+(ParticleEmitter)emptyParticleEmitter{
    ParticleEmitter e;
    e.tag = 0;
    e.active = NO;
    
    e.birthrate = 0;               //number of particles created per second
    e.birthrateEntropy = 0;
    e.velocity = 0;           //base velocity - all speed values are in points/sec
    e.velocityEntropy = 0;         //amount each velocity can vary
    CGPoint emissionPoint = CGPointMake(0, 0);
    e.emissionPoint = emissionPoint;
    e.emittingAngleDirection = 0; //radians
    e.emittingAngleSize = 0;      //also radians
    MFVector4 color = MFVector4Make(0, 0, 0, 0);
    e.color = color;
    e.alphaEntropy = 0;
    e.colorEntropy = 0;
    e.lifetime = 0;
    e.lifetimeEntropy = 0;
    e.width = 0;
    e.height = 0;
    e.sizeEntropy = 0;
    MFVector acceleration = MFVectorMake(0,0);
    e.acceleration = acceleration;
    e.accelerationEntropy = 0;
    
    e.alphaDelta = 0;
    e.alphaDeltaDelay = 0;
    e.alphaDeltaEntropy = 0;
    e.colorDelta = 0;
    e.colorDeltaDelay = 0;
    e.colorDeltaEntropy = 0;
    
    e.particleCreationInterval = 0;
    e.timeSincePreviousParticleCreation = 0;
    return e;
}

#pragma mark Getters/Setters

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"birthrate"] || [keyPath isEqualToString:@"lifetime"]){
        //update the buffer array sizing
        [self updateBuffers];
    }
}

ParticleEmitter ParticleEmitterSetColorWithColor(NSColor *color, ParticleEmitter p){
    p.color = MFVector4Make([color redComponent], [color greenComponent], [color blueComponent], [color alphaComponent]);
    return p;
}

-(void)dealloc{
    free(particleEmittersArray);
    [self removeObserver:self forKeyPath:@"birthrate"];
    [self removeObserver:self forKeyPath:@"lifetime"];
//    glDeleteBuffers(1, &vertexBuffer);
//    [self destroyTextureBuffer];
    [super dealloc];
}

@end
