//
//  MFBatchRenderer.m
//
//  Created by Chance Hudson on 3/5/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFBatchRenderer.h"
#import "MFGLImage.h"

@interface MFBatchRenderer()
-(id)init;
@end

@implementation MFBatchRenderer

CGSize currentViewOffset;

static Vertex makeVertex(CGPoint pos, CGPoint texPos, MFVector4 color, float alphaMod){
    Vertex v;
    CGPoint converted = MFGLCoordsConvertUIKit(pos, currentViewOffset);
    v.posX = converted.x;
    v.posY = converted.y;
    v.texX = texPos.x;
    v.texY = texPos.y;
    v.r = color.x;
    v.g = color.y;
    v.b = color.z;
    v.a = color.w;
    v.alphaModifier = alphaMod;
    return v;
}

@synthesize preserveRenderOrder = _preserveRenderOrder;

static MFBatchRenderer *sharedRenderer = nil;

+(MFBatchRenderer*)sharedBatchRenderer{
    if(!glInitialized)
        return nil;
    if(!sharedRenderer){
        sharedRenderer = [[MFBatchRenderer alloc] init];
    }
    return sharedRenderer;
}

-(id)init{
    if((self = [super init])){
        framesHolder = calloc(BASE_ARRAY_COUNT,sizeof(Vertex*));
        imageDictionary = calloc(BASE_ARRAY_COUNT,sizeof(int*));
        for(int x = 0; x < BASE_ARRAY_COUNT; x++) {
            imageDictionary[x] = calloc(4,sizeof(int)); //contains 4 objects
        }
        frameArrayCount = BASE_FRAME_ARRAY_COUNT;
    }
    return self;
}

+(void)initGlobalGLWithContext:(EAGLContext*)context{
	[EAGLContext setCurrentContext:context];
    GLfloat defaultTextureAndAlpha[] = { // this is used for the rendering in the batch renderer
        0,1, //texture coords
        1,   //then alpha
        //        0,0,0,0, //then color
        1,1,
        1,
        //        0,0,0,0,
        0,0,
        1,
        //        0,0,0,0,
        1,0,
        1,
        //        0,0,0,0
    };
    glDefaultTextureCoordsStride = sizeof(GLfloat)*7;
    int count = MAX_QUAD_COUNT*12;
    GLfloat *finalArray = malloc(sizeof(GLfloat)*count);
    for(int x = 0; x < count; x++){
        int i = floorf((float)x/12);
        i = x - i*12;
        finalArray[x] = defaultTextureAndAlpha[i];
    }
    
    glGenBuffers(1, &glDefaultTextureCoordsBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, glDefaultTextureCoordsBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*count, finalArray, GL_STATIC_DRAW);
    free(finalArray);
    
    GLuint indices[] =
    {0,2,3, // first triangle (bottom left - top left - top right)
        0,3,1}; // second triangle (bottom left - top right - bottom right)
    
    int indiceCount = MAX_QUAD_COUNT*6;
    
    GLuint *finalIndices = malloc(sizeof(GLuint)*indiceCount);
    for(int x = 0; x < indiceCount; x++){
        int i = floorf((float)x/6.0);
        int ii = x - i*6;
        finalIndices[x] = indices[ii]+(4*i);
    }
    
    glGenBuffers(1, &glIndiceBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIndiceBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint)*indiceCount, finalIndices, GL_STATIC_DRAW);
    free(finalIndices);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glInitialized = YES;
}

-(int)createNewImageEntry:(GLuint)image renderAlpha:(BOOL)a{
    int imageIndex;
    if(imageArraySize <= imageCount){
        framesHolder = realloc(framesHolder, (imageArraySize+BASE_ARRAY_COUNT)*sizeof(Vertex*));
        imageDictionary = realloc(imageDictionary, (imageArraySize+BASE_ARRAY_COUNT)*sizeof(int*));
        imageArraySize += BASE_ARRAY_COUNT;
    }
    
    imageDictionary[imageCount][IMAGE_ID_INDEX] = image;
    imageDictionary[imageCount][IMAGE_VERTEX_COUNT_INDEX] = 0;
    imageDictionary[imageCount][IMAGE_SHOULD_RENDER_ALPHA_INDEX] = a?1:0;
    
    imageIndex = imageCount;
    imageCount++;
    
    if(imageDictionary[imageIndex][IMAGE_ARRAY_CURRENT_SIZE] == 0){
        framesHolder[imageIndex] = calloc(frameArrayCount, sizeof(Vertex));
        imageDictionary[imageIndex][IMAGE_ARRAY_CURRENT_SIZE] = frameArrayCount;
    }
    if(vertexBuffer == 0){
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*frameArrayCount, framesHolder[imageIndex], GL_STREAM_DRAW);
    }
    
    return imageIndex;
}

