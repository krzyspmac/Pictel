/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC source
*/

#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs
// match Metal API buffer set calls.
typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices        = 0,        // the vertices
    AAPLVertexInputIndexUniforms        = 1,        // uniforms; non change-able during rendering pass
    AAPLVertexInputIndexWindowSize      = 2,        // the current window size
    AAPLVertexInputIndexWindowScale     = 3,        // the current window scale
    AAPLVertexInputIndexObjectOffset    = 4,        // the object translation from the top, left corner in viewport coordinates
    AAPLVertexInputIndexObjectScale     = 5,        // the object scale
    AAPLVertexInputIndexObjectSize      = 6,        // the size of the object
    AAPLVertexInputIndexViewportSize    = 7,        // the current viewport size; usually
                                                    // set at the beginning; this is also the
                                                    // size of the framebuffer texture
} AAPLVertexInputIndex;

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
typedef enum AAPLTextureIndex
{
    AAPLTextureIndexBaseColor           = 0,
    AAPLTextureIndexBaseAlpha           = 1,
    AAPLVertexInputIndexLight           = 2,        // An array of light information
    AAPLVertexInpueIndexLightCount      = 3
} AAPLTextureIndex;

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
typedef struct
{
    // Positions in pixel space. A value of 100 indicates 100 pixels from the origin/center.
    vector_float2 position;

    // 2D texture coordinate
    vector_float2 textureCoordinate;

    // The light amount; 0-1
    float lightAmount;
} AAPLVertex;

// float size == 4
typedef struct
{
    vector_float3 color;            // 0-2
    float ambientIntensity;         // 3

    vector_float2 position;         // 4-5
    float diffuse_size;             // 6

    float diffuse_intensity;        // 7

//    float reserved1;                // 8
//    float reserved2;                // 9
//    float reserved3;                // 10
//    float reserved4;                // 11
    /*
    _______________________
   |0 1 2 3|4 5 6 7|8 9 10   |
    -----------------------
   |       |       |       |
   | chunk0| chunk1| chunk2|
    */
} AAPAmbientLLight;

#endif /* AAPLShaderTypes_h */
