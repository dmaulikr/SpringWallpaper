//
//  Shader.vsh
//
//  Created by Chance Hudson on 3/2/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

attribute lowp vec4 position;

attribute lowp vec2 texPosIn;
varying lowp vec2 texPosOut;

attribute lowp vec4 color;
varying lowp vec4 colorOut;

varying lowp vec2 v_blurTexCoords[14];

void blur();

void main() {
    gl_Position = position;
    texPosOut = texPosIn;
    colorOut = color;
    //blur();
}

void blur(){
    v_blurTexCoords[ 0] = texPosIn + vec2(-0.028, 0.0);
    v_blurTexCoords[ 1] = texPosIn + vec2(-0.024, 0.0);
    v_blurTexCoords[ 2] = texPosIn + vec2(-0.020, 0.0);
    v_blurTexCoords[ 3] = texPosIn + vec2(-0.016, 0.0);
    v_blurTexCoords[ 4] = texPosIn + vec2(-0.012, 0.0);
    v_blurTexCoords[ 5] = texPosIn + vec2(-0.008, 0.0);
    v_blurTexCoords[ 6] = texPosIn + vec2(-0.004, 0.0);
    v_blurTexCoords[ 7] = texPosIn + vec2( 0.004, 0.0);
    v_blurTexCoords[ 8] = texPosIn + vec2( 0.008, 0.0);
    v_blurTexCoords[ 9] = texPosIn + vec2( 0.012, 0.0);
    v_blurTexCoords[10] = texPosIn + vec2( 0.016, 0.0);
    v_blurTexCoords[11] = texPosIn + vec2( 0.020, 0.0);
    v_blurTexCoords[12] = texPosIn + vec2( 0.024, 0.0);
    v_blurTexCoords[13] = texPosIn + vec2( 0.028, 0.0);
}