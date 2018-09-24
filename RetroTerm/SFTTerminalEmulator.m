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

@import AppKit;

#import "SFTTerminalEmulator.h"
#import "NSMutableData+Append.h"
#import "SFTCommon.h"
#import "SFTPETSCIIConverter.h"

static const uint8_t kCharacterSpace = 0x20;

static const uint16_t kUnmappedASCIICharacter = 0xFFFF;

static const uint16_t kControlBell = 0x0200;
static const uint16_t kControlBackspace = 0x0201;
static const uint16_t kControlNewLine = 0x0202;
static const uint16_t kControlCarriageReturn = 0x0203;
static const uint16_t kControlIgnore = 0x0208;

#define ____ kUnmappedASCIICharacter
#define CBEL kControlBell
#define CBSP kControlBackspace
#define CNLN kControlNewLine
#define CCRN kControlCarriageReturn
#define CIGN kControlIgnore

// clang-format off

static const uint16_t kASCIILookupLowerCase[256] = {
    // 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
    ____, ____, ____, ____, ____, ____, ____, CBEL, CBSP, ____, CNLN, ____, ____, CCRN, ____, ____, // 0
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, CIGN, ____, ____, ____, ____, // 1
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, // 2
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, // 3
    0x00, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, // 4
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x1B, ____, 0x1D, ____, ____, // 5
    ____, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, // 6
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, ____, ____, ____, ____, ____, // 7
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 8
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 9
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // A
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // B
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // C
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // D
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // E
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // F
};

// clang-format on

typedef NS_ENUM(NSUInteger, SFTTerminalEmulatorProcessResult) {
  SFTTerminalEmulatorProcessResultForceRedraw,
  SFTTerminalEmulatorProcessResultDoNotRedraw,
  SFTTerminalEmulatorProcessResultSwitchToPetscii
};

@interface SFTTerminalEmulator ()

- (SFTTerminalEmulatorProcessResult)
processASCIICharacters:(nonnull NSData *)characters
           withContext:(nonnull SFTTerminalEmulatorContext *)context
          onCellBuffer:(nonnull SFTTerminalEmulatorCell *)cellBuffer
        afterConsuming:(nonnull NSUInteger *)consumed;

- (SFTTerminalEmulatorProcessResult)
processPETSCIICharacters:(nonnull NSData *)characters
             withContext:(nonnull SFTTerminalEmulatorContext *)context
            onCellBuffer:(nonnull SFTTerminalEmulatorCell *)cellBuffer;

@end

@implementation SFTTerminalEmulator

- (void)clearScreenForContext:(nonnull SFTTerminalEmulatorContext *)context
                 onCellBuffer:(nonnull SFTTerminalEmulatorCell *)cellBuffer {

  for (NSUInteger index = 0; index < (context.width * context.height);
       index++) {
    cellBuffer[index] = (SFTTerminalEmulatorCell)SFTTerminalEmulatorCellPack(
        context, kCharacterSpace);
  }

  context.row = 0;
  context.column = 0;
}

- (void)scrollContentsUpForContext:(nonnull SFTTerminalEmulatorContext *)context
                      onCellBuffer:
                          (nonnull SFTTerminalEmulatorCell *)cellBuffer {

  memmove(
      (void *)cellBuffer,
      (void *)cellBuffer + (context.width * sizeof(SFTTerminalEmulatorCell)),
      context.width * (context.height - 1) * sizeof(SFTTerminalEmulatorCell));

  for (NSUInteger index = 0; index < context.width; index++) {
    cellBuffer[(context.width * (context.height - 1)) + index] =
        (SFTTerminalEmulatorCell)SFTTerminalEmulatorCellPack(context,
                                                             kCharacterSpace);
  }
}

- (BOOL)
processIncomingDataForContext:(nonnull SFTTerminalEmulatorContext *)context
                 onCellBuffer:(nonnull SFTTerminalEmulatorCell *)cellBuffer
                      forData:(nonnull NSData *)data {

  NSUInteger consumed = 0;
  SFTTerminalEmulatorProcessResult result =
      context.isInASCIIMode ? [self processASCIICharacters:data
                                               withContext:context
                                              onCellBuffer:cellBuffer
                                            afterConsuming:&consumed]
                            : [self processPETSCIICharacters:data
                                                 withContext:context
                                                onCellBuffer:cellBuffer];

  switch (result) {
  case SFTTerminalEmulatorProcessResultDoNotRedraw:
    return NO;

  case SFTTerminalEmulatorProcessResultForceRedraw:
    return YES;

  case SFTTerminalEmulatorProcessResultSwitchToPetscii: {
    NSData *subData =
        [NSData dataWithBytesNoCopy:(void *)(data.bytes + consumed)
                             length:data.length - consumed
                       freeWhenDone:NO];

    return [self processPETSCIICharacters:subData
                              withContext:context
                             onCellBuffer:cellBuffer] ==
           SFTTerminalEmulatorProcessResultForceRedraw;
  }
  }

  return NO;
}

