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

varying lowp vec2 v_blurTexCoords[14];

vec4 blur();
vec4 additiveColorBlend();

void main() {
    gl_FragColor = additiveColorBlend();
}

vec4 additiveColorBlend(){
    vec4 base = texture2D(Texture, texPosOut);
    vec4 temp = (base+colorOut)/vec4(2.0);
    return vec4(temp.x, temp.y, temp.z, base.w);
}

vec4 blur() {
    vec4 temp = vec4(0.0);
    temp += texture2D(Texture, v_blurTexCoords[ 0])*0.0044299121055113265;
    temp += texture2D(Texture, v_blurTexCoords[ 1])*0.00895781211794;
    temp += texture2D(Texture, v_blurTexCoords[ 2])*0.0215963866053;
    temp += texture2D(Texture, v_blurTexCoords[ 3])*0.0443683338718;
    temp += texture2D(Texture, v_blurTexCoords[ 4])*0.0776744219933;
    temp += texture2D(Texture, v_blurTexCoords[ 5])*0.115876621105;
    temp += texture2D(Texture, v_blurTexCoords[ 6])*0.147308056121;
    temp += texture2D(Texture, texPosOut          )*0.159576912161;
    temp += texture2D(Texture, v_blurTexCoords[ 7])*0.147308056121;
    temp += texture2D(Texture, v_blurTexCoords[ 8])*0.115876621105;
    temp += texture2D(Texture, v_blurTexCoords[ 9])*0.0776744219933;
    temp += texture2D(Texture, v_blurTexCoords[10])*0.0443683338718;
    temp += texture2D(Texture, v_blurTexCoords[11])*0.0215963866053;
    temp += texture2D(Texture, v_blurTexCoords[12])*0.00895781211794;
    temp += texture2D(Texture, v_blurTexCoords[13])*0.0044299121055113265;
    return temp;
}