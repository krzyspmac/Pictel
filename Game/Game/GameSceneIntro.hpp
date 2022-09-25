//
//  GameSceneIntro.hpp
//  Game-Mac
//
//  Created by krzysp on 25/09/2022.
//

#ifndef GameSceneIntro_hpp
#define GameSceneIntro_hpp

#include "GameSceneInterface.hpp"
#include "interfaces.h"

class GameSceneIntro: public GameSceneI {
    engine::FontI *m_font;
public: // GameSceneIntro
    GameSceneIntro();

public: // GameSceneI
    void DidActivate();
    void DidDeactivate();
};

#endif /* GameSceneIntro_hpp */