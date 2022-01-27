//
//  engine.cpp
//  Engine
//
//  Created by krzysp on 01/01/2022.
//

#include "engine_state.hpp"
#include "engine.hpp"
#include "common.h"

using namespace engine;

EngineState::EngineState()
    : m_screenSizeChangeHandler(nullptr)
    , m_screenSizeChangeScriptHandler(CallableScriptFunctionSciptableInstance::none())
{

}

Size EngineState::GetViewportSize()
{
    return GetMainEngine()->getProvider().GetDesiredViewport();
}

void EngineState::SetOnScreenSizeChange(std::function<void (Size)> lambda)
{
    m_screenSizeChangeHandler = lambda;
}

void EngineState::SetOnScreenSizeChange(CallableScriptFunctionSciptableInstance handler)
{
    m_screenSizeChangeScriptHandler = handler;
}

void EngineState::SendScreenSizeChangeEvent(Size size, float density)
{
    if (m_screenSizeChangeHandler != nullptr)
    {
        m_screenSizeChangeHandler(size);
    }

    if (m_screenSizeChangeScriptHandler.CanCall())
    {
        m_screenSizeChangeScriptHandler.PerformCall([&](lua_State *L){
            lua_pushnumber(L, size.width);
            lua_pushnumber(L, size.height);
            lua_pushnumber(L, density);
            return 3;
        });
    }
}

#pragma mark - Scripting Interface

SCRIPTING_INTERFACE_IMPL_NAME(EngineState);

static int lua_EngineState_GetViewport(lua_State *L)
{
    EngineState *spr = ScriptingEngineI::GetScriptingObjectPtr<EngineState>(L, 1);
    Size size = spr->GetViewportSize();
    lua_pushnumber(L, size.width);
    lua_pushnumber(L, size.height);
    return 2;
}

static int lua_EngineState_SetOnScreenSizeChange(lua_State *L)
{
    EngineState *obj = ScriptingEngineI::GetScriptingObjectPtr<EngineState>(L, 1);
    int fnRef = luaL_ref( L, LUA_REGISTRYINDEX );
    obj->SetOnScreenSizeChange(CallableScriptFunctionSciptableInstance(fnRef));
    return 0;
}

std::vector<luaL_Reg> EngineState::ScriptingInterfaceFunctions()
{
    std::vector<luaL_Reg> result({
        { "GetViewportSize", &lua_EngineState_GetViewport}
      , { "SetOnScreenSizeChange", &lua_EngineState_SetOnScreenSizeChange}
    });
    return result;
}
