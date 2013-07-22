//config file

#import "MFStructs.h"

CGPoint MFGLCoordsConvertUIKit(CGPoint point, CGSize viewOffset); //view offset is the size of the view / 2.0
//float* MFGLCoordsConvertUIKitArray(float points[], int arrayLength, CGSize viewOffset);

// Commonly used
typedef struct _MFGLImage {
    CGRect baseTextureFrame;
    CGRect textureFrame;
    GLfloat textureCoords[8];
    GLuint imageID;
    float scale;
    CGSize size;
    CGSize atlasSize;
    BOOL textureRotated;
    float rotation;
    BOOL flipY; //used when rendering into a texture
} MFGLImage;

typedef struct _MFGLSprite{
    CGRect frame;
    float rotation;
    float alpha;
    BOOL hidden;
    MFGLImage image;
} MFGLSprite;

enum
{
    ATTRIB_VERTEX,
    ATTRIB_ALPHA,
    ATTRIB_TEX,
    ATTRIB_COLOR,
    ATTRIB_ALPHA_MODIFIER
}; // gl attribs used for shaders

typedef struct {
    MFVector pos;
    MFVector texPos;
    GLshort alpha;
} vertex;

BOOL glInitialized;

//GLuint glOffsetUniform; //aww yee - no longer need to use htis
GLuint glTextureUniform;
GLuint glGLProgram;
GLuint glDefaultTextureCoordsBuffer;
float  glDefaultTextureCoordsStride;
GLuint glIndiceBuffer;

GLuint glCurrentlyBoundTexture;

BOOL glIs_iPad;
BOOL glIs_RetinaDisplay;

CGFloat glScreenWidth;
CGFloat glScreenHeight;

#define MAX_QUAD_COUNT 50000

#define BIND_TEXTURE_IF_NEEDED(t)           \
do{                                         \
    if(glCurrentlyBoundTexture != t){       \
        glBindTexture(GL_TEXTURE_2D, t);    \
        glCurrentlyBoundTexture = t;        \
    }                                       \
} while(0)

