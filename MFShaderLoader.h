//
//  MFShaderLoader.h
//
//  Created by Chance Hudson on 6/14/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface MFShaderLoader : NSObject{
    GLuint _program;
    
    NSString *path;
    NSString *name;
}

-(id)initWithShaderPath:(NSString*)p name:(NSString*)n;
-(void)setupForNewShaderLoadPath:(NSString*)p name:(NSString*)n;

-(GLuint)program;
-(GLuint)loadShadersWithBindingCode:(void(^)(GLuint prog))bindingBlock;

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

