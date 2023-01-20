#include <metal_stdlib>

using namespace metal;

typedef struct {
    simd_float2 inSize;
    simd_float2 outSize;
} UpscalerArgs;


#define CLAMP(v, min, max) \
    if (v < min) { \
        v = min; \
    } else if (v > max) { \
        v = max; \
    }


float4 GetPixelClamped(texture2d<float, access::read> in [[texture(0)]], uint x, uint y, float inW, float inH) {
    CLAMP(x, 0, inW - 1)
    CLAMP(y, 0, inH - 1)
    return in.read(uint2(x, y));
}

// t is a value that goes from 0 to 1 to interpolate in a C1 continuous way across uniformly sampled data points.
// when t is 0, this will return B.  When t is 1, this will return C.  Inbetween values will return an interpolation
// between B and C.  A and B are used to calculate slopes at the edges.
float CubicHermite(float A, float B, float C, float D, float t) {
    float a = -A / 2.0f + (3.0f * B) / 2.0f - (3.0f * C) / 2.0f + D / 2.0f;
    float b = A - (5.0f * B) / 2.0f + 2.0f * C - D / 2.0f;
    float c = -A / 2.0f + C / 2.0f;
    float d = B;
    
    return a * t * t * t + b * t * t + c * t + d;
}

float4 SampleBicubic(texture2d<float, access::read> in [[texture(0)]], float u, float v, float inW, float inH) {
    // calculate coordinates -> also need to offset by half a pixel to keep image from shifting down and left half a pixel
    float x = u * float(inW) - 0.5;
    int xint = int(x);
    float xfract = x - floor(x);
    
    float y = v * float(inH) - 0.5;
    int yint = int(y);
    float yfract = y - floor(y);
    
    // 1st row
    auto p00 = GetPixelClamped(in, xint - 1, yint - 1, inW, inH);
    auto p10 = GetPixelClamped(in, xint + 0, yint - 1, inW, inH);
    auto p20 = GetPixelClamped(in, xint + 1, yint - 1, inW, inH);
    auto p30 = GetPixelClamped(in, xint + 2, yint - 1, inW, inH);
    
    // 2nd row
    auto p01 = GetPixelClamped(in, xint - 1, yint + 0, inW, inH);
    auto p11 = GetPixelClamped(in, xint + 0, yint + 0, inW, inH);
    auto p21 = GetPixelClamped(in, xint + 1, yint + 0, inW, inH);
    auto p31 = GetPixelClamped(in, xint + 2, yint + 0, inW, inH);
    
    // 3rd row
    auto p02 = GetPixelClamped(in, xint - 1, yint + 1, inW, inH);
    auto p12 = GetPixelClamped(in, xint + 0, yint + 1, inW, inH);
    auto p22 = GetPixelClamped(in, xint + 1, yint + 1, inW, inH);
    auto p32 = GetPixelClamped(in, xint + 2, yint + 1, inW, inH);
    
    // 4th row
    auto p03 = GetPixelClamped(in, xint - 1, yint + 2, inW, inH);
    auto p13 = GetPixelClamped(in, xint + 0, yint + 2, inW, inH);
    auto p23 = GetPixelClamped(in, xint + 1, yint + 2, inW, inH);
    auto p33 = GetPixelClamped(in, xint + 2, yint + 2, inW, inH);
    
    // interpolate bi-cubically!
    // Clamp the values since the curve can put the value below 0 or above 255
    float4 ret;
    for (int i = 0; i < 4; ++i)
    {
        float col0 = CubicHermite(p00[i], p10[i], p20[i], p30[i], xfract);
        float col1 = CubicHermite(p01[i], p11[i], p21[i], p31[i], xfract);
        float col2 = CubicHermite(p02[i], p12[i], p22[i], p32[i], xfract);
        float col3 = CubicHermite(p03[i], p13[i], p23[i], p33[i], xfract);
        float value = CubicHermite(col0, col1, col2, col3, yfract);
        CLAMP(value, 0.0f, 255.0f);
        ret[i] = value;
    }
    return ret;
    
}

// From: https://github.com/imxieyi/MetalResize
kernel void BicubicMain(texture2d<float, access::read> in  [[texture(0)]],
                        texture2d<float, access::write> out [[texture(1)]],
                        constant UpscalerArgs *args [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]]) {

    float v = float(gid.y) / float(args->outSize.y - 1);
    float u = float(gid.x) / float(args->outSize.x - 1);
    float4 sample = SampleBicubic(in, u, v, args->inSize.x, args->inSize.y);
    out.write(sample, gid);
}

kernel void removeBlackColor(texture2d<half, access::read_write> texture [[texture(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    half4 sample = texture.read(gid);
    
    if (length(sample.rgb) > 0.1) {
        return;
    }
    
    texture.write(half4(0), gid);
}

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate [[user(textureCoordinate)]];
} TextureMappingVertex;

vertex TextureMappingVertex vertexShader(unsigned int vertex_id [[ vertex_id ]]) {
    
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));
    
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    return outVertex;
}


fragment half4 fragmentShader(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<half> texture [[ texture(0) ]]) {
    
    constexpr sampler s(address::clamp_to_edge, min_filter::linear, mag_filter::linear, mip_filter::none);
    return texture.sample(s, mappingVertex.textureCoordinate);
}

constant half3 luminance_vector(0.2125, 0.7154, 0.0721);
constant half3 bt601(0.299, 0.587, 0.114);

half gauss(half x, half sigma) {
    return 1 / sqrt(2 * M_PI_H * sigma * sigma) * exp(-x * x / (2 * sigma * sigma));
};

half kernel_factor(half center_luminance,
                   half surrounding_luminance,
                   half sigma,
                   half luminance_sigma,
                   int2 normalized_position) {
    half luminance_gauss = gauss(center_luminance - surrounding_luminance, luminance_sigma);
    half space_gauss = gauss(normalized_position.x, sigma) * gauss(normalized_position.y, sigma);
    
    return space_gauss * luminance_gauss;
}



kernel void smoothEdges(texture2d<half, access::sample> inTexture [[ texture(0) ]],
                        texture2d<half, access::read_write> outTexture [[ texture(1) ]],
                        uint2 gid [[ thread_position_in_grid ]]) {
    
    // Step 1: Find edges
    // From: https://medium.com/p/33f4c707dbb
    int kernel_size = 3;
    int radius = kernel_size / 2;
    
    half3x3 horizontal_kernel = half3x3( 0, 0, 0,
                                        -1, 0, 1,
                                         0, 0, 0);
    
    half3x3 vertical_kernel = half3x3(0, -1,  0,
                                      0,  0,  0,
                                      0,  1,  0);

    half3 result_horizontal(0, 0, 0);
    half3 result_vertical(0, 0, 0);
    half result_alpha = 0;
    bool doBlend = false;
    for (int j = 0; j < kernel_size; j++) {
        for (int i = 0; i < kernel_size; i++) {
            uint2 texture_index(gid.x + (i - radius), gid.y + (j - radius));
            result_horizontal += horizontal_kernel[i][j] * inTexture.read(texture_index).rgb;
            result_vertical += vertical_kernel[i][j] * inTexture.read(texture_index).rgb;
            half4 sample = inTexture.read(texture_index);
            result_alpha += sample[3];
        }
    }
    if (result_alpha > 0 && result_alpha < 9) doBlend = true;
    half gray_horizontal = dot(result_horizontal.rgb, bt601);
    half gray_vertical = dot(result_vertical.rgb, bt601);

    half magnitude = length(half2(gray_horizontal, gray_vertical));
    // Skip edges that are not "strong" enough
    if (magnitude <= 0.1 || !doBlend) {
        outTexture.write(inTexture.read(gid), gid);
        return;
    }
    
    // Step 2: Blur/blend edge
    // Bilateral filtering from: https://medium.com/p/3f599e663b02
    kernel_size = 7;
    radius = kernel_size / 2;
    float sigma = 100.0;
    float luminance_sigma = .2;
    half kernel_weight = 0;
    half center_luminance = dot(inTexture.read(gid).rgb, luminance_vector);
    for (int j = 0; j <= kernel_size - 1; j++) {
        for (int i = 0; i <= kernel_size - 1; i++) {
            uint2 texture_index(gid.x + (i - radius), gid.y + (j - radius));
            half surrounding_luminance = dot(inTexture.read(texture_index).rgb, luminance_vector);
            int2 normalized_position(i - radius, j - radius);

            kernel_weight += kernel_factor(center_luminance, surrounding_luminance, sigma, luminance_sigma, normalized_position);
        }
    }

    half4 acc_color(0, 0, 0, 0);
    for (int j = 0; j <= kernel_size - 1; j++) {
        for (int i = 0; i <= kernel_size - 1; i++) {
            uint2 texture_index(gid.x + (i - radius), gid.y + (j - radius));
            half4 texture = inTexture.read(texture_index);
            half surrounding_luminance = dot(texture.rgb, luminance_vector);
            int2 normalized_position(i - radius, j - radius);

            half factor = kernel_factor(center_luminance, surrounding_luminance, sigma, luminance_sigma, normalized_position) / kernel_weight;
            acc_color += factor * texture.rgba;
        }
    }

    outTexture.write(acc_color, gid);
}
