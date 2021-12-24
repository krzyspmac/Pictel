//
//  sprite_draw_interface.h
//  RendererAppSDL
//
//  Created by krzysp on 22/12/2021.
//

#ifndef sprite_draw_interface_h
#define sprite_draw_interface_h

#include "sprite_interface.h"

namespace engine
{

    class SpriteDrawI
    {
    public:
        SpriteDrawI(SpriteI *sprite)
            : m_sprite(sprite)
        { };

    public:
        virtual void Draw(int x, int y) = 0;

    protected:
        SpriteI *m_sprite;
    };
};

#endif /* sprite_draw_interface_h */