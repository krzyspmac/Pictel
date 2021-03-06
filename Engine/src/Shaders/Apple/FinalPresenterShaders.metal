//
//  FinalPresenterShaders.metal
//  Engine
//
//  Created by krzysp on 13/02/2022.
//

#include <metal_stdlib>
using namespace metal;

#include "AAPLShaderTypes.h"
#include "SharedShaders.metal"

// Vertex shader which adjusts positions by an aspect ratio and passes texture
// coordinates through to the rasterizer.
vertex RasterizerData
presenterVertexShader(const uint vertexID [[ vertex_id ]],
                      const device AAPLVertex *vertices [[ buffer(AAPLVertexInputIndexVertices) ]],
                      constant vector_float2  *viewportSizePointer [[buffer(AAPLVertexInputIndexWindowSize)]],
                      constant float          *viewportScalePointer [[buffer(AAPLVertexInputIndexWindowScale)]],
                      constant vector_float2  *desiredViewportSizePointer [[buffer(AAPLVertexInputIndexViewportSize)]],
                      constant float          *affineScalePointer     [[buffer(AAPLVertexInputIndexObjectScale)]]
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

    // Get the target final scale for the texture
    float targetAffineScale = float(*affineScalePointer);

    float2 scale = viewportSize / desiredViewportSize;

    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / scale * targetAffineScale;
    out.textureCoordinate = vertices[vertexID].textureCoordinate;

    return out;
}
// Fragment shader that samples a texture and outputs the sampled color.
fragment float4 presenterFragmentShader(RasterizerData in  [[stage_in]],
                                        texture2d<float> texture [[texture(FragmentShaderIndexBaseColor)]])
{
    constexpr sampler simpleSampler;

    // Sample data from the texture.
    float4 colorSample = texture.sample(simpleSampler, in.textureCoordinate);

    // Return the color sample as the final color.
    return colorSample;
}
