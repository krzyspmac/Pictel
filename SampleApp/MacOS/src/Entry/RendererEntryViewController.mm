//
//  PlatformViewController.m
//  SampleApp
//
//  Created by krzysp on 09/01/2022.
//

#import "RendererEntryViewController.h"
#include "AAPLShaderTypes.h"

//#define NS_PRIVATE_IMPLEMENTATION
//#define CA_PRIVATE_IMPLEMENTATION
//#define MTL_PRIVATE_IMPLEMENTATION
#include <Metal/Metal.hpp>
#include <MetalKit/MetalKit.h>

#include "file_access.hpp"
#include "scripting_engine.hpp"
#include "event_provider.hpp"
#include "engine.hpp"
#include "common_engine_impl.h"

#define SCREEN_WIDTH  1280
#define SCREEN_HEIGHT 720
#define ASPECT_RATIO (640/480)

using namespace engine;

@implementation RendererEntryViewController
{
    /** Metal related */
    id<MTLDevice> device;
    id<MTLLibrary> library;
    id<MTLFunction> vertexFunction;
    id<MTLFunction> fragmentFunction;
    MTLRenderPipelineDescriptor *renderePipelineDescriptor;
    id<MTLRenderPipelineState> pipelineState;
    id<MTLCommandQueue> commandQueue;
    vector_float2 viewportSize;
    MTKView *mtkView;

    /** Engine Related */
    engine::FileAccessI *m_fileAccess;
    engine::TextureManager *m_textureManager;
    engine::EngineProviderMetal *m_engineProvider;
    engine::FontManager *m_fontManager;
    engine::ScriptingEngineI *m_scriptingEngine;
    engine::EventProviderI *m_eventProvider;
    engine::EventsManager *m_eventsManager;
    engine::CharacterManager *m_characterManager;
    engine::SceneManager *m_sceneManager;
    engine::SpriteAtlasManager *m_spriteAtlasManager;
    engine::SpriteRendererManager *m_sprireRendererManager;
    engine::ConsoleRenderer *m_consoleRenderer;
    engine::Engine *m_engine;
}

- (void)setupEngine
{
    FileAccess *fa = new FileAccess();
    TextureManager *tm = new TextureManager();
    EngineProviderMetal *ep = new EngineProviderMetal();
    FontManager *fm  = new FontManager();
    ScriptingEngine *se = new ScriptingEngine();
    EventProvider *eventProvider = new EventProvider();
    EventsManager *eventsManager = new EventsManager(*eventProvider, *ep);
    CharacterManager *characteManager = new CharacterManager();
    SceneManager *sceneManager = new SceneManager();
    SpriteAtlasManager * spriteAtlasManager = new SpriteAtlasManager();
    SpriteRendererManager *sprireRendererManager = new SpriteRendererManager();
    ConsoleRenderer *consoleRenderer = new ConsoleRenderer();

    m_fileAccess = fa;
    m_textureManager = tm;
    m_engineProvider = ep;
    m_fontManager = fm;
    m_scriptingEngine = se;
    m_eventProvider = eventProvider;
    m_eventsManager = eventsManager;
    m_characterManager = characteManager;
    m_sceneManager = sceneManager;
    m_spriteAtlasManager = spriteAtlasManager;
    m_sprireRendererManager = sprireRendererManager;
    m_consoleRenderer = consoleRenderer;

    engine::Size viewportSize;
    viewportSize.width = SCREEN_WIDTH;
    viewportSize.height = SCREEN_HEIGHT;
    m_engine = new Engine(
                            *m_engineProvider
                          , *m_textureManager
                          , *m_fileAccess
                          , *m_fontManager
                          , *m_scriptingEngine
                          , *m_eventProvider
                          , *m_eventsManager
                          , *m_characterManager
                          , *m_sceneManager
                          , *m_spriteAtlasManager
                          , *m_sprireRendererManager
                          , *m_consoleRenderer
                          , viewportSize
                          );

}

- (void)prepareEngine
{
    m_engine->Setup();
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
//    NSWindow * window = NSApplication.sharedApplication.windows[0];
//    [window setFrame:CGRectMake(0, 0, 1280, 720) display:YES];

    [self setupEngine];
    [self setupRenderingPipeline];
    [self prepareEngine];

    [self mtkView:mtkView drawableSizeWillChange:mtkView.drawableSize];
}

- (void)setupRenderingPipeline
{
    device = MTLCreateSystemDefaultDevice();

    mtkView = (MTKView*)self.view;
    mtkView.device = device;
    mtkView.delegate = self;

    library = [device newDefaultLibrary];
    vertexFunction = [library newFunctionWithName:@"vertexShader"];
    fragmentFunction = [library newFunctionWithName:@"fragmentShader"];

    renderePipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    [renderePipelineDescriptor setLabel:@"Simple Pipeline"];
    [renderePipelineDescriptor setVertexFunction:vertexFunction];
    [renderePipelineDescriptor setFragmentFunction:fragmentFunction];

    MTLRenderPipelineColorAttachmentDescriptor *renderbufferAttachment = renderePipelineDescriptor.colorAttachments[0];
    [renderbufferAttachment setPixelFormat:mtkView.colorPixelFormat];
    [renderbufferAttachment setBlendingEnabled:YES];
    [renderbufferAttachment setRgbBlendOperation:MTLBlendOperationAdd];
    [renderbufferAttachment setAlphaBlendOperation:MTLBlendOperationAdd];
    [renderbufferAttachment setSourceRGBBlendFactor:MTLBlendFactorSourceAlpha];
    [renderbufferAttachment setSourceAlphaBlendFactor:MTLBlendFactorSourceAlpha];
    [renderbufferAttachment setDestinationRGBBlendFactor:MTLBlendFactorOneMinusSourceAlpha];
    [renderbufferAttachment setDestinationAlphaBlendFactor:MTLBlendFactorOneMinusSourceAlpha];

    NSError *error;
    pipelineState = [device newRenderPipelineStateWithDescriptor:renderePipelineDescriptor
                                                           error:&error];
    if (!pipelineState)
    {
        NSLog(@"Failed to create pipeline state: %@.", error);
        // TODO: error handling
    }

    commandQueue = [device newCommandQueue];

    m_engineProvider->SetRendererDevice((__bridge MTL::Device*)device);
    m_engineProvider->SetDesiredViewport(SCREEN_WIDTH, SCREEN_HEIGHT);
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    viewportSize.x = size.width;
    viewportSize.y = size.height;
    NSLog(@"New size = %@\n", NSStringFromSize(size));
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    /** Create a command buffer*/
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    /** Encoder goes directly to the C++ engine*/
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:mtkView.currentRenderPassDescriptor];
    [encoder setRenderPipelineState:pipelineState];

    /** Pass in the C++ bridge to the MTLRendererCommandEncoder */
    m_engineProvider->SetRendererCommandEncoder((__bridge MTL::RenderCommandEncoder*)encoder);
    m_engineProvider->SetViewportSize(viewportSize);

    m_engine->FrameBegin();
    m_engine->FrameDraw();

    /** End encoding */
    [encoder endEncoding];

    /** Present the drawable */
    [commandBuffer presentDrawable:view.currentDrawable];

    /** Flush the queue */
    [commandBuffer commit];
};

@end