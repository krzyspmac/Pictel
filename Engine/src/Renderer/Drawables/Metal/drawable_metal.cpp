//
//  drawable_metal.cpp
//  Engine
//
//  Created by krzysp on 12/01/2022.
//

#include "drawable_metal.hpp"

using namespace engine;

DrawableMetal::DrawableMetal(SpriteAtlasItemI *atlasItem)
    : DrawableSpriteI(atlasItem)
{
    auto metalTextrue = (TextureMetal*)atlasItem->GetTexture();
    if (metalTextrue->GetMTLTextureHandle() == nullptr)
    {
        m_size = { 0, 0 };
        m_triangleVertices = 0;
        m_triangleVerticiesDataSize = 0;
        m_vertexCount = 0;
        return;
    };

    m_vertexCount = 6;
    m_triangleVertices = (AAPLVertex*)malloc(m_vertexCount * sizeof(AAPLVertex));

    auto textureSize = metalTextrue->GetSize();
    
    float x = atlasItem->GetX() / textureSize.x;
    float y = atlasItem->GetY() / textureSize.y;
    float w = (atlasItem->GetX() +atlasItem->GetWidth()) / textureSize.x;
    float h = (atlasItem->GetY() + atlasItem->GetHeight()) / textureSize.y;
    
    m_texture = metalTextrue;

    float width = atlasItem->GetWidth();
    float height = atlasItem->GetHeight();
    float width2 = width/2;
    float height2 = height/2;
    
    // Set up a simple MTLBuffer with vertices which include texture coordinates
    static const AAPLVertex data[] =
    {
        // Pixel positions, Texture coordinates
        { { -width2,  -height2 },   { x, h } },
        { { -width2,   height2 },   { x, y } },
        { {  width2,   height2 },   { w, y } },

        { {  width2,    height2 },  { w, y } },
        { {  width2,   -height2 },  { w, h } },
        { { -width2,   -height2 },  { x, h } },
    };
    
    m_triangleVerticiesDataSize = sizeof(data);
    memcpy(m_triangleVertices, data, m_triangleVerticiesDataSize);
}

bool DrawableMetal::CanDraw()
{
    return m_vertexCount > 0;
}

vector_float2 *DrawableMetal::GetSize()
{
    return &m_size;
}

AAPLVertex *DrawableMetal::GetVertexData()
{
    return m_triangleVertices;
}

size_t DrawableMetal::GetVertexDataSize()
{
    return m_triangleVerticiesDataSize;
}

size_t DrawableMetal::GetVertexCount()
{
    return m_vertexCount;
}