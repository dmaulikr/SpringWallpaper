//
//  MFShaderLoader.m
//
//  Created by Chance Hudson on 6/14/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFShaderLoader.h"
#import "MFGLConfig.h"

#define DEBUG 1

@implementation MFShaderLoader

-(id)initWithShaderPath:(NSString*)p name:(NSString*)n{
    //assumes that the vertex and fragment shaders have the same name but different extensions
    //also assumes that the extensions are vsh and fsh for the vertex and fragment shaders respectively
    if((self = [super init])){
        path = [p retain];
        name = [n retain];
    }
    return self;
}

-(void)setupForNewShaderLoadPath:(NSString*)p name:(NSString*)n{
    [path release];
    [name release];
    path = [p retain];
    name = [n retain];
    _program = 0;
}

-(GLuint)program{
    return _program;
}

- (GLuint)loadShadersWithBindingCode:(void(^)(GLuint prog))bindingBlock
{
    if(!name)
        return NO;
    
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    // vertShaderPathname = [[NSBundle mainBundle] pathForResource:name ofType:@"vsh"];
    vertShaderPathname = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.vsh", name]];
    if(![[NSFileManager defaultManager] fileExistsAtPath:vertShaderPathname]){
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    // fragShaderPathname = [[NSBundle mainBundle] pathForResource:name ofType:@"fsh"];
    fragShaderPathname = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.fsh", name]];
    if(![[NSFileManager defaultManager] fileExistsAtPath:fragShaderPathname]){
        NSLog(@"Failed to load fragment shader");
        return NO;
    }
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    bindingBlock(_program); //use this to allow the calling class to bind attributes to names
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return -1;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    return _program;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
 #if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
 #endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)dealloc
{
    if (_program)
        glDeleteProgram(_program);
    [name release];
    name = nil;
    [path release];
    path = nil;
    
    [super dealloc];
}

@end
