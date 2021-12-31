//
//  scene.hpp
//  Engine
//
//  Created by krzysp on 30/12/2021.
//

#ifndef scene_hpp
#define scene_hpp

#include "scripting_engine_provider_interface.h"
#include "sprite_draw_static.hpp"
#include "sprite_draw_animated.hpp"
#include "sprite_atlas.hpp"
#include "character_representation.hpp"
#include <iostream>

namespace engine
{
    class Scene
    {
    ///
    public:

        Scene();
        ~Scene();

    /// Rederer
    public:
        /**
         Render the scene including all the objects that have been
         added to it.
        */
        void RenderScene();

        /**
         Called by the engine. Reacts to mouse clicks.
         */
        void MouseClicked(Vector2 pos);

    public:
        /**
         Helper method to oad the sprite and puts it into the stack.
         Uses SpriteRendererManager.
         \include SampleSpriteStatic-helper.lua
         \ingroup API_EXPOSED
         \see Scene::AddSpriteDrawStatic.
         */
        SpriteDrawStatic *LoadSpriteStatic(SpriteAtlas *atlas, std::string name);

        /**
         Loads the character and puts it in cache. Loads the appropriate atlas and
         atlas items referenced by the json file.
         Uses CharacterManager.
         To move the character you should use CharacterMover.
         \ingroup API_EXPOSED
         */
        CharacterRepresentation *LoadCharacter(std::string jsonFilename);

        /**
         Sets the character as main. By default the character reacts to mouse clicks
         and walks the path unless specified otherwise.
         */
        void SetMainCharacter(CharacterRepresentation*);
    public:
        /**
         Add a sprite renderer to the list of game objects.
         \include SampleSpriteStatic-lowlevel.lua
         \ingroup API_EXPOSED
         */
        void AddSpriteDrawStatic(SpriteDrawStatic*);

    /// Variables
    private:
        std::vector<SpriteDrawStatic*> m_staticSprites;
        std::vector<CharacterRepresentation*> m_characterRepresentations;
        CharacterRepresentation *m_mainCharacter;

    /// ScriptingInterface
    public:
        /// @private
        SCRIPTING_INTERFACE_HEADERS(Scene);
    };
};

#endif /* scene_hpp */
