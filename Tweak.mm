#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SpringBoard/SBUIController.h"

#import <objc/runtime.h>
#import "SpringBoard/SBIcon.h"

#import "SpringBoard/SBAwayController.h"
#import "MFOpenGLController.h"

MFOpenGLController *glController;

%hook SBUIController

-(id)init{
    SBUIController *s = %orig;
    glController = [[objc_getClass("MFOpenGLController") alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[self rootView] addSubview:glController.view];
    [[self rootView] bringSubviewToFront:glController.view];
    return s;
}

%end
