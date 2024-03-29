// Copyright (c) 2022 Krzysztof Pawłowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
// OR OTHER DEALINGS IN THE SOFTWARE.

#import "RendererEntryViewController.h"
#include "common.h"
#include "interfaces.h"

#ifdef APPLE
#include "gamepad_apple_handle.hpp"
#endif

using namespace engine;

static GamepadButtonAction GamepadButtonActionFromPressed(bool);

@implementation RendererEntryViewController (Events)

#pragma mark - Setup

- (void)setupEvents
{
    if (didSetupEvents) { return; };

    [self setupMouseClickEvents];
    [self setupMouseMovedEvents];
    [self setupKeyEvents];
    [self setupControllers];
    [self createVirtualControllerIfNeeded];

    didSetupEvents = YES;
}

- (void)setupMouseClickEvents
{
#if defined(TARGET_IOS) || defined(TARGET_TVOS)
#else
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseUp handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
#if SHOW_CONSOLE
        if (!self->m_consoleRenderer->GetConsoleHidden())
        {
            bool result = self->m_consoleRendererProvider->HandleEvent(event);
            if (result) { return event; };
        }
#endif

        self->m_engine->getEventProvider().PushMouseLeftUp();
        return event;
    }];
#endif
}

- (void)setupMouseMovedEvents
{
#if defined(TARGET_IOS) || defined(TARGET_TVOS)
#else
    NSView *view = self.view;
    if (mouseTrackingArea)
    {
        [view removeTrackingArea: mouseTrackingArea];
    }

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:view.bounds
                                                        options:NSTrackingActiveInKeyWindow|NSTrackingMouseMoved
                                                          owner:self
                                                       userInfo:nil];
    [view addTrackingArea:area];
#endif
}

- (void)setupKeyEvents
{
#if defined(TARGET_IOS) || defined(TARGET_TVOS)
#else
    // If we want to receive key events, we either need to be in the responder chain of the key view,
    // or else we can install a local monitor. The consequence of this heavy-handed approach is that
    // we receive events for all controls, not just Dear ImGui widgets. If we had native controls in our
    // window, we'd want to be much more careful than just ingesting the complete event stream.
    // To match the behavior of other backends, we pass every event down to the OS.
    NSEventMask eventMask = NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskFlagsChanged;
    [NSEvent addLocalMonitorForEventsMatchingMask:eventMask handler:^NSEvent * _Nullable(NSEvent *event)
    {
#if SHOW_CONSOLE
        if (!self->m_consoleRenderer->GetConsoleHidden())
        {
            self->m_consoleRendererProvider->HandleEvent(event);
        }
#endif

        auto& eventsProvider = ENGINE().getEventProvider();
        switch (event.type)
        {
            case NSEventTypeKeyDown:
            {
                if (event.ARepeat ) { break; };

                NSString *characters = event.charactersIgnoringModifiers;
                for (NSInteger i = 0; i < characters.length; i++)
                {
                    unichar c = [characters characterAtIndex:i];
                    eventsProvider.PushKeyStateChange((unsigned short)c, true);
                }
                break;
            }
            case NSEventTypeKeyUp:
            {
                if (event.ARepeat ) { break; };

                NSString *characters = event.charactersIgnoringModifiers;
                for (NSInteger i = 0; i < characters.length; i++)
                {
                    unichar c = [characters characterAtIndex:i];
                    eventsProvider.PushKeyStateChange((unsigned short)c, false);
                }
                break;
            }
            case NSEventTypeFlagsChanged:
            {
                NSEventModifierFlags flags = event.modifierFlags;

                bool isShift = flags & NSEventModifierFlagShift;
                eventsProvider.PushFlagsChange(FLAG_SHIFT, isShift);

                bool isControl = flags & NSEventModifierFlagControl;
                eventsProvider.PushFlagsChange(FLAG_CONTROL, isControl);

                bool isAlt = flags & NSEventModifierFlagOption;
                eventsProvider.PushFlagsChange(FLAG_ALT, isAlt);

                bool isCommand = flags & NSEventModifierFlagCommand;
                eventsProvider.PushFlagsChange(FLAG_COMMAND, isCommand);

                break;
            }
            default:
            {
                break;
            }
        }

        // TODO: do not send all events to the system!
        return NULL;
    }];
#endif
}

#pragma mark - Handling

#if TARGET_OSX
- (void)handle:(NSEvent*)event
{
#if SHOW_CONSOLE
    if (!self->m_consoleRenderer->GetConsoleHidden())
    {
        m_consoleRendererProvider->HandleEvent(event);
    }
#endif
}
#endif

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
#else

- (void)mouseMoved:(NSEvent *)event
{
    NSView    *view = self.view;
    CGRect    viewFrame = view.frame;
    CGPoint   locationInView = [view convertPoint:[event locationInWindow] fromView:nil];

    /** Make the origin top, left */
    locationInView.y = viewFrame.size.height - locationInView.y;

    /** Get the desired viewport set by the engine */
    auto& viewport = m_engine->GetEngineSetup().resolution;

    /** Get the scale that was applied to the viewport in order to render it on-screen*/
    float aspect = desiredFramebufferTextureSize.x / desiredFramebufferTextureSize.y;
    float viewFrameAspect = CGRectGetWidth(viewFrame) / CGRectGetHeight(viewFrame);
    simd_float2 displayFramebufferSize;
    if (viewFrameAspect >= aspect)
    {
        displayFramebufferSize.y = viewFrame.size.height;
        displayFramebufferSize.x = displayFramebufferSize.y * aspect;
    }
    else
    {
        displayFramebufferSize.x = viewFrame.size.width;
        displayFramebufferSize.y = displayFramebufferSize.x / aspect;
    }

    /** Scale & offset the position to take into account that the viewport may be
        scaled and translated/centered in the backing window/surface. */
    locationInView.x -= ceil((CGRectGetWidth(viewFrame) - displayFramebufferSize.x)/2);
    locationInView.x = MAX(0, MIN(locationInView.x, displayFramebufferSize.x));

    locationInView.y -= ceil((CGRectGetHeight(viewFrame) - displayFramebufferSize.y)/2);
    locationInView.y = MAX(0, MIN(locationInView.y, displayFramebufferSize.y));

    float xPer = locationInView.x / displayFramebufferSize.x;
    float yPer = locationInView.y / displayFramebufferSize.y;

    /** Calcualte position in the viewport */
    Origin locationInViewport;
    locationInViewport.x = (int)(xPer * (float)viewport.width);
    locationInViewport.y = (int)(yPer * (float)viewport.height);

    /** Send the calcualted position ot the engine provider */
//    m_engine->getEventProvider().PushMouseLocation(locationInViewport);

    /** Also handle other events if necessary */
    [self handle:event];
}

- (void)keyDown:(NSEvent *)event             { [self handle:event]; }
- (void)keyUp:(NSEvent *)event               { [self handle:event]; };
- (void)mouseDown:(NSEvent *)event           { [self handle:event]; }
- (void)rightMouseDown:(NSEvent *)event      { [self handle:event]; }
- (void)otherMouseDown:(NSEvent *)event      { [self handle:event]; }
- (void)mouseUp:(NSEvent *)event             { [self handle:event]; }
- (void)rightMouseUp:(NSEvent *)event        { [self handle:event]; }
- (void)otherMouseUp:(NSEvent *)event        { [self handle:event]; }
- (void)mouseDragged:(NSEvent *)event        { [self handle:event]; }
- (void)rightMouseMoved:(NSEvent *)event     { [self handle:event]; }
- (void)rightMouseDragged:(NSEvent *)event   { [self handle:event]; }
- (void)otherMouseMoved:(NSEvent *)event     { [self handle:event]; }
- (void)otherMouseDragged:(NSEvent *)event   { [self handle:event]; }
- (void)scrollWheel:(NSEvent *)event         { [self handle:event]; }

#endif // defined(TARGET_IOS) || defined(TARGET_TVOS)

- (void)setupControllers
{
#if USE_CONTROLLERS
    if (!ENGINE().GetEngineSetup().gamepad_support)
    {   return;
    }

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didConnectController:) name:GCControllerDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(didDisconnectController:) name:GCControllerDidDisconnectNotification object:nil];

    [self setupControllerHandlers];
    [self processController];
#endif
}

#if USE_CONTROLLERS

- (void)didConnectController:(NSNotification*)notification
{
    [self processController];
}

- (void)didDisconnectController:(NSNotification*)notification
{
    [self processController];
}