- (SFTTerminalEmulatorProcessResult)
processASCIICharacters:(nonnull NSData *)characters
           withContext:(nonnull SFTTerminalEmulatorContext *)context
          onCellBuffer:(nonnull SFTTerminalEmulatorCell *)cellBuffer
        afterConsuming:(nonnull NSUInteger *)consumed {

  BOOL shouldRedraw = NO;
  const uint8_t *bytes = (const uint8_t *)characters.bytes;

  for (NSUInteger index = 0; index < characters.length; index++) {

    NSUInteger mapped = kASCIILookupLowerCase[bytes[index]];

    switch (mapped) {
    case kControlBell:
      NSBeep();
      continue;

    case kControlBackspace:
      context.column = context.column > 0 ? context.column - 1 : 0;
      continue;

    case kControlNewLine:
      ++context.row;
      if (context.row >= context.height) {
        [self scrollContentsUpForContext:context onCellBuffer:cellBuffer];
        context.row = context.height - 1;
        shouldRedraw = YES;
      }
      continue;

    case kControlCarriageReturn:
      context.column = 0;
      continue;

    case kControlIgnore:
      continue;

    case kUnmappedASCIICharacter:
      context.isInASCIIMode = NO;
      *consumed = (index > 0) ? index - 1 : 0;
      return SFTTerminalEmulatorProcessResultSwitchToPetscii;

    default: {
      shouldRedraw = YES;
      cellBuffer[(context.width * context.row) + context.column] =
          SFTTerminalEmulatorCellPack(context, (uint8_t)(mapped & 0xFF));
      ++context.column;
      if (context.column >= context.width) {
        context.column = 0;
        ++context.row;
        if (context.row >= context.height) {
          [self scrollContentsUpForContext:context onCellBuffer:cellBuffer];
          context.row = context.height - 1;
        }
      }
    }
    }
  }

  *consumed = characters.length;
  return shouldRedraw ? SFTTerminalEmulatorProcessResultForceRedraw
                      : SFTTerminalEmulatorProcessResultDoNotRedraw;
}

