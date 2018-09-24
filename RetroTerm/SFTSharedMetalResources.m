/*
 * Copyright 2017-2018 Alessandro Gatti - frob.it
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "SFTSharedMetalResources.h"
#import "SFTCommon.h"

#define VERTEX_COUNT_PER_QUAD (3 * 2)

const NSUInteger SFTVertexBufferQuadItemsCount = VERTEX_COUNT_PER_QUAD;

typedef struct {
  simd_float4 position;
  simd_float2 texture;
} SFTVertex;

// clang-format off

static const SFTVertex kDisplayQuad[VERTEX_COUNT_PER_QUAD * 3] = {
    {{ 1.0, -1.0,  0.0,  1.0}, {1.0, 0.0}},
    {{-1.0, -1.0,  0.0,  1.0}, {0.0, 0.0}},
    {{-1.0,  1.0,  0.0,  1.0}, {0.0, 1.0}},

    {{ 1.0,  1.0,  0.0,  1.0}, {1.0, 1.0}},
    {{ 1.0, -1.0,  0.0,  1.0}, {1.0, 0.0}},
    {{-1.0,  1.0,  0.0,  1.0}, {0.0, 1.0}}};

// clang-format on

@implementation SFTSharedMetalResources

- (nonnull instancetype)init {
  self = [super init];
  if (self != nil) {
    _device = MTLCreateSystemDefaultDevice();
    if (_device == nil) {
      @throw
          [NSException exceptionWithName:SFTMetalException
                                  reason:@"Cannot create system default device"
                                userInfo:nil];
    }

    NSError *error;

    MTKTextureLoader *textureLoader =
        [[MTKTextureLoader alloc] initWithDevice:_device];
    _charsetTexture =
        [textureLoader newTextureWithName:@"CharsetTexture"
                              scaleFactor:1.0
                                   bundle:NSBundle.mainBundle
                                  options:@{
                                    MTKTextureLoaderOptionAllocateMipmaps : @NO,
                                    MTKTextureLoaderOptionOrigin :
                                        MTKTextureLoaderOriginBottomLeft,
                                    MTKTextureLoaderOptionTextureStorageMode :
                                        @(MTLStorageModePrivate),
                                    MTKTextureLoaderOptionTextureUsage :
                                        @(MTLTextureUsageShaderRead)
                                  }
                                    error:&error];

    if (error != nil) {
      @throw [NSException exceptionWithName:SFTMetalException
                                     reason:error.localizedFailureReason
                                   userInfo:nil];
    }

    id<MTLLibrary> library = [_device newDefaultLibrary];

    _terminalVertexFunction = [library newFunctionWithName:@"vertex_terminal"];
    _terminalFragmentFunction =
        [library newFunctionWithName:@"fragment_terminal"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor =
        [MTLRenderPipelineDescriptor new];
    pipelineStateDescriptor.vertexFunction = _terminalVertexFunction;
    pipelineStateDescriptor.fragmentFunction = _terminalFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat =
        MTLPixelFormatBGRA8Unorm;

    _renderPipelineState =
        [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                error:&error];
    if (error != nil) {
      @throw [NSException exceptionWithName:SFTMetalException
                                     reason:error.localizedFailureReason
                                   userInfo:nil];
    }

    _vertexBufferQuad =
        [_device newBufferWithBytes:(void *)&kDisplayQuad[0]
                             length:sizeof(kDisplayQuad)
                            options:MTLResourceStorageModeShared];
  }

  return self;
}

+ (nonnull instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static SFTSharedMetalResources *container;
  dispatch_once(&onceToken, ^{
    container = [SFTSharedMetalResources new];
  });

  return container;
}

@end