-(void)setShouldRenderAlpha:(BOOL)a forImage:(GLuint)image{
    for(int x = 0; x < imageCount; x++){
        if(imageDictionary[x][IMAGE_ID_INDEX] == image){
            imageDictionary[x][IMAGE_SHOULD_RENDER_ALPHA_INDEX] = a?1:0;
            break;
        }
    }
}

-(void)addFrame:(CGRect)frame withColor:(MFVector4)color forImage:(GLuint)image renderAlpha:(BOOL)renderAlpha withOffset:(MFVector)offset textureFrame:(CGRect)textureFrame textureSize:(CGSize)size{
    int imageIndex = -1;
    if(_preserveRenderOrder && imageDictionary[frameArrayCount-1][IMAGE_ID_INDEX] == image) {
        
    }
    for(int x = 0; x < imageCount; x++){
        if(imageDictionary[x][IMAGE_ID_INDEX] == image){
            imageIndex = x;
            break;
        }
    }
    
    if(imageIndex == -1)
        imageIndex = [self createNewImageEntry:image renderAlpha:renderAlpha];
    
    int vertexCount = imageDictionary[imageIndex][IMAGE_VERTEX_COUNT_INDEX];
    BOOL shouldRenderAlpha = imageDictionary[imageIndex][IMAGE_SHOULD_RENDER_ALPHA_INDEX] == 1;
    if(!shouldRenderAlpha)
        color.w = 1;
    
    int newCount = 0;
    newCount = vertexCount+4;
    
    GLfloat texCoords[] = {
        (textureFrame.origin.x/size.width), ((textureFrame.origin.y+textureFrame.size.height)/size.height),
        (textureFrame.origin.x+textureFrame.size.width)/size.width, ((textureFrame.origin.y+textureFrame.size.height)/size.height),
        (textureFrame.origin.x/size.width), (textureFrame.origin.y/size.height),
        (textureFrame.origin.x+textureFrame.size.width)/size.width, (textureFrame.origin.y/size.height)
    };
    
    if((newCount/2)/4 > MAX_QUAD_COUNT){
        NSLog(@"Batch exceeded max size, adjust defined maximum size");
        return;
    }
    
    if(frameArrayCount < newCount){
        frameArrayCount = frameArrayCount + FRAME_INCREASE_COUNT;
        for(int x = 0; x < imageArraySize; x++){
            framesHolder[x] = realloc(framesHolder[x], frameArrayCount*sizeof(Vertex));
        }
        NSLog(@"Increasing batch renderer buffer size to %i", frameArrayCount);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*frameArrayCount, framesHolder[imageIndex], GL_STREAM_DRAW);
    }
    framesHolder[imageIndex][vertexCount] = makeVertex(CGPointMake(frame.origin.x-offset.x, frame.origin.y-offset.y+frame.size.height), CGPointMake(texCoords[0], texCoords[1]), color, 0.0);
    framesHolder[imageIndex][vertexCount+1] = makeVertex(CGPointMake(frame.origin.x-offset.x+frame.size.width, frame.origin.y-offset.y+frame.size.height), CGPointMake(texCoords[2], texCoords[3]), color, 0.0);
    framesHolder[imageIndex][vertexCount+2] = makeVertex(CGPointMake(frame.origin.x-offset.x, frame.origin.y-offset.y), CGPointMake(texCoords[4], texCoords[5]), color, 0.0);
    framesHolder[imageIndex][vertexCount+3] = makeVertex(CGPointMake(frame.origin.x-offset.x+frame.size.width, frame.origin.y-offset.y), CGPointMake(texCoords[6], texCoords[7]), color, 0.0);
    vertexCount+=4;
    
    imageDictionary[imageIndex][IMAGE_VERTEX_COUNT_INDEX] = vertexCount;
}

-(void)addFrame:(CGRect)frame withColor:(MFVector4)color forImage:(MFGLImage)image renderAlpha:(BOOL)renderAlpha offset:(MFVector)offset{
    int imageIndex = -1;
    for(int x = 0; x < imageCount; x++){
        if(imageDictionary[x][IMAGE_ID_INDEX] == image.imageID){
            imageIndex = x;
            break;
        }
    }
    
    if(imageIndex == -1)
        imageIndex = [self createNewImageEntry:image.imageID renderAlpha:renderAlpha];
    
    int vertexCount = imageDictionary[imageIndex][IMAGE_VERTEX_COUNT_INDEX];
    BOOL shouldRenderAlpha = imageDictionary[imageIndex][IMAGE_SHOULD_RENDER_ALPHA_INDEX] == 1;
    if(!shouldRenderAlpha)
        color.w = 1;
    
    int newCount = 0;
    newCount = vertexCount+4;
    
    if((newCount/2)/4 > MAX_QUAD_COUNT){
        NSLog(@"Batch exceeded max size, adjust defined maximum size");
        return;
    }
    
    Vertex vertices[4];
    vertices[0] = makeVertex(CGPointMake(frame.origin.x-offset.x, frame.origin.y-offset.y+frame.size.height), CGPointMake(image.textureCoords[0], image.textureCoords[1]), color, 0.0);
    vertices[1] = makeVertex(CGPointMake(frame.origin.x-offset.x+frame.size.width, frame.origin.y-offset.y+frame.size.height), CGPointMake(image.textureCoords[2], image.textureCoords[3]), color, 0.0);
    vertices[2] = makeVertex(CGPointMake(frame.origin.x-offset.x, frame.origin.y-offset.y), CGPointMake(image.textureCoords[4], image.textureCoords[5]), color, 0.0);
    vertices[3] = makeVertex(CGPointMake(frame.origin.x-offset.x+frame.size.width, frame.origin.y-offset.y), CGPointMake(image.textureCoords[6], image.textureCoords[7]), color, 0.0);
    if(image.rotation != 0){
        CGPoint origCenter = CGPointMake(frame.origin.x+(frame.size.width/2.0f), frame.origin.y-offset.y+(frame.size.height/2.0f));
        for(int x = 0; x < 4; x++){
            CGPoint centerVert = CGPointMake(vertices[x].posX-origCenter.x, vertices[x].posY-origCenter.y);
            CGPoint rotatedVert = CGPointMake((centerVert.x*cosf(image.rotation))-(centerVert.y*sinf(image.rotation)), (centerVert.y*cosf(image.rotation))+(centerVert.x*sinf(image.rotation)));
            rotatedVert = CGPointMake(rotatedVert.x+origCenter.x, rotatedVert.y+origCenter.y);
            vertices[x] = makeVertex(rotatedVert, CGPointMake(image.textureCoords[x*2], image.textureCoords[(x*2)+1]), color, 0.0);
        }
    }
    
    if(frameArrayCount < newCount){
        frameArrayCount = frameArrayCount + FRAME_INCREASE_COUNT;
        for(int x = 0; x < imageArraySize; x++){
            framesHolder[x] = realloc(framesHolder[x], frameArrayCount*sizeof(Vertex));
        }
        NSLog(@"Increasing batch renderer buffer size to %i", frameArrayCount);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*frameArrayCount, framesHolder[imageIndex], GL_STREAM_DRAW);
    }
    //bottom left
    //bottom right
    //top left
    //top right
    for(int x = 0; x < 4; x++){
        framesHolder[imageIndex][vertexCount+x] = vertices[x];
    }
    vertexCount+=4;
    
    imageDictionary[imageIndex][IMAGE_VERTEX_COUNT_INDEX] = vertexCount;
}

-(void)addFrame:(CGRect)frame withAlpha:(float)a forImage:(GLuint)image renderAlpha:(BOOL)renderAlpha withOffset:(MFVector)offset textureFrame:(CGRect)textureFrame textureSize:(CGSize)size{
    [self addFrame:frame withColor:MFVector4Make(1.0, 1.0, 1.0, a) forImage:image renderAlpha:renderAlpha withOffset:offset textureFrame:textureFrame textureSize:size];
}

-(void)addFrame:(CGRect)frame withAlpha:(float)a forImage:(MFGLImage)image renderAlpha:(BOOL)renderAlpha offset:(MFVector)offset{
    [self addFrame:frame withColor:MFVector4Make(1.0, 1.0, 1.0, a) forImage:image renderAlpha:renderAlpha offset:offset];
}

