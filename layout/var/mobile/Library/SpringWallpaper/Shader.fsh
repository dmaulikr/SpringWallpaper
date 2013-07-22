//
//  Shader.fsh
//
//  Created by Chance Hudson on 3/2/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

precision lowp float;

varying lowp vec2 texPosOut;
uniform sampler2D Texture;

varying lowp vec4 colorOut;
varying lowp float alphaModifierOut;

vec4 additiveColorBlend();

void main() {
    gl_FragColor = additiveColorBlend();
}

vec4 additiveColorBlend(){
    vec4 base = texture2D(Texture, texPosOut);
    vec4 temp = (base+colorOut)/vec4(2.0);
    return vec4(temp.x, temp.y, temp.z, base.w+alphaModifierOut);
}