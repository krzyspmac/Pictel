//
//  RendererEntrySDL.hpp
//  RendererAppSDL
//
//  Created by krzysp on 20/12/2021.
//

#ifndef RendererEntry_hpp
#define RendererEntry_hpp

#include <stdio.h>
#include "common.h"
#include "file_access_provider.h"
#include "engine_provider_interface.h"
#include "scripting_engine_provider_interface.h"
#include "engine_interface.h"
#include "engine.hpp"
#include "events_manager.hpp"
#include "character_manager.hpp"
#include "scene_manager.hpp"
#include "sprite_atlas_manager.hpp"
#include "sprite_renderer_manager.hpp"
#include "console_renderer.h"
#include "texture_manager.hpp"
#include "font_manager.hpp"
#include "engine_provider_sdl.hpp"

namespace engine
{

class RendererEntrySDL
{
public:
    ///
    RendererEntrySDL();

    ///
    int initSDL();

    void destroy();

    void prepare();

    void doInput();

    void doScene();

    ///
    void main(int argc, const char *argv[]);

private:
    engine::FileAccessI *m_fileAccess;
    engine::TextureManager *m_textureManager;
    engine::EngineProviderSDL *m_engineProvider;
    engine::FontManager *m_fontManager;
    engine::ScriptingEngineI *m_scriptingEngine;
    engine::EventProviderI *m_eventProvider;
    engine::EventsManager *m_eventsManager;
    engine::CharacterManager *m_characterManager;
    engine::SceneManager *m_sceneManager;
    engine::SpriteAtlasManager *m_spriteAtlasManager;
    engine::SpriteRendererManager *m_sprireRendererManager;
    engine::ConsoleRenderer *m_consoleRenderer;
    engine::Engine *m_engine;
};

}; // namespace

#endif /* RendererEntry_hpp */
