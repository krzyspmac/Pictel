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
    AAPLVertexInputIndexWindowSize      = 1,        // the current window size
    AAPLVertexInputIndexWindowScale     = 2,        // the current window scale
    AAPLVertexInputIndexObjectOffset    = 3,        // the object translation from the top, left corner in viewport coordinates
    AAPLVertexInputIndexObjectScale     = 4,        // the object scale
    AAPLVertexInputIndexObjectSize      = 5,        // the size of the object
    AAPLVertexInputIndexViewportSize    = 6,        // the current viewport size; usually
                                                    // set at the beginning; this is also the
                                                    // size of the framebuffer texture
} AAPLVertexInputIndex;

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
typedef enum AAPLTextureIndex
{
    AAPLTextureIndexBaseColor = 0,
    AAPLTextureIndexBaseAlpha = 1,
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
} AAPLVertex;

#endif /* AAPLShaderTypes_h */