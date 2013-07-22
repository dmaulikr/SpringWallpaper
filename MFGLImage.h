//
//  MFGLImageNew.h
//
//  Created by Chance Hudson on 4/2/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>
#import "MFGLConfig.h"

MFGLImage MFGLImageCreateUsingAtlas(GLuint atlas, NSString *texName, NSMutableDictionary *atlasDict, float atlasScale, CGSize atlasSize);
MFGLImage MFGLImageCreateRenderable(CGSize size, float scale);
MFGLImage MFGLImageCreateWithImage(UIImage *image);
MFGLImage MFGLImageCreateWithImageNamed(NSString *filePath);
//MFGLImage MFGLImageCreateUsingImageFromMainBundleFile(NSString *filePath);
//NSString* MFGLImageGetImageFilepathWithName(NSString *name);
//MFGLImage MFGLImageCreateUsingTextureInfo(GLKTextureInfo *textureInfo);

MFGLImage MFGLImageEmpty();

MFGLImage MFGLImageSetCustomTextureFrame(MFGLImage image, CGRect textureFrame);

MFGLImage MFGLImageUpdateTextureCoords(MFGLImage image);

void MFGLImageDestroy(MFGLImage image, EAGLContext *context);
