/**
 *
 * RenderPipeline
 *
 * Copyright (c) 2014-2016 tobspr <tobias.springer1@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#version 430

// This shader provides a bilateral blur at half-resolution

#pragma optionNV (unroll all)

#pragma include "render_pipeline_base.inc.glsl"
#pragma include "includes/gbuffer.inc.glsl"
#pragma include "includes/gaussian_weights.inc.glsl"

uniform ivec2 blur_direction;
uniform sampler2D SourceTex;
uniform GBufferData GBuffer;

out vec4 result;

float get_lin_z(ivec2 ccoord) {
    return get_linear_z_from_z(get_gbuffer_depth(GBuffer, ccoord));
}


uniform sampler2D LowPrecisionNormals;
vec3 get_normal(vec2 coord) { return unpack_normal_unsigned(textureLod(LowPrecisionNormals, coord, 0).xy); }
vec3 get_normal(ivec2 coord) { return unpack_normal_unsigned(texelFetch(LowPrecisionNormals, coord, 0).xy); }


void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);

    vec2 pixel_size = 2.0 / SCREEN_SIZE;

    // Store accumulated color
    vec4 accum = vec4(0);
    float accum_w = 0.0;

    // Amount of samples, don't forget to change the weights array in case you change this.
    const int blur_size = 8;

    // Get the mid pixel normal and depth
    vec3 pixel_nrm = get_normal(coord * 2);
    float pixel_depth = get_lin_z(coord * 2);

    const float max_nrm_diff = 0.1;
    float max_depth_diff = pixel_depth / 25.0;

    // Increase maximum depth difference at obligue angles, to avoid artifacts
    vec3 pixel_pos = get_gbuffer_position(GBuffer, coord * 2);
    vec3 view_dir = normalize(pixel_pos - MainSceneData.camera_pos);
    float NxV = saturate(dot(view_dir, -pixel_nrm));
    max_depth_diff /= max(0.1, NxV);

    // Blur to the right
    for (int i = -blur_size + 1; i < blur_size; ++i) {
        ivec2 offcoord = coord + i * blur_direction * 2;
        vec4 sampled = texelFetch(SourceTex, offcoord, 0);
        vec3 nrm = get_normal(offcoord * 2);
        float depth = get_lin_z(offcoord * 2);

        float weight = gaussian_weights_8[abs(i)];
        float depth_diff = abs(depth - pixel_depth) > max_depth_diff ? 0.0 : 1.0;
        weight *= depth_diff;

        float nrm_diff = distance(nrm, pixel_nrm) < max_nrm_diff ? 1.0 : 0.0;
        weight *= nrm_diff;

        accum += sampled * weight;
        accum_w += weight;
    }

    accum /= max(0.04, accum_w);
    result = accum;
}
