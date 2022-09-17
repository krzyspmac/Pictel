//
//  gamepad_interface.h
//  Engine
//
//  Created by krzysp on 14/09/2022.
//

#ifndef gamepad_interface_h
#define gamepad_interface_h

#include "common.h"
#include "common_engine_impl.h"
#include "event_provider_interface.h"
#include "callable.hpp"

namespace engine
{
    typedef unsigned int GamepadEventIdentifier;

    /**
     All face buttons are required to be analog in the Extended profile. These must be arranged
     in the diamond pattern given below:

       Y
      / \
     X   B
      \ /
       A

     */
//    @property (nonatomic, readonly) GCControllerButtonInput *buttonA;
//    @property (nonatomic, readonly) GCControllerButtonInput *buttonB;
//    @property (nonatomic, readonly) GCControllerButtonInput *buttonX;
//    @property (nonatomic, readonly) GCControllerButtonInput *buttonY;

    class GamepadI
    {
    protected:
        GamepadType m_gamepadType;
        GamepadMakeFamily m_gamepadFamily;
        GamepadDeviceHandleI *m_handle;

    public:
        GamepadI(GamepadType type, GamepadMakeFamily family, GamepadDeviceHandleI *handle)
            : m_gamepadType(type)
            , m_gamepadFamily(family)
            , m_handle(handle)
        { };

        virtual ~GamepadI() { };

        virtual void ProcessEvent(EventGamepadThumbstickAxisChanged* event) = 0;
        virtual void ProcessButtonEvent(GamepadButtonActionHolder*) = 0;
        virtual void UnregisterEvent(GamepadEventIdentifier) = 0;
        virtual void UnregisterAllEvents() = 0;
        virtual GamepadEventIdentifier RegisterLeftThumbstickAxis(CallableScriptFunctionParameters1<Vector2>) = 0;
        virtual GamepadEventIdentifier RegisterRightThumbstickAxis(CallableScriptFunctionParameters1<Vector2>) = 0;
        virtual GamepadEventIdentifier RegisterDpadAxis(CallableScriptFunctionParameters1<Vector2>) = 0;
        virtual GamepadEventIdentifier RegisterButtonTapped(CallableScriptFunctionParameters2<GamepadButtonType, GamepadButtonAction>) = 0;

        virtual void SetLight(Color3) = 0;
    };
};

#endif /* gamepad_interface_h */
