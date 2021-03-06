//
//  light_interface.hpp
//  Engine
//
//  Created by krzysp on 05/02/2022.
//

#ifndef light_interface_h
#define light_interface_h

#include "common_engine_impl.h"
#include <iostream>

namespace engine
{
    typedef enum
    {
        LIGHT_FALLOUT_TYPE_LINEAR       = 0
      , LIGHT_FALLOUT_TYPE_EXP          = 1
    } LightFalloffType;

    typedef struct {
        std::string name;
        LightFalloffType type;
    } LightInfo;

    class LightI
    {
    public:
        LightI(LightFalloffType type, Color3 color, float ambientIntensity, Origin position, float diffuseSize, float diffuseIntensity)
        { };

        static std::vector<LightInfo>& LIGHT_TYPES() {
            static std::vector<LightInfo> lightTypes =
            {
                { "linear", LIGHT_FALLOUT_TYPE_LINEAR }
              , { "exponential", LIGHT_FALLOUT_TYPE_EXP }
            };

            return lightTypes;
        }

        static LightFalloffType GetFalloutTypeForName(std::string type)
        {
            auto lightInfo = matching<LightInfo>(LightI::LIGHT_TYPES(), [&](LightInfo& info){
                return info.name == type;
            });
            if (lightInfo != nullptr)
            {
                return lightInfo->type;
            }
            else
            {
                return LIGHT_FALLOUT_TYPE_LINEAR;
            }
        }

        virtual LightFalloffType GetType() = 0;
        virtual void SetType(LightFalloffType) = 0;
        virtual Color3& GetColor() = 0;
        virtual void SetColor(Color3) = 0;
        virtual bool GetIsEnabled() = 0;
        virtual void SetIsEnabled(bool) = 0;
        virtual std::string& GetName() = 0;
        virtual float& GetAmbientIntensity() = 0;
        virtual void SetAmbientIntensity(float) = 0;
        virtual float& GetDiffuseIntensity() = 0;
        virtual void SetDiffuseIntensity(float) = 0;
        virtual float& GetDiffuseSize() = 0;
        virtual void SetDiffuseSize(float) = 0;
        virtual Origin& GetPosition() = 0;
        virtual void SetPosition(Origin) = 0;
    };
};

#endif /* light_interface_h */
