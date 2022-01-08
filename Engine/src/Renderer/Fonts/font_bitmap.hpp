//
//  font_bitmap.hpp
//  Engine
//
//  Created by krzysp on 06/01/2022.
//

#ifndef font_bitmap_hpp
#define font_bitmap_hpp

#include "common.h"
#include "key_value.hpp"
#include "font_interface.h"
#include "common_engine_impl.h"
#include "vector2.hpp"
#include "texture_interface.h"

namespace engine
{
    /**
     Defines the bitmap font properties.
     Not all properties are supported atm.
     \see https://www.angelcode.com/products/bmfont/doc/file_format.html
     */
    typedef struct
    {
        std::string face;
        size_t size;
        Vector2 spacing;
    } FontBitmapDescriptorInfo;

    typedef struct
    {
        int lineHeight;
        int base;
        int scaleW;
        int scaleH;
    } FontBitmapDescriptorCommon;

    typedef struct
    {
        std::string m_textureFilename;
        FontBitmapDescriptorInfo info;
        FontBitmapDescriptorCommon common;
    } FontBitmapInfo;

    class FontBitmapGlyph
    {
        int m_characterId;
        Rect m_textureRect;
        Size m_Offset;
        int m_xAdvance;
        std::string m_letterName;

    public:
        FontBitmapGlyph(int id, int x, int y, int w, int h, int xO, int yO, int xA, std::string letterName);
        FontBitmapGlyph(KeyValueProperties& properties);

        auto& GetId() { return m_characterId; };
        auto& GetRect() { return m_textureRect; };
        auto& GetOffset() { return m_Offset; };
        auto& GetXAdvance() { return m_xAdvance; };
    };

    typedef struct
    {
        int first;
        int second;
        int amount;
    } FontBitmapGlyphKerning;

    /**
     Declares a concrete instance for rendering bitmpa fonts
     using a sprite atlas sheet and a .fnt file in text format.
     */
    class FontBitmapDescriptor
    {
        FontBitmapInfo m_sDescriptor;
        std::vector<FontBitmapGlyph> m_glyphs;
        std::vector<FontBitmapGlyphKerning> m_kerning;

        void Prepare(std::string fntFile);
        void BuildDescriptorFace(KeyValueProperties&);
        void BuildDescriptorCommon(KeyValueProperties&);
        void BuildDescriptorKerning(KeyValueProperties&);
    public:
        /**
         Create a bitmap bit.
         @private
         @param fntFile     - path to a FNT file (in text format)
         @param fontAtlas   - path to the bitmap containing the font sprite sheet.
         */
        FontBitmapDescriptor(std::string fntFile, std::string fontAtlas);

        auto& GetDescriptor() { return m_sDescriptor; };

        FontBitmapGlyph *GetGlyph(char&);

        int GetKerningAmount(int first, int second);
    };

    /**
     Declares the rendering engine for the font.
     */
    class FontBitmapRepresentation: FontI
    {
        FontBitmapDescriptor m_font;
        TextureI *m_texture;
    public:
        /**
         Create a bitmap bit.
         @param fntFile     - path to a FNT file (in text format)
         @param fontAtlas   - path to the bitmap containing the font sprite sheet.
         */
        FontBitmapRepresentation(std::string fntFile, std::string fontAtlas);

        void DrawAt(std::string text, float x, float, int r, int g, int b, int a, TEXT_ALIGNMENT align);
    };
};

#endif /* font_bitmap_hpp */