
#include "GameSceneIntro.hpp"

GameSceneIntro::GameSceneIntro(GameResolutionState *resState)
    : m_resState(resState)
{
    m_font = engine::Globals::fontManager()->LoadFont("at01.fnt", "at01.png");
    m_scene = engine::Globals::sceneManager()->SceneCreateNew();
    m_textSprite = m_scene->SpriteTextLoad(m_font);

    m_texts = {
        "This game is made using a custom built engine"
      , "Some things might not work.\nA lot of them actually."
      , "Drop me a line if wish.\nMore in the game menu"
    };

    auto size = m_resState->GetViewportSize();

    m_textSprite->SetText("Test");
    m_textSprite->SetPosition({size.x / 2, size.y / 2});
    m_textSprite->SetColorMod({1.f, 1.f, 1.f, 1.f});
    m_textSprite->SetHorizontalAlignment("center");
    m_textSprite->SetVerticalAlignment("middle");
    m_textSprite->SetScale(2.0f);

    m_scene->SetFrameUpdate([&]{
        FrameUpdate();
    });

    ContinueAnimation();
}

void
GameSceneIntro::DidActivate() {
}

void
GameSceneIntro::DidDeactivate() {
}

void
GameSceneIntro::FrameUpdate() {
    auto size = m_resState->GetViewportSize();
    printf("width = %f\n", size.x);
}

void
GameSceneIntro::ContinueAnimation() {
    auto propertyAnimatorFactory = engine::Globals::propertyAnimatorFactory();

    m_fadeIn = propertyAnimatorFactory
        ->FadeIn(m_textSprite, "linear", 0.2, 1, std::shared_ptr<engine::CallbackEmpty>(new engine::CallbackEmpty([&] {
            m_fadeOut->Start();
            }))
    );
    
    m_fadeOut = propertyAnimatorFactory
        ->FadeOut(m_textSprite, "linear", 0.2, 1, std::shared_ptr<engine::CallbackEmpty>(new engine::CallbackEmpty([&] {
            m_fadeIn->Start();
            }))
    );

    m_fadeIn->Start();
}
