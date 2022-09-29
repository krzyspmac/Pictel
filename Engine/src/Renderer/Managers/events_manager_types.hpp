//
//  events_manager_types.hpp
//  Engine
//
//  Created by krzysp on 30/01/2022.
//

#ifndef events_manager_types_hpp
#define events_manager_types_hpp

#include <iostream>
#include "common.h"
#include "event_provider_interface.h"
#include "engine_provider_interface.h"
#include "interfaces.h"
#include "scripting_engine_provider_interface.h"
#include "gamepad_interface.h"
#include "callable_interface.h"
#include "events_manager_interface.h"
#include "defs.h"

#define KEY_TABLE_SIZE 256

namespace engine
{

    /** The base class for all event holder types. Identifier is used to mark
        the event in order to remove it from the event hander list. */
    /** @private */
    template <typename T>
    class EventHolderI: public EventHolderIdentifier
    {
    public:
        EventHolderI(EventIdentifier identifier)
            : EventHolderIdentifier(identifier)
        { };

    public:
        virtual void Process(T*) = 0;
    };

    /** The base for all LUA script event handlers
     */
    /** @private */
    class EventHolderScript
    {
    public:
        EventHolderScript() { };
    };

    /** Void Handler */
    class EventHolderVoid: public EventHolderI<void>, public EventHolderScript
    {
        std::shared_ptr<CallableParametersEmpty> m_script;
    public:
        EventHolderVoid(EventIdentifier identifier, std::shared_ptr<CallableParametersEmpty> fnc)
            : EventHolderI<void>(identifier)
            , EventHolderScript()
            , m_script(fnc)
        { };

        void Process(void*);
    };

    /** Script variation of the EventHolderKeyShortcutPressed */
    class EventHolderKeyDown: public EventHolderI<char>, public EventHolderScript
    {
        typedef std::shared_ptr<CallableParameters1<char>> FunctionType;
        FunctionType m_script;
    public:
        EventHolderKeyDown(EventIdentifier identifier, FunctionType fnc)
            : EventHolderI<char>(identifier)
            , EventHolderScript()
            , m_script(fnc)
        { };

        void Process(char*);
    };

    /** Holder for mouse moved event. Provides the position. */
    /** @private */
    class EventHolderMouseMoved: public EventHolderI<Origin>, public EventHolderScript
    {
        typedef std::shared_ptr<CallableParameters1<Origin>> FunctionType;

        FunctionType m_script;
    public:
        EventHolderMouseMoved(EventIdentifier identifier, FunctionType fnc)
            : EventHolderI<Origin>(identifier)
            , EventHolderScript()
            , m_script(fnc)
        { };

        void Process(Origin*);
    };

    /** Holder for mouse clicked event. */
    /** @private */
    class EventHolderMouseClicked: public EventHolderMouseMoved
    {
        using EventHolderMouseMoved::EventHolderMouseMoved;
    };

    typedef std::vector<EventFlagType>  EventHolderKeyShortcutFlagsList;
    typedef std::vector<unsigned short> EventHolderKeyShortcutKeyList;

    /** Gamepad Connection Event Handler */
    class EventHolderKeyShortcut: public EventHolderI<void>, public EventHolderScript
    {
        EventHolderKeyShortcutFlagsList m_flags;
        EventHolderKeyShortcutKeyList m_keys;
        std::shared_ptr<CallableParametersEmpty> m_script;
    public:
        EventHolderKeyShortcut(EventIdentifier identifier, EventHolderKeyShortcutFlagsList flags, EventHolderKeyShortcutKeyList keys, std::shared_ptr<CallableParametersEmpty> fnc)
            : EventHolderI<void>(identifier)
            , EventHolderScript()
            , m_script(fnc)
            , m_flags(flags)
            , m_keys(keys)
        { };

        bool Matches(bool shiftDown, bool controlDown, bool keys[KEY_TABLE_SIZE]);
        void Process(void*);
    };

    /** Gamepad Connection Event Handler */
    class EventHolderGamepadConnection: public EventHolderI<GamepadI*>, public EventHolderScript
    {
        std::shared_ptr<CallableParameters2<GamepadI*, bool>> m_script;
    public:
        EventHolderGamepadConnection(EventIdentifier identifier, std::shared_ptr<CallableParameters2<GamepadI*, bool>> fnc)
            : EventHolderI<GamepadI*>(identifier)
            , EventHolderScript()
            , m_script(fnc)
        { };

        void Process(GamepadI**);
    };

    /** Gamepad Stick Event Handler */
    class EventHolderGamepadStickAxis: public EventHolderI<Vector2>, public EventHolderScript
    {
        std::shared_ptr<CallableParameters1<Vector2>> m_script;
    public:
        EventHolderGamepadStickAxis(EventIdentifier identifier, std::shared_ptr<CallableParameters1<Vector2>> fnc)
            : EventHolderI<Vector2>(identifier)
            , EventHolderScript()
            , m_script(fnc)
        { };

        void Process(Vector2*);
    };

    /** Gamepad Button Event Holder */
    class EventHolderGamepadButton: public EventHolderI<GamepadButtonActionHolder>, public EventHolderScript
    {
        std::shared_ptr<CallableParameters3<GamepadButtonType, GamepadButtonAction, float>> m_script;
    public:
        EventHolderGamepadButton(EventIdentifier identifier, std::shared_ptr<CallableParameters3<GamepadButtonType, GamepadButtonAction, float>> fnc)
            : EventHolderI<GamepadButtonActionHolder>(identifier)
            , EventHolderScript()
            , m_script(fnc)
        { };

        void Process(GamepadButtonActionHolder*);
    };
};

#endif /* events_manager_types_hpp */
