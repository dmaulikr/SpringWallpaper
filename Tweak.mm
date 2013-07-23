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

- (void)lockFromSource:(int)arg1 disconnectingCallIfNecessary:(BOOL)arg2{
    NSLog(@"MFLog: lock called");
    [glController stopAnimation];
    %orig;
}

- (void)restoreIconListAnimated:(BOOL)arg1 delay:(double)arg2 animateWallpaper:(BOOL)arg3 keepSwitcher:(BOOL)arg4{
    NSLog(@"MFLog: unlock called");
    [glController resetAnimation];
    %orig;
}

%end
