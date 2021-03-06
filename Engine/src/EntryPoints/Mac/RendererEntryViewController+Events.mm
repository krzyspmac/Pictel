//
//  RendererEntryViewController+RendererEntryViewController_Helpers.m
//  Engine
//
//  Created by krzysp on 24/01/2022.
//

#import "RendererEntryViewController.h"
#include "common.h"
#include "common_engine_impl.h"

using namespace engine;

@implementation RendererEntryViewController (Events)

#pragma mark - Setup

- (void)setupEvents
{
    if (didSetupEvents) { return; };

    [self setupMouseClickEvents];
    [self setupMouseMovedEvents];
    [self setupKeyEvents];

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
        auto& eventsProvider = GetMainEngine()->getEventProvider();
        switch (event.type)
        {
            case NSEventTypeKeyDown:
            {
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
                NSString *characters = event.charactersIgnoringModifiers;
                for (NSInteger i = 0; i < characters.length; i++)
                {
                    unichar c = [characters characterAtIndex:i];
                    eventsProvider.PushKeyStateChange((unsigned short)c, false);
                }
                break;
            }
            case NSFlagsChanged:
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
        return event;
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
    m_engine->getEventProvider().PushMouseLocation(locationInViewport);

    /** Also handle other events if necessary */
    [self handle:event];
}

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

#endif

@end
