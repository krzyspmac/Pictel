//
//  RendererEntryViewController+RendererEntryViewController_Helpers.m
//  Engine
//
//  Created by krzysp on 24/01/2022.
//

#import "RendererEntryViewController.h"
#import "engine.hpp"
#include "defs.h"

@implementation RendererEntryViewController (Rendering)

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    density = [self density];

    viewportSize.x = size.width;
    viewportSize.y = size.height;
    printf("size = %f, %f\n", size.width, size.height);

    [self setupMouseMovedEvents];

    if (density > 0)
    {
        GetMainEngine()->getEngineState().SendScreenSizeChangeEvent(
            { static_cast<int>(size.width), static_cast<int>(size.height) }
          , density
        );
    }
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    /** The main engine */
    auto engine = GetMainEngine();

    /** Engine state */
    auto& engineSetup = engine->GetEngineSetup();

    /** The main engine provider */
    auto& provider = engine->getProvider();

    /** Update the engine if needed*/
    m_engine->SetViewportScale(density);

    /** Recreate the offscreen texture if needed */
    desiredFramebufferTextureSize.x = engineSetup.resolution.width;
    desiredFramebufferTextureSize.y = engineSetup.resolution.height;

    if ( engineSetup.isDirty )
    {
        [self recreateOffscreenRenderingPipeline];
        provider.SetDesiredViewport(desiredFramebufferTextureSize.x, desiredFramebufferTextureSize.y);
        affineScale = engineSetup.affineScale;
        engineSetup.isDirty = false;
    }

    /** Process events */
    m_engine->ProcessEvents();

    /** Process script. Script can alter the current rendering queue */
    m_engine->ProcessScript();

    /** Create a command buffer*/
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"Command Buffer";

    /** Render the scene offscreen to a target texture */
    {
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:oscRenderPassDescriptor];
        [encoder setRenderPipelineState:oscPipelineState];
        [encoder setDepthStencilState:oscDepthStencilTest];

        /** Pass in the C++ bridge to the MTLRendererCommandEncoder */
        m_engineProvider->SetRendererCommandEncoder((__bridge MTL::RenderCommandEncoder*)encoder);
        m_engineProvider->SetViewportSize(desiredFramebufferTextureSize);

        /** Render the scene */
        m_engine->FrameBegin();
        m_engine->FrameDrawBackgroundObjects();
        m_engine->FrameDrawForegroundObjects();
        m_engine->FrameDrawTopObjects();

        [encoder endEncoding];
    }

    /** Render the offscreen texture to screen */
    MTLRenderPassDescriptor *drawableRenderPassDescriptor = view.currentRenderPassDescriptor;
    if(drawableRenderPassDescriptor != nil)
    {
        /** Create the encoder for the pass */
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:drawableRenderPassDescriptor];
        encoder.label = @"Drawable Render Pass";
        [encoder setRenderPipelineState:pipelineState];

        static const AAPLVertex quadVertices[] =
        {
            // Positions     , Texture coordinates
            { {  1,  -1 },  { 1.0, 1.0 } },
            { { -1,  -1 },  { 0.0, 1.0 } },
            { { -1,   1 },  { 0.0, 0.0 } },

            { {  1,  -1 },  { 1.0, 1.0 } },
            { { -1,   1 },  { 0.0, 0.0 } },
            { {  1,   1 },  { 1.0, 0.0 } },
        };

        // Draw the offscreen texture
        [encoder setVertexBytes:&quadVertices length:sizeof(quadVertices) atIndex:AAPLVertexInputIndexVertices];
        [encoder setVertexBytes:&viewportSize length:sizeof(viewportSize) atIndex:AAPLVertexInputIndexWindowSize];
        [encoder setVertexBytes:&desiredFramebufferTextureSize length:sizeof(desiredFramebufferTextureSize) atIndex:AAPLVertexInputIndexViewportSize];
        [encoder setVertexBytes:&affineScale length:sizeof(affineScale) atIndex:AAPLVertexInputIndexObjectScale];
        [encoder setFragmentTexture:oscTargetTexture atIndex:FragmentShaderIndexBaseColor];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        // Optionally draw the console
#if TARGET_OSX
#if SHOW_CONSOLE
        if (!m_consoleRenderer->GetConsoleHidden())
        {
            [encoder pushDebugGroup:@"Dear ImGui rendering"];

            m_consoleRendererProvider->PrepareForFrame(
               self.view
             , (__bridge MTL::RenderPassDescriptor*)drawableRenderPassDescriptor
             , (__bridge MTL::CommandBuffer*)commandBuffer
             , (__bridge MTL::RenderCommandEncoder*)encoder
            );
            m_consoleRenderer->DoFrame();
            m_consoleRendererProvider->Render();

            [encoder popDebugGroup];
        }
#endif
#endif
        /** End encoding */
        [encoder endEncoding];
    }

    /** Present the drawable */
    [commandBuffer presentDrawable:view.currentDrawable];

    /** Flush the queue */
    [commandBuffer commit];
};

- (float)density
{
#if TARGET_IOS
    return [UIScreen mainScreen].scale;
#else
    return self.parentWindow.backingScaleFactor;
#endif

}

@end