- (SFTTerminalEmulatorProcessResult)
processPETSCIICharacters:(nonnull NSData *)characters
             withContext:(nonnull SFTTerminalEmulatorContext *)context
            onCellBuffer:(nonnull SFTTerminalEmulatorCell *)cellBuffer {
  BOOL shouldRedraw = NO;
  const uint8_t *bytes = (const uint8_t *)characters.bytes;

  for (NSUInteger index = 0; index < characters.length; index++) {
    uint16_t mapped = [SFTPETSCIIConverter
        convertFromPETSCIIToLowerCaseFontIndex:bytes[index]];

    if (mapped > SFTPETSCIIControlCodeFirstControlCode) {
      switch (mapped) {
      case SFTPETSCIIControlCodeBell:
        NSBeep();
        continue;

      case SFTPETSCIIControlCodeCarriageReturn:
      case SFTPETSCIIControlCodeLineFeed:
        context.column = 0;
        ++context.row;
        if (context.row >= context.height) {
          [self scrollContentsUpForContext:context onCellBuffer:cellBuffer];
          context.row = context.height - 1;
          shouldRedraw = YES;
        }
        context.reverseVideo = NO;
        continue;

      case SFTPETSCIIControlCodeHome:
        context.row = 0;
        context.column = 0;
        continue;

      case SFTPETSCIIControlCodeClear:
        [self clearScreenForContext:context onCellBuffer:cellBuffer];
        shouldRedraw = YES;
        continue;

      case SFTPETSCIIControlCodeInsert:
        //
        continue;

      case SFTPETSCIIControlCodeDelete:
        //
        continue;

      case SFTPETSCIIControlCodeCursorDown:
        ++context.row;
        if (context.row >= context.height) {
          [self scrollContentsUpForContext:context onCellBuffer:cellBuffer];
          context.row = context.height - 1;
          shouldRedraw = YES;
        }
        context.reverseVideo = NO;
        continue;

      case SFTPETSCIIControlCodeCursorUp:
        if (context.row > 0) {
          --context.row;
        }
        continue;

      case SFTPETSCIIControlCodeCursorLeft:
        if (context.column > 0) {
          --context.column;
        }
        continue;

      case SFTPETSCIIControlCodeCursorRight:
        ++context.column;
        if (context.column >= context.width) {
          context.column = 0;
          if (context.row >= context.height) {
            [self scrollContentsUpForContext:context onCellBuffer:cellBuffer];
            context.row = context.height - 1;
            shouldRedraw = YES;
          }
        }
        context.reverseVideo = NO;
        continue;

      case SFTPETSCIIControlCodeReverseOn:
        context.reverseVideo = YES;
        continue;

      case SFTPETSCIIControlCodeReverseOff:
        context.reverseVideo = NO;
        continue;

      case SFTPETSCIIControlCodeTextMode:
        context.useLowerCase = YES;
        continue;

      case SFTPETSCIIControlCodeGraphicsMode:
        context.useLowerCase = NO;
        continue;

      case SFTPETSCIIControlCodeColourBlack:
      case SFTPETSCIIControlCodeColourWhite:
      case SFTPETSCIIControlCodeColourRed:
      case SFTPETSCIIControlCodeColourCyan:
      case SFTPETSCIIControlCodeColourPurple:
      case SFTPETSCIIControlCodeColourGreen:
      case SFTPETSCIIControlCodeColourBlue:
      case SFTPETSCIIControlCodeColourYellow:
      case SFTPETSCIIControlCodeColourOrange:
      case SFTPETSCIIControlCodeColourBrown:
      case SFTPETSCIIControlCodeColourLightRed:
      case SFTPETSCIIControlCodeColourDarkGray:
      case SFTPETSCIIControlCodeColourMiddleGray:
      case SFTPETSCIIControlCodeColourLightGreen:
      case SFTPETSCIIControlCodeColourLightBlue:
      case SFTPETSCIIControlCodeColourLightGray:
        context.foreground = mapped - SFTPETSCIIControlCodeColourBlack;
        continue;
      }
    } else {
      shouldRedraw = YES;
      cellBuffer[(context.width * context.row) + context.column] =
          (SFTTerminalEmulatorCell)SFTTerminalEmulatorCellPack(
              context, (uint8_t)(mapped & 0xFF));
      ++context.column;
      if (context.column >= context.width) {
        context.column = 0;
        ++context.row;
        if (context.row >= context.height) {
          [self scrollContentsUpForContext:context onCellBuffer:cellBuffer];
          context.row = context.height - 1;
          context.reverseVideo = NO;
        }
      }
    }
  }

  return shouldRedraw ? SFTTerminalEmulatorProcessResultForceRedraw
                      : SFTTerminalEmulatorProcessResultDoNotRedraw;
}

- (BOOL)convertKeyCodeForContext:(nonnull SFTTerminalEmulatorContext *)context
                     withKeyCode:(unichar)keyCode
                    toCharacters:(nonnull NSMutableData *)characters {

  NSLog(@"Converting using lower case ---> %@", @(context.useLowerCase));

  uint8_t petscii;
  uint16_t mapped = [SFTPETSCIIConverter
      convertFromEventKeyCodeToPETSCII:keyCode
                        usingLowerCase:context.useLowerCase];
  switch (mapped) {
  case SFTPETSCIIControlCodeCursorUp:
    petscii = 145;
    break;

  case SFTPETSCIIControlCodeCursorDown:
    petscii = 17;
    break;

  case SFTPETSCIIControlCodeCursorLeft:
    petscii = 157;
    break;

  case SFTPETSCIIControlCodeCursorRight:
    petscii = 29;
    break;

  case SFTPETSCIIControlCodeF1:
    petscii = 133;
    break;

  case SFTPETSCIIControlCodeF2:
    petscii = 137;
    break;

  case SFTPETSCIIControlCodeF3:
    petscii = 134;
    break;

  case SFTPETSCIIControlCodeF4:
    petscii = 138;
    break;

  case SFTPETSCIIControlCodeF5:
    petscii = 135;
    break;

  case SFTPETSCIIControlCodeF6:
    petscii = 139;
    break;

  case SFTPETSCIIControlCodeF7:
    petscii = 136;
    break;

  case SFTPETSCIIControlCodeF8:
    petscii = 140;
    break;

  case SFTPETSCIIControlCodeInsert:
    petscii = 148;
    break;

  case SFTPETSCIIControlCodeDelete:
    petscii = 20;
    break;

  case SFTPETSCIIControlCodeHome:
    petscii = 19;
    break;

  case SFTPETSCIIControlCodeCarriageReturn:
    petscii = 13;
    break;

  default:
    if ((mapped >= 0x20) && (mapped <= 0x7F)) {
      petscii = (uint8_t)(mapped & 0xFF);
    } else {
      return NO;
    }
  }

  [characters appendByte:(uint8_t)(petscii & 0xFF)];
  return YES;
}

@end
