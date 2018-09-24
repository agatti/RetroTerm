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

#import "SFTSharedResources.h"

typedef struct {
  float red;
  float green;
  float blue;
  float alpha;
} SFTColour;

#define PALETTE_COLOURS_COUNT 16

static const NSUInteger kColoursCount = PALETTE_COLOURS_COUNT;

// clang-format off

static const SFTColour kPalette[PALETTE_COLOURS_COUNT] = {
    {0.000000f, 0.000000f, 0.000000f, 1.000000f},
    {1.000000f, 1.000000f, 1.000000f, 1.000000f},
    {0.533333f, 0.000000f, 0.000000f, 1.000000f},
    {0.666667f, 1.000000f, 0.933333f, 1.000000f},
    {0.800000f, 0.266667f, 0.800000f, 1.000000f},
    {0.000000f, 0.800000f, 0.333333f, 1.000000f},
    {0.000000f, 0.000000f, 0.666667f, 1.000000f},
    {0.933333f, 0.933333f, 0.466667f, 1.000000f},
    {0.866667f, 0.533333f, 0.333333f, 1.000000f},
    {0.400000f, 0.266667f, 0.000000f, 1.000000f},
    {1.000000f, 0.466667f, 0.466667f, 1.000000f},
    {0.200000f, 0.200000f, 0.200000f, 1.000000f},
    {0.466667f, 0.466667f, 0.466667f, 1.000000f},
    {0.666667f, 1.000000f, 0.400000f, 1.000000f},
    {0.000000f, 0.533333f, 1.000000f, 1.000000f},
    {0.733333f, 0.733333f, 0.733333f, 1.000000f}
};

// clang-format on

@implementation SFTSharedResources

- (instancetype)init {
  self = [super init];
  if (self != nil) {

    NSMutableArray<NSColor *> *palette =
        [NSMutableArray<NSColor *> arrayWithCapacity:kColoursCount];
    const SFTColour *colour;
    for (NSUInteger index = 0; index < kColoursCount; index++) {
      colour = &kPalette[index];
      [palette addObject:[NSColor colorWithRed:colour->red
                                         green:colour->green
                                          blue:colour->blue
                                         alpha:colour->alpha]];
    }

    _paletteColours = palette;

    _terminalEmulator = [SFTTerminalEmulator new];
  }

  return self;
}

+ (nonnull instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static SFTSharedResources *container;
  dispatch_once(&onceToken, ^{
    container = [SFTSharedResources new];
  });

  return container;
}

@end
