/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

#include "AAPLShaderTypes.h"
#include "SharedShaders.metal"

// Some hardcoded defs in order not to include additional headers
#define LIGHT_FALLOUT_TYPE_LINEAR       0.f
#define LIGHT_FALLOUT_TYPE_EXP          1.f

vertex RasterizerData
vertexShader(
    uint     vertexID                                 [[ vertex_id ]]
  , constant AAPLVertex       *vertices               [[ buffer(AAPLVertexInputIndexVertices) ]]
  , constant float            *viewportScalePointer   [[ buffer(AAPLVertexInputIndexWindowScale) ]]
  , constant vector_float2    *viewportOffset         [[ buffer(AAPLVertexInputIndexObjectOffset) ]]
  , constant float            *objectScalePointer     [[ buffer(AAPLVertexInputIndexObjectScale) ]]
  , constant vector_float2    *objectSizePointer      [[ buffer(AAPLVertexInputIndexObjectSize) ]]
  , constant vector_float2    *viewportSizePointer    [[ buffer(AAPLVertexInputIndexViewportSize) ]]
)
{
    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions (i.e. a value of 100
    // is 100 pixels from the origin).
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    float pixelZSpacePosition = vertices[vertexID].position.z;
    
    // Get the viewport size and cast to float.
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);

    // Get the viewport scale
    float viewportScale = float(*viewportScalePointer);

    // Get the target object scale
    float objectScale = float(*objectScalePointer);

    // Get the object size
    vector_float2 objectSize = vector_float2(*objectSizePointer);

    // Calculate object size scaled
    vector_float2 objectSizeScaled = objectSize.xy * objectScale * viewportScale;

    // Get the target object translation
    vector_float2 objectTranslation = vector_float2(*viewportOffset);
    objectTranslation.xy *= viewportScale;

    // Scale the object based on the viewport scale
    pixelSpacePosition.xy *= viewportScale;

    // Sacle the object based on internal scale
    pixelSpacePosition.xy *= objectScale;

    // Translate to top-left corner
    pixelSpacePosition.x -= (viewportSize.x - objectSizeScaled.x)/2;
    pixelSpacePosition.y += (viewportSize.y - objectSizeScaled.y)/2;

    // Apply translation
    pixelSpacePosition.x += objectTranslation.x / viewportScale;
    pixelSpacePosition.y -= objectTranslation.y / viewportScale;

    // To convert from positions in pixel space to positions in clip-space,
    // divide the pixel coordinates by half the size of the viewport.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.position.z = pixelZSpacePosition;
    
    // Pass the input color directly to the rasterizer.
    out.textureCoordinate = vertices[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4
fragmentShader(
     RasterizerData             in [[stage_in]]
   , texture2d<half>            colorTexture     [[ texture(FragmentShaderIndexBaseColor)  ]]
   , constant float             *alphaPointer    [[ buffer (FragmentShaderIndexBaseAlpha)  ]]
   , constant AAPAmbientLLight  *lights          [[ buffer (FragmentShaderIndexLight)      ]]
   , constant int               *lightCountPtr   [[ buffer (FragmentShaderIndexLightCount) ]]
   , constant vector_float4     *colorModPtr     [[ buffer (FragmentShaderIndexColorMod)   ]]
)
{
    // Texture sampler
    constexpr sampler textureSampler (mag_filter::nearest,
                                      min_filter::nearest);

    // Sample the texture to obtain a color
    half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    // Get the chosen alpha transparency for the object
    float alpha = float(*alphaPointer);

    // If not visible hide the fragment anyway
    if (alpha <= 0)
    {
        discard_fragment();
    }

    // If still visible combine with the fragment's alpha
    colorSample.a *= *alphaPointer;

    if (colorSample.a <= 0.0001)
    {
        discard_fragment();
        return float4(colorSample);
    }

    // Apply the color mod
    half4 colorMod = half4(*colorModPtr);
    colorSample.rgba *= colorMod;

    // Light calculation
    int lightCount = int(*lightCountPtr);
    if (lightCount)
    {
        half3 appliedColor = half3(0.f, 0.f, 0.f);
        for (int i = 0; i < lightCount; i++)
        {
            auto light = &lights[i];
            if (light->enabled > 0.f)
            {
                float distance = metal::distance(in.position.xy, light->position);
                float str = 0;
                if (light->lightType == LIGHT_FALLOUT_TYPE_LINEAR)
                {
                    str = max(light->diffuse_size - distance, 0.0f) / light->diffuse_size;
                }
                else if (light->lightType == LIGHT_FALLOUT_TYPE_EXP)
                {
                    str = exp( 1 - (pow(distance, 2) / light->diffuse_size) );
                }

                half3 ambientColor = half3(light->color);
                half3 ambientIntensity = half3(light->ambientIntensity);
                half3 diffuseIntensity = half3(light->diffuse_intensity);
                appliedColor = min(1.f, appliedColor + min(1.f, ambientColor.rgb * min(1.f, (ambientIntensity + (diffuseIntensity * str)))));
            }
        }

        colorSample.rgb *= appliedColor;
    }

    // return the color of the texture
    return float4(colorSample);
}
