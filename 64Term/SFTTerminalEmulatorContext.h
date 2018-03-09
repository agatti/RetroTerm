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

@import Foundation;

#import "SFTCommon.h"

typedef uint32_t SFTTerminalEmulatorCell;

#define SFTTerminalEmulatorCellPack(context, character)                        \
  (SFTTerminalEmulatorCell)(((character)&0xFF) +                               \
                            ((((context).foreground) & 0x0F) << 8) +           \
                            ((((context).background) & 0x0F) << 12) +          \
                            ((((context).reverseVideo) & 0x01) << 16))
#define SFTTerminalEmulatorCellGetCharacter(cell) ((uint8_t)(cell & 0xFF))
#define SFTTerminalEmulatorCellGetForeground(cell)                             \
  ((uint8_t)((cell >> 8) & 0x0F))
#define SFTTerminalEmulatorCellGetBackground(cell)                             \
  ((uint8_t)((cell >> 12) & 0x0F))
#define SFTTerminalEmulatorCellGetReverse(cell) ((BOOL)((cell >> 16) & 0xF1))

@interface SFTTerminalEmulatorContext : NSObject

/**
 * Screen content width, in cells.
 */
@property(assign, nonatomic, readonly) NSUInteger width;

/**
 * Screen content height, in cells.
 */
@property(assign, nonatomic, readonly) NSUInteger height;

@property(assign, nonatomic) SFTC64Colour background;
@property(assign, nonatomic) SFTC64Colour foreground;

@property(assign, nonatomic) NSUInteger row;
@property(assign, nonatomic) NSUInteger column;

@property(assign, nonatomic) BOOL isInASCIIMode;
@property(assign, nonatomic) BOOL useLowerCase;
@property(assign, nonatomic) BOOL reverseVideo;

/**
 *
 * @param[in] width screen width, in cell.
 * @param[in] height screen height, in cell.
 * @param[in] background currently chosen background colour.
 * @param[in] foreground currently chosen foreground colour.
 * @param[in] asciiMode flag indicating whether to start in ASCII or PETSCII
 * mode.
 * @param[in] lowerCase flag indicating whether to start using upper or lower
 * case characters for PETSCII.
 */
- (nonnull instancetype)initWithWidth:(NSUInteger)width
                            andHeight:(NSUInteger)height
                      usingBackground:(SFTC64Colour)background
                        andForeground:(SFTC64Colour)foreground
                          inASCIIMode:(BOOL)asciiMode
                       usingLowerCase:(BOOL)lowerCase;

@end
