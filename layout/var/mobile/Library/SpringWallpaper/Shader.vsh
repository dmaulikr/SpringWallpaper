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

attribute lowp float alphaModifier;
varying lowp float alphaModifierOut;

void main() {
    gl_Position = position;
    texPosOut = texPosIn;
    colorOut = color;
    alphaModifierOut = alphaModifier;
}