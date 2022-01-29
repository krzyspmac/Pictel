//
//  PlatformViewController.m
//  SampleApp
//
//  Created by krzysp on 09/01/2022.
//

#import "RendererEntryViewController.h"
#include <Metal/Metal.hpp>
#include <MetalKit/MetalKit.h>
#include "defs.h"

using namespace engine;

@implementation RendererEntryViewController

#pragma mark - Lifecycle & Setup

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)loadView
{
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupView];
    [self setupScreenRendingPipeline];
    [self setupOffscreenRenderingPipeline];
    [self setupEngine];
    [self setupConsole];
    [self prepareEngine];

    [self mtkView:mtkView drawableSizeWillChange:mtkView.drawableSize];
}

- (void)viewDidAppear
{
    [self setupEvents];
}

- (void)setupView
{
    mtkView = (MTKView*)self.view;
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;//.bgra8Unorm_srgb
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
    viewportSize.width = INITIAL_SCREEN_WIDTH;
    viewportSize.height = INITIAL_SCREEN_HEIGHT;
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

    m_engineProvider->SetRendererDevice((__bridge MTL::Device*)device);
    m_engineProvider->SetRenderingPipelineState((__bridge MTL::RenderPipelineState*)pipelineState);
    m_engineProvider->SetDesiredViewport(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT);

    desiredFramebufferTextureSize.x = INITIAL_SCREEN_WIDTH;
    desiredFramebufferTextureSize.y = INITIAL_SCREEN_HEIGHT;
    affineScale = 1.0f;
}

- (void)setupConsole
{
    m_consoleRendererProvider = (ConsoleAppRendererMac*)m_consoleRenderer->GetPlarformRenderer();
    m_consoleRendererProvider->SetDevice((__bridge MTL::Device*)device);
#if TARGET_OSX
    m_consoleRendererProvider->SetView(self.view);
#endif
}

- (void)prepareEngine
{
    // Setup the engine
    m_engine->Setup();

    // Reapply initial resolution read from ini file
    auto resolution = m_engine->GetEngineSetup().resolution;
    m_engineProvider->SetDesiredViewport(resolution.width, resolution.height);

    // Recreate the offscreen rendering pipeline
    [self recreateOffscreenRenderingPipeline];

    // Reapply the view size from ini file
    CGRect viewFrame = self.view.frame;
    viewFrame.size = CGSizeMake(resolution.width, resolution.height);
    self.view.frame = viewFrame;
}

- (void)setupScreenRendingPipeline
{
    device = MTLCreateSystemDefaultDevice();

    mtkView.device = device;
    mtkView.delegate = self;

    NSError *libraryError = NULL;
    library = [device newLibraryWithFile:[self libraryPath] error:&libraryError];
    if (!library) {
        NSLog(@"Library error: %@", libraryError.localizedDescription);
    }

    vertexFunction = [library newFunctionWithName:@"presenterVertexShader"];
    fragmentFunction = [library newFunctionWithName:@"presenterFragmentShader"];

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
}

- (void)setupOffscreenRenderingPipeline
{
    if (!oscVertexFunction)
        oscVertexFunction = [library newFunctionWithName:@"vertexShader"];
    if (!oscFragmentFunction)
        oscFragmentFunction = [library newFunctionWithName:@"fragmentShader"];

    framebufferTextureSize.x = m_engine ? m_engine->GetEngineSetup().resolution.width : INITIAL_SCREEN_WIDTH;
    framebufferTextureSize.y = m_engine ? m_engine->GetEngineSetup().resolution.height : INITIAL_SCREEN_HEIGHT;

    MTLTextureDescriptor *texDescriptor = [MTLTextureDescriptor new];
    texDescriptor.textureType = MTLTextureType2D;
    texDescriptor.width = framebufferTextureSize.x;
    texDescriptor.height = framebufferTextureSize.y;
    texDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;//MTLPixelFormatRGBA8Unorm;
    texDescriptor.usage = MTLTextureUsageRenderTarget |
                          MTLTextureUsageShaderRead;

    if (oscTargetTexture)
    {
        oscTargetTexture = nil;
    }

    oscTargetTexture = [device newTextureWithDescriptor:texDescriptor];

    oscRenderPassDescriptor = [MTLRenderPassDescriptor new];
    oscRenderPassDescriptor.colorAttachments[0].texture = oscTargetTexture;
    oscRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;//MTLLoadActionLoad;//MTLLoadActionClear;
    oscRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 1, 1);
    oscRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    MTLRenderPipelineDescriptor *oscRenderePipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    oscRenderePipelineDescriptor.label = @"Offline Render Pipeline";
    oscRenderePipelineDescriptor.sampleCount = 1;
    oscRenderePipelineDescriptor.vertexFunction = oscVertexFunction;
    oscRenderePipelineDescriptor.fragmentFunction = oscFragmentFunction;

    MTLRenderPipelineColorAttachmentDescriptor *colorAttch = oscRenderePipelineDescriptor.colorAttachments[0];
    colorAttch.pixelFormat = oscTargetTexture.pixelFormat;
    colorAttch.blendingEnabled             = YES;
    colorAttch.rgbBlendOperation           = MTLBlendOperationAdd;
    colorAttch.alphaBlendOperation         = MTLBlendOperationAdd;
    colorAttch.sourceRGBBlendFactor        = MTLBlendFactorSourceAlpha;
    colorAttch.sourceAlphaBlendFactor      = MTLBlendFactorSourceAlpha;
    colorAttch.destinationRGBBlendFactor   = MTLBlendFactorOneMinusSourceAlpha;
    colorAttch.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    NSError *error;
    oscPipelineState = [device newRenderPipelineStateWithDescriptor:oscRenderePipelineDescriptor error:&error];
    NSAssert(oscPipelineState, @"Failed to create pipeline state to render to screen: %@", error);
}

- (void)recreateOffscreenRenderingPipeline
{
    [self setupOffscreenRenderingPipeline];
}

@end

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
#else

@interface GameWindowController: NSWindowController
@end

@implementation GameWindowController

- (void)windowWillLoad
{
    [super windowWillLoad];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

@end

#endif