-(void)addLineFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2 withColor:(MFVector4)color image:(MFGLImage)image width:(float)width offset:(MFVector)offset{
    int imageIndex = -1;
    for(int x = 0; x < imageCount; x++){
        if(imageDictionary[x][IMAGE_ID_INDEX] == image.imageID){
            imageIndex = x;
            break;
        }
    }
    
    if(imageIndex == -1)
        imageIndex = [self createNewImageEntry:image.imageID renderAlpha:YES];
    
    int vertexCount = imageDictionary[imageIndex][IMAGE_VERTEX_COUNT_INDEX];
    BOOL shouldRenderAlpha = imageDictionary[imageIndex][IMAGE_SHOULD_RENDER_ALPHA_INDEX] == 1;
    if(!shouldRenderAlpha)
        color.w = 1;
    
    int newCount = 0;
    newCount = vertexCount+4;
    
    if((newCount/2)/4 > MAX_QUAD_COUNT){
        NSLog(@"Batch exceeded max size, adjust defined maximum size");
        return;
    }
    float angle = -1*atan2f(point2.y-point1.y, point2.x-point1.x);
    Vertex vertices[4];
    vertices[0] = makeVertex(CGPointMake(point1.x-offset.x-cosf(angle-M_PI/2.0)*width, point1.y-offset.y+sinf(angle-M_PI/2.0)*width), CGPointMake(image.textureCoords[0], image.textureCoords[1]), color, 1.0);
    vertices[1] = makeVertex(CGPointMake(point2.x-offset.x-cosf(angle-M_PI/2.0)*width, point2.y-offset.y+sinf(angle-M_PI/2.0)*width), CGPointMake(image.textureCoords[2], image.textureCoords[3]), color, 1.0);
    vertices[2] = makeVertex(CGPointMake(point1.x-offset.x+cosf(angle-M_PI/2.0)*width, point1.y-offset.y-sinf(angle-M_PI/2.0)*width), CGPointMake(image.textureCoords[4], image.textureCoords[5]), color, 1.0);
    vertices[3] = makeVertex(CGPointMake(point2.x-offset.x+cosf(angle-M_PI/2.0)*width, point2.y-offset.y-sinf(angle-M_PI/2.0)*width), CGPointMake(image.textureCoords[6], image.textureCoords[7]), color, 1.0);
    
    if(frameArrayCount < newCount){
        frameArrayCount = frameArrayCount + FRAME_INCREASE_COUNT;
        for(int x = 0; x < imageArraySize; x++){
            framesHolder[x] = realloc(framesHolder[x], frameArrayCount*sizeof(Vertex));
        }
        NSLog(@"Increasing batch renderer buffer size to %i", frameArrayCount);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*frameArrayCount, framesHolder[imageIndex], GL_STREAM_DRAW);
    }
    //bottom left
    //bottom right
    //top left
    //top right
    for(int x = 0; x < 4; x++){
        framesHolder[imageIndex][vertexCount+x] = vertices[x];
    }
    vertexCount+=4;
    
    imageDictionary[imageIndex][IMAGE_VERTEX_COUNT_INDEX] = vertexCount;
}

-(void)finishAndDrawBatch{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIndiceBuffer);
    
    for (int x = 0; x < imageCount; x++) {
        int vertexCount = imageDictionary[x][IMAGE_VERTEX_COUNT_INDEX];
        if(vertexCount > 0){
            BOOL shouldRenderAlpha = imageDictionary[x][IMAGE_SHOULD_RENDER_ALPHA_INDEX] == 1;
            if(!shouldRenderAlpha)
                glDisable(GL_BLEND);
            else{
                glEnable(GL_BLEND);
            }
            glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
            glBufferSubData(GL_ARRAY_BUFFER, 0, (vertexCount)*sizeof(Vertex), framesHolder[x]);
            glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
//            if(shouldRenderAlpha)
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(sizeof(GLfloat)*4));
            glVertexAttribPointer(ATTRIB_TEX, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(sizeof(GLfloat)*2));
            glVertexAttribPointer(ATTRIB_ALPHA_MODIFIER, 1, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(sizeof(GLfloat)*8));
            
//            if(!shouldRenderAlpha){
//                glBindBuffer(GL_ARRAY_BUFFER, glDefaultTextureCoordsBuffer);
//                glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, glDefaultTextureCoordsStride, (void*)(sizeof(GLfloat)*2));
//            }
            
            BIND_TEXTURE_IF_NEEDED(imageDictionary[x][IMAGE_ID_INDEX]);
            glDrawElements(GL_TRIANGLES, 6*(vertexCount/4), GL_UNSIGNED_INT, 0);
        }
    }
    [self resetHolderArrays];
}

-(void)resetHolderArrays{
    // no need to release the buffers as they will be overwritten in the next frame
    imageCount = 0;
//    imageArraySize = BASE_ARRAY_COUNT;
}

-(void)setCurrentViewOffset:(CGSize)size{
    currentViewOffset = CGSizeMake(size.width/2.0f, size.height/2.0f);
}

-(void)dealloc{
    for(int x = 0; x < imageCount; x++){
        free(imageDictionary[x]);
        free(framesHolder[x]);
    }
    
    free(imageDictionary);
    free(framesHolder);
    
    glDeleteBuffers(1, &vertexBuffer);
    
    [super dealloc];
}

@end
