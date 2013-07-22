//
//  MFStructs.h
//
//  Created by Chance Hudson on 7/17/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

typedef CGPoint MFVector;
extern const MFVector MFVectorZero;

typedef struct _MFVector3{
    float x;
    float y;
    float z;
} MFVector3;

typedef struct _MFVector4{
    float x;
    float y;
    float z;
    float w;
} MFVector4;

typedef struct _MFSize{
    float width;
    float height;
} MFSize;

MFVector MFVectorMake(float x, float y);
MFVector3 MFVector3Make(float x, float y, float z);
MFVector4 MFVector4Make(float x, float y, float z, float w);

MFSize MFSizeMake(float width, float height);
