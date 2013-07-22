#import "MFGLConfig.h"

CGPoint MFGLCoordsConvertUIKit(CGPoint point, CGSize viewOffset){
    return CGPointMake((point.x/viewOffset.width)-1, -1*((point.y/viewOffset.height)-1));
}

//CGPoint MFGLCoordsConvertUIKitArray(float *points, CGSize viewOffset)