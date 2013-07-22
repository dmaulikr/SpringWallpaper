//
//  MFStructs.m
//
//  Created by Chance Hudson on 7/17/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFStructs.h"

const MFVector MFVectorZero = {0,0};

MFVector MFVectorMake(float x, float y){
    return (MFVector){.x = x, .y = y};
}

MFVector3 MFVector3Make(float x, float y, float z){
    return (MFVector3){.x = x, .y = y, .z = z};
}

MFVector4 MFVector4Make(float x, float y, float z, float w){
    return (MFVector4){.x = x, .y = y, .z = z, .w = w};
}

MFSize MFSizeMake(float width, float height){
    return (MFSize){.width = width, .height = height};
}