- (void)setupControllerHandlers
{
    Engine *weakEngine = self->m_engine;

    self.leftThumbstickHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        weakEngine->getEventProvider().PushLeftThumbstickAxisChange(xValue, -yValue);
    };
    self.rightThumbstickHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        weakEngine->getEventProvider().PushRightThumbstickAxisChange(xValue, -yValue);
    };
    self.dpadThumbstickHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        weakEngine->getEventProvider().PushDpadAxisChange(xValue, -yValue);
    };
    self.handlerButtonA = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_A, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonB = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_B, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonX = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_X, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonY = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_Y, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonMenu = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_MENU, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonOptions = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_OPTIONS, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonLeftShoulder = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_LEFT_TRIGGER, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonLeftTrigger = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_LEFT_SHOULDER, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonRightShoulder = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_RIGHT_TRIGGER, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonRightTrigger = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_RIGHT_SHOULDER, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonLeftThumbstickButton = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_LEFT_THUMBSTICK_BTN, GamepadButtonActionFromPressed(pressed), button.value));
    };
    self.handlerButtonRightThumbstickButton = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        weakEngine->getEventProvider().PushButtonAction(engine::GamepadButtonActionHolder(GAMEPAD_BUTTON_RIGHT_THUMBSTICK_BTN, GamepadButtonActionFromPressed(pressed), button.value));
    };
}

- (void)processController
{
    [self setupController];
}

- (void)setupController
{
    if (!ENGINE().GetEngineSetup().gamepad_support)
    {   return;
    }

    NSArray<GCController*> *controllers = [GCController controllers];
    self.controller = [controllers firstObject];

#if TARGET_IOS
    if (!self.controller)
    {
        if (self.virtualController != nil)
        {
            self.controller = self.virtualController.controller;
        }
    }
#endif
    
    [self setupControllerProfiles: self.controller];
}

- (void)setupControllerProfiles:(GCController*)controller
{
    GCMicroGamepad *controllerMicroProfile = controller.microGamepad;
    GCExtendedGamepad *controllerExtendedProfile = controller.extendedGamepad;

    if (controllerExtendedProfile != nil)
    {
        GCControllerDirectionPad *leftThumbstick = controllerExtendedProfile.leftThumbstick;
        GCControllerDirectionPad *rightThumbstick = controllerExtendedProfile.rightThumbstick;
        GCControllerDirectionPad *controllerDPad = controllerExtendedProfile.dpad;

        leftThumbstick.valueChangedHandler = self.leftThumbstickHandler;
        rightThumbstick.valueChangedHandler = self.rightThumbstickHandler;
        controllerDPad.valueChangedHandler = self.dpadThumbstickHandler;

        controllerExtendedProfile.buttonA.valueChangedHandler = self.handlerButtonA;
        controllerExtendedProfile.buttonB.valueChangedHandler = self.handlerButtonB;
        controllerExtendedProfile.buttonX.valueChangedHandler = self.handlerButtonX;
        controllerExtendedProfile.buttonY.valueChangedHandler = self.handlerButtonY;
        controllerExtendedProfile.buttonMenu.valueChangedHandler = self.handlerButtonMenu;
        controllerExtendedProfile.buttonOptions.valueChangedHandler = self.handlerButtonOptions;
        controllerExtendedProfile.leftShoulder.valueChangedHandler = self.handlerButtonLeftShoulder;
        controllerExtendedProfile.leftTrigger.valueChangedHandler = self.handlerButtonLeftTrigger;
        controllerExtendedProfile.rightShoulder.valueChangedHandler = self.handlerButtonRightShoulder;
        controllerExtendedProfile.rightTrigger.valueChangedHandler = self.handlerButtonRightTrigger;
        controllerExtendedProfile.leftThumbstickButton.valueChangedHandler = self.handlerButtonLeftThumbstickButton;
        controllerExtendedProfile.rightThumbstickButton.valueChangedHandler = self.handlerButtonLeftThumbstickButton;

        GamepadAppleHandle *gampadHandle = new GamepadAppleHandle(self.controller);
        m_engine->getEventProvider().PushGamepadConnectionEvent(GAMEPAD_TYPE_EXTENDED, GAMEPAD_MAKE_SONY, GAMEPAD_CONNECTION_STATUS_CONNECTED, gampadHandle);
    }
    else if (controllerMicroProfile != nil)
    {
        GCControllerDirectionPad *controllerDPad = controllerMicroProfile.dpad;
        controllerDPad.valueChangedHandler = self.dpadThumbstickHandler;
        controllerMicroProfile.buttonA.valueChangedHandler = self.handlerButtonA;
        controllerMicroProfile.buttonX.valueChangedHandler = self.handlerButtonX;
        controllerMicroProfile.buttonMenu.valueChangedHandler = self.handlerButtonMenu;

        GamepadAppleHandle *gampadHandle = new GamepadAppleHandle(self.controller);
        m_engine->getEventProvider().PushGamepadConnectionEvent(GAMEPAD_TYPE_SIMPLE, GAMEPAD_MAKE_SONY, GAMEPAD_CONNECTION_STATUS_CONNECTED, gampadHandle);
    }
    else
    {
        m_engine->getEventProvider().PushGamepadConnectionEvent(GAMEPAD_TYPE_EXTENDED, GAMEPAD_MAKE_SONY, GAMEPAD_CONNECTION_STATUS_DISCRONNECTED, nil);
    }
}

