//
//  engine.hpp
//  RendererApp
//
//  Created by krzysp on 19/12/2021.
//

#ifndef engine_hpp
#define engine_hpp

#import "common.h"
#import "engine_interface.h"
#import "engine_provider_interface.h"
#import "file_access_provider.h"
#import "scripting_engine_provider_interface.h"

namespace engine
{
    class Engine: public EngineI
    {
    public:
        ///
        Engine(EngineProviderI &engine, FileAccessI &fileAccess, ScriptingEngineI &scriptingEngine);

        ~Engine();

        void setup();
        void update();
        TextureI *LoadTexture(std::string name);
        TextureI *GetTexture(std::string name);
        void DrawTexture(TextureI *texture, int x, int y);
        void UnloadTexture(TextureI *texture);
        void DisposeAllTextures();

        FontI *LoadFont(std::string name);
        FontI *GetFont(std::string name);
        void DrawText(FontI *font, std::string text, int x, int y, int r, int g, int b, TEXT_ALIGNMENT align);
        void DisposeAllFonts();

    private:
        std::vector<std::unique_ptr<TextureI>> m_textures;
        std::vector<std::unique_ptr<FontI>> m_fonts;
    };
}

#endif /* engine_hpp */
