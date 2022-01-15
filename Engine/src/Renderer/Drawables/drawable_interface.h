//
//  drawable_interface.h
//  Engine
//
//  Created by krzysp on 12/01/2022.
//

#ifndef drawable_interface_h
#define drawable_interface_h

#include "common.h"
#include "common_engine_impl.h"

namespace engine
{
    /** Declares an abstract interface for the final object that will be drawn using the EngineProviderI.
        Different backend for different libraries might declare differently working concrete instances.

        The `drawable` is usually composed of vertex data and texture data.
     */
    class DrawableI
    {
    public:
        DrawableI(float width, float height)
            : m_scale(1.0f)
            , m_alpha(255)
        { };

        void SetScale(float val) { m_scale = val; }
        float *GetScale() { return &m_scale; };

        /** 0-255 */
        void SetAlpha(uint8_t val) { m_alpha = val; };

        /** 0-255 */
        uint8_t GetAlpha() { return m_alpha; };

    protected:
        float m_scale;
        uint8_t m_alpha;
    };
};

#endif /* drawable_interface_h */
