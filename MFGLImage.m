//
//  MFGLImage.c
//
//  Created by Chance Hudson on 4/2/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFGLImage.h"

MFGLImage MFGLImageCreateUsingAtlas(GLuint atlas, NSString *texName, NSMutableDictionary *atlasDict, float atlasScale, CGSize atlasSize){
    MFGLImage image = MFGLImageEmpty();
    image.imageID = atlas;
    NSMutableDictionary *imageDict = [[atlasDict objectForKey:@"frames"] objectForKey:texName];
    NSString *s = [imageDict objectForKey:@"textureRect"];
    if(!s){
        image.imageID = 0;
        return image;
    }
    CGSize spriteSize = CGSizeFromString([imageDict objectForKey:@"spriteSize"]);
    image.textureRotated = [[imageDict objectForKey:@"textureRotated"] boolValue];
    image.textureFrame = CGRectFromString(s);
    image.baseTextureFrame = image.textureFrame = image.textureFrame;
    image.size = CGSizeMake(spriteSize.width/atlasScale, spriteSize.height/atlasScale);
    image.scale = atlasScale;
    image.atlasSize = atlasSize;
    image = MFGLImageUpdateTextureCoords(image);
    image.rotation = 0;
    return image;
}

MFGLImage MFGLImageCreateRenderable(CGSize size, float scale){ //make sure that the relevant framebuffer is bound /before/ calling this method
    MFGLImage image = MFGLImageEmpty();
    GLuint renderTexture;
    glGenTextures(1, &renderTexture);
    image.imageID = renderTexture;
    image.textureRotated = NO;
    image.textureFrame = (CGRect){CGPointMake(0,0), size};
    image.baseTextureFrame = image.textureFrame;
    image.scale = scale;
    image.atlasSize = size;
    image.flipY = YES;
    image = MFGLImageUpdateTextureCoords(image);
    
    glBindTexture(GL_TEXTURE_2D, renderTexture);
    glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA, size.width*scale, size.height*scale, 0,GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D , renderTexture, 0);
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE){
        NSLog(@"MFGLImage: Failed to create renderable framebuffer");
    }
    glBindTexture(GL_TEXTURE_2D, 0);
    glCurrentlyBoundTexture = 0;
    return image;
}

//MFGLImage MFGLImageCreateUsingTextureInfo(GLKTextureInfo *textureInfo){
//    MFGLImage returnImage = MFGLImageEmpty();
//    float scale = [UIScreen mainScreen].scale;
//    returnImage.imageID = textureInfo.name;
//    returnImage.size = CGSizeMake(textureInfo.width/scale, textureInfo.height/scale);
//    returnImage.scale = scale;
//    returnImage.baseTextureFrame = CGRectMake(0, 0, textureInfo.width, textureInfo.height);
//    returnImage.textureFrame = returnImage.baseTextureFrame;
//    returnImage.atlasSize = CGSizeMake(textureInfo.width, textureInfo.height);
//    returnImage = MFGLImageUpdateTextureCoords(returnImage);
//    returnImage.rotation = 0;
//    return returnImage;
//}
//
//NSString* MFGLImageGetImageFilepathWithName(NSString *name){
//    NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
//    if(!glIs_iPad){
//        if(glIs_RetinaDisplay && [[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@"@2x~iphone.png"]]]){
//            name = [name stringByAppendingString:@"@2x~iphone.png"];
//        }
//        else if(glIs_RetinaDisplay && [[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@"@2x~iphone.jpg"]]]){
//            name = [name stringByAppendingString:@"@2x~iphone.jpg"];
//        }
//        else if([[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@"~iphone.png"]]]){
//            name = [name stringByAppendingString:@"~iphone.png"];
//        }
//        else if([[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@"~iphone.jpg"]]]){
//            name = [name stringByAppendingString:@"~iphone.jpg"];
//        }
//    }
//    else{
//        if(glIs_RetinaDisplay && [[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@"@2x.png"]]]){
//            name = [name stringByAppendingString:@"@2x.png"];
//        }
//        else if(glIs_RetinaDisplay && [[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@"@2x.jpg"]]]){
//            name = [name stringByAppendingString:@"@2x.jpg"];
//        }
//        else if([[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@".png"]]]){
//            name = [name stringByAppendingString:@".png"];
//        }
//        else if([[NSFileManager defaultManager] fileExistsAtPath:[bundlePath stringByAppendingPathComponent:[name stringByAppendingString:@".jpg"]]]){
//            name = [name stringByAppendingString:@".jpg"];
//        }
//    }
//    if([name rangeOfString:@".png"].location == NSNotFound && [name rangeOfString:@".jpg"].location == NSNotFound){
//        return [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
//    }
//    else if([name rangeOfString:@".png"].location == NSNotFound && [name rangeOfString:@".jpg"].location == NSNotFound){
//        return [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
//    }
//    else if([name rangeOfString:@"/"].location == NSNotFound){
//        return [NSString stringWithFormat:@"%@/%@", bundlePath,name];
//    }
//    else return name;
//}
//
//MFGLImage MFGLImageCreateUsingImageFromMainBundleFile(NSString *filePath){
//    return MFGLImageCreateWithImage([UIImage imageWithContentsOfFile:MFGLImageGetImageFilepathWithName(filePath)]);
//}
//
//MFGLImage MFGLImageCreateWithImageNamed(NSString *filePath){
//    return MFGLImageCreateWithImage([UIImage imageNamed:filePath]);
//}

MFGLImage MFGLImageCreateWithImage(UIImage *image){
	MFGLImage returnImage = MFGLImageEmpty();
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
    if(error != nil){
        NSLog(@"MFGLImage failed to load image: %@", error.localizedDescription);
    }
    returnImage.imageID = textureInfo.name;
    returnImage.size = CGSizeMake(textureInfo.width/image.scale, textureInfo.height/image.scale);
    returnImage.scale = image.scale;
    returnImage.baseTextureFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    returnImage.textureFrame = returnImage.baseTextureFrame;
    returnImage.atlasSize = image.size;
    returnImage = MFGLImageUpdateTextureCoords(returnImage);
    returnImage.rotation = 0;
    return returnImage;
}

MFGLImage MFGLImageSetCustomTextureFrame(MFGLImage image, CGRect textureFrame){
    CGRect newFrame = image.textureRotated?CGRectMake(image.baseTextureFrame.origin.x, image.baseTextureFrame.origin.y+(textureFrame.origin.x*image.scale), textureFrame.size.height*image.scale, textureFrame.size.width*image.scale)
    :
    CGRectMake(image.baseTextureFrame.origin.x+(textureFrame.origin.x*image.scale), image.baseTextureFrame.origin.y+(textureFrame.origin.y*image.scale), textureFrame.size.width*image.scale, textureFrame.size.height*image.scale);
    image.textureFrame = newFrame;
    image = MFGLImageUpdateTextureCoords(image);
    return image;
}

MFGLImage MFGLImageUpdateTextureCoords(MFGLImage image){
    //bottom left
    //bottom right
    //top left
    //top right
    if(image.textureRotated){
        GLfloat texCoords[] = {
            (image.textureFrame.origin.x)/image.atlasSize.width, ((image.textureFrame.origin.y)/image.atlasSize.height),
            (image.textureFrame.origin.x)/image.atlasSize.width, ((image.textureFrame.origin.y+image.textureFrame.size.height)/image.atlasSize.height),
            ((image.textureFrame.origin.x+image.textureFrame.size.width)/image.atlasSize.width), ((image.textureFrame.origin.y)/image.atlasSize.height),
            ((image.textureFrame.origin.x+image.textureFrame.size.width)/image.atlasSize.width), ((image.textureFrame.origin.y+image.textureFrame.size.height)/image.atlasSize.height)
        };
        for(int x = 0; x < 8; x++)
            image.textureCoords[x] = texCoords[x];
    }
    else if(image.flipY){
        GLfloat texCoords[] = {
            (image.textureFrame.origin.x/image.atlasSize.width), (image.textureFrame.origin.y/image.atlasSize.height),
            (image.textureFrame.origin.x+image.textureFrame.size.width)/image.atlasSize.width, (image.textureFrame.origin.y/image.atlasSize.height),
            (image.textureFrame.origin.x/image.atlasSize.width), ((image.textureFrame.origin.y+image.textureFrame.size.height)/image.atlasSize.height),
            (image.textureFrame.origin.x+image.textureFrame.size.width)/image.atlasSize.width, ((image.textureFrame.origin.y+image.textureFrame.size.height)/image.atlasSize.height)
        };
        for(int x = 0; x < 8; x++)
            image.textureCoords[x] = texCoords[x];
    }
    else{
        GLfloat texCoords[] = {
            (image.textureFrame.origin.x/image.atlasSize.width), ((image.textureFrame.origin.y+image.textureFrame.size.height)/image.atlasSize.height),
            (image.textureFrame.origin.x+image.textureFrame.size.width)/image.atlasSize.width, ((image.textureFrame.origin.y+image.textureFrame.size.height)/image.atlasSize.height),
            (image.textureFrame.origin.x/image.atlasSize.width), (image.textureFrame.origin.y/image.atlasSize.height),
            (image.textureFrame.origin.x+image.textureFrame.size.width)/image.atlasSize.width, (image.textureFrame.origin.y/image.atlasSize.height)
        };
        for(int x = 0; x < 8; x++)
            image.textureCoords[x] = texCoords[x];
    }
    return image;
}

MFGLImage MFGLImageEmpty(){
    MFGLImage image;
    image.baseTextureFrame = CGRectZero;
    image.textureFrame = CGRectZero;
    image.imageID = 0;
    image.scale = 0.0;
    image.size = CGSizeZero;
    image.atlasSize = CGSizeZero;
    image.textureRotated = NO;
    image.rotation = 0.0;
    image.flipY = NO;
    return image;
}

void MFGLImageDestroy(MFGLImage image, EAGLContext *context){
	[EAGLContext setCurrentContext:context];	
    BIND_TEXTURE_IF_NEEDED(0);
    glDeleteTextures(1, &image.imageID);
}

