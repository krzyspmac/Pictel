//
//  sprite_atlas.hpp
//  RendererAppSDL
//
//  Created by krzysp on 22/12/2021.
//

#ifndef sprite_atlas_hpp
#define sprite_atlas_hpp

#include "common.h"
#include "sprite_atlas_interface.h"
#include "scripting_engine_provider_interface.h"

namespace engine
{
    /**
     \ingroup API_EXPOSED
     */
    class SpriteAtlas: public SpriteAtlasI
    {
    public:
        /** @private */
        SpriteAtlas(std::string jsonFilename, std::string textureFilename);

        /** @private */
        ~SpriteAtlas();

        /**
         Get the specific atlas item for the name.
         \ingroup API_EXPOSED
         */
        SpriteAtlasItemI *GetItemForName(std::string name);

        /** @private */
        std::string &GetFilename() { return m_filename; };

    private:
        std::string m_filename;
        TextureI *m_texture;
        std::vector<SpriteAtlasItemI> m_items;

    /// ScriptingInterface
    public:
        /** @private */
        SCRIPTING_INTERFACE_HEADERS(SpriteAtlas);
    };
};

#endif /* sprite_atlas_hpp */
