/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands.
#include "AAPLShaderTypes.h"

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant AAPLVertex *vertices [[buffer(AAPLVertexInputIndexVertices)]],
             constant vector_float2 *viewportSizePointer [[buffer(AAPLVertexInputIndexViewportSize)]],
             constant vector_float2 *viewportOffset [[buffer(AAPLVertexInputIndexViewportOffset)]],
             constant float *objectScalePointer [[buffer(AAPLVertexInputIndexViewportScale)]],
             constant vector_float2 *objectSizePointer [[buffer(AAPLVertexInputIndexObjectSize)]],
             constant vector_float2 *desiredViewportSizePointer [[buffer(AAPLVertexInputIndexViewportTarget)]]
             )
{
    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions (i.e. a value of 100
    // is 100 pixels from the origin).
    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    // Get the viewport size and cast to float.
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);

    // Get the desired viewport size; used to calaculate aspect ratio
    vector_float2 desiredViewportSize = vector_float2(*desiredViewportSizePointer);

    // Get the target object scale
    float objectScale = float(*objectScalePointer);

    // Get the object size
    vector_float2 objectSize = vector_float2(*objectSizePointer);

    // Get the target object translation
    vector_float2 objectTranslation = vector_float2(*viewportOffset);

    // Calculate aspect ratio & scale
    float scaleX, scaleY, scale;
    scaleX = viewportSize.x / (desiredViewportSize.x / objectScale);
    scaleY = viewportSize.y / (desiredViewportSize.y / objectScale);
    scale = min(scaleX, scaleY);

    // Calculate offsets due to scaling
    // TBD

    pixelSpacePosition.xy *= scale;

    float offsetXToEdge = viewportSize.x/2 - ((objectSize.x * scale)/2);

    pixelSpacePosition.x -= offsetXToEdge;
    pixelSpacePosition.x += objectTranslation.x * scale / 2;
    pixelSpacePosition.x += offsetXToEdge;

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

    // Pass the input color directly to the rasterizer.
    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}