- (void)createVirtualController
{
#if TARGET_IOS
    if (!ENGINE().GetEngineSetup().gamepad_virtual_support)
    {   return;
    }

    auto &engineSetup = m_engine->GetEngineSetup();
    auto buttonConfig = engineSetup.gamepad_virtual_configuration;

    NSMutableSet<NSString*> *elements = [[NSMutableSet<NSString*> alloc] init];

    if (buttonConfig & GamepadConfiguration_DirectionPad)
    {   [elements addObject:GCInputDirectionPad];
    }

    if (buttonConfig & GamepadConfiguration_LeftThumbstick)
    {   [elements addObject:GCInputLeftThumbstick];
    }

    if (buttonConfig & GamepadConfiguration_RightThumbstick)
    {   [elements addObject:GCInputRightThumbstick];
    }

    if (buttonConfig & GamepadConfiguration_ButtonA)
    {   [elements addObject:GCInputButtonA];
    }

    if (buttonConfig & GamepadConfiguration_ButtonB)
    {   [elements addObject:GCInputButtonB];
    }

    if (buttonConfig & GamepadConfiguration_ButtonX)
    {   [elements addObject:GCInputButtonX];
    }

    if (buttonConfig & GamepadConfiguration_ButtonY)
    {   [elements addObject:GCInputButtonY];
    }

    if (buttonConfig & GamepadConfiguration_LeftShoulder)
    {   [elements addObject:GCInputLeftShoulder];
    }

    if (buttonConfig & GamepadConfiguration_RightShoulder)
    {   [elements addObject:GCInputRightShoulder];
    }

    if (buttonConfig & GamepadConfiguration_LeftTrigger)
    {   [elements addObject:GCInputLeftTrigger];
    }

    if (buttonConfig & GamepadConfiguration_RightTrigger)
    {   [elements addObject:GCInputRightTrigger];
    }

    if (buttonConfig & GamepadConfiguration_LeftThumbstickBtn)
    {   [elements addObject:GCInputLeftThumbstickButton];
    }

    if (buttonConfig & GamepadConfiguration_RightThumbstickBtn)
    {   [elements addObject:GCInputRightThumbstickButton];
    }

    GCVirtualControllerConfiguration *configuration = [[GCVirtualControllerConfiguration alloc] init];
    configuration.elements = elements;

    self.virtualController = [GCVirtualController virtualControllerWithConfiguration:configuration];
    [self.virtualController connectWithReplyHandler:^(NSError * _Nullable error) {
        NSLog(@"setupVirtualController::connectWithReplyHandler: %@", error);
    }];
#endif
}

- (void)createVirtualControllerIfNeeded
{
#if TARGET_IOS
    if (!self.virtualController)
    {
        [self createVirtualController];
    }
#endif
}

#endif // USE_CONTROLLERS

@end

#pragma mark - Helpers

GamepadButtonAction GamepadButtonActionFromPressed(bool pressed)
{
    return pressed ? GAMEPAD_BUTTON_ACTION_PRESSED : GAMEPAD_BUTTON_ACTION_DEPRESSED;
}
