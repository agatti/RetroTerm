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

#import "SFTPETSCIIConverter.h"

#define ____ SFTUnmappedPETSCIICharacter
#define RSTP SFTPETSCIIControlCodeRunStop
#define BELL SFTPETSCIIControlCodeBell
#define SHDI SFTPETSCIIControlCodeShiftDisable
#define SHEN SFTPETSCIIControlCodeShiftEnable
#define CRTN SFTPETSCIIControlCodeCarriageReturn
#define LNFD SFTPETSCIIControlCodeLineFeed
#define HOME SFTPETSCIIControlCodeHome
#define CLER SFTPETSCIIControlCodeClear
#define INSR SFTPETSCIIControlCodeInsert
#define DELT SFTPETSCIIControlCodeDelete
#define CRUP SFTPETSCIIControlCodeCursorUp
#define CRDN SFTPETSCIIControlCodeCursorDown
#define CRLT SFTPETSCIIControlCodeCursorLeft
#define CRRT SFTPETSCIIControlCodeCursorRight
#define RVON SFTPETSCIIControlCodeReverseOn
#define RVOF SFTPETSCIIControlCodeReverseOff
#define TEXT SFTPETSCIIControlCodeTextMode
#define GRPH SFTPETSCIIControlCodeGraphicsMode
#define CBLK SFTPETSCIIControlCodeColourBlack
#define CWHT SFTPETSCIIControlCodeColourWhite
#define CRED SFTPETSCIIControlCodeColourRed
#define CCYN SFTPETSCIIControlCodeColourCyan
#define CPRP SFTPETSCIIControlCodeColourPurple
#define CGRN SFTPETSCIIControlCodeColourGreen
#define CBLU SFTPETSCIIControlCodeColourBlue
#define CYLW SFTPETSCIIControlCodeColourYellow
#define CORG SFTPETSCIIControlCodeColourOrange
#define CBRN SFTPETSCIIControlCodeColourBrown
#define CLTR SFTPETSCIIControlCodeColourLightRed
#define CDGR SFTPETSCIIControlCodeColourDarkGray
#define CMGR SFTPETSCIIControlCodeColourMiddleGray
#define CLGN SFTPETSCIIControlCodeColourLightGreen
#define CLBL SFTPETSCIIControlCodeColourLightBlue
#define CLGR SFTPETSCIIControlCodeColourLightGray
#define CFK1 SFTPETSCIIControlCodeF1
#define CFK2 SFTPETSCIIControlCodeF2
#define CFK3 SFTPETSCIIControlCodeF3
#define CFK4 SFTPETSCIIControlCodeF4
#define CFK5 SFTPETSCIIControlCodeF5
#define CFK6 SFTPETSCIIControlCodeF6
#define CFK7 SFTPETSCIIControlCodeF7
#define CFK8 SFTPETSCIIControlCodeF8

// clang-format off

static const uint16_t kPETSCIIToFontIndex[256] = {
    // 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F

    ____, ____, ____, RSTP, ____, CWHT, ____, BELL, SHDI, SHEN, ____, ____, ____, CRTN, TEXT, ____, // 0
    ____, CRDN, RVON, HOME, DELT, ____, ____, ____, ____, ____, ____, ____, CRED, CRRT, CGRN, CBLU, // 1
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, // 2
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, // 3
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, // 4
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, // 5
    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, // 6
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, // 7
    ____, CORG, ____, ____, ____, CFK1, CFK3, CFK5, CFK7, CFK2, CFK4, CFK6, CFK8, LNFD, GRPH, ____, // 8
    CBLK, CRUP, RVOF, CLER, INSR, CBRN, CLTR, CDGR, CMGR, CLGN, CLBL, CLGR, CPRP, CRLT, CYLW, CCYN, // 9
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, // A
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x7F, // B
    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, // C
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, // D
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, // E
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x5E  // F
};

// clang-format on

static NSArray<NSString *> *kControlCodeNames = nil;

@interface SFTPETSCIIConverter ()
@end

@implementation SFTPETSCIIConverter

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kControlCodeNames = @[
      @"RUN/STOP",
      @"BELL",
      @"DISABLE C=+SHIFT",
      @"ENABLE C=+SHIFT",
      @"CARRIAGE RETURN",
      @"LINE FEED",
      @"HOME",
      @"CLEAR",
      @"INSERT",
      @"DELETE",
      @"CURSOR UP",
      @"CURSOR DOWN",
      @"CURSOR LEFT",
      @"CURSOR RIGHT",
      @"REVERSE ON",
      @"REVERSE OFF",
      @"TEXT MODE",
      @"GRAPHICS MODE",
      @"COLOUR BLACK",
      @"COLOUR WHITE",
      @"COLOUR RED",
      @"COLOUR CYAN",
      @"COLOUR PURPLE",
      @"COLOUR GREEN",
      @"COLOUR BLUE",
      @"COLOUR YELLOW",
      @"COLOUR ORANGE",
      @"COLOUR BROWN",
      @"COLOUR LIGHT RED",
      @"COLOUR DARK GRAY",
      @"COLOUR MIDDLE GRAY",
      @"COLOUR LIGHT GREEN",
      @"COLOUR LIGHT BLUE",
      @"COLOUR LIGHT GRAY",
      @"FUNCTION KEY F1",
      @"FUNCTION KEY F2",
      @"FUNCTION KEY F3",
      @"FUNCTION KEY F4",
      @"FUNCTION KEY F5",
      @"FUNCTION KEY F6",
      @"FUNCTION KEY F7",
      @"FUNCTION KEY F8"
    ];
  });
}

+ (uint16_t)convertFromEventKeyCodeToPETSCIIControlCode:(unichar)keyCode {
  switch (keyCode) {
  case NSUpArrowFunctionKey:
    return SFTPETSCIIControlCodeCursorUp;

  case NSDownArrowFunctionKey:
    return SFTPETSCIIControlCodeCursorDown;

  case NSLeftArrowFunctionKey:
    return SFTPETSCIIControlCodeCursorLeft;

  case NSRightArrowFunctionKey:
    return SFTPETSCIIControlCodeCursorRight;

  case NSF1FunctionKey:
    return SFTPETSCIIControlCodeF1;

  case NSF2FunctionKey:
    return SFTPETSCIIControlCodeF2;

  case NSF3FunctionKey:
    return SFTPETSCIIControlCodeF3;

  case NSF4FunctionKey:
    return SFTPETSCIIControlCodeF4;

  case NSF5FunctionKey:
    return SFTPETSCIIControlCodeF5;

  case NSF6FunctionKey:
    return SFTPETSCIIControlCodeF6;

  case NSF7FunctionKey:
    return SFTPETSCIIControlCodeF7;

  case NSF8FunctionKey:
    return SFTPETSCIIControlCodeF8;

  case NSInsertFunctionKey:
    return SFTPETSCIIControlCodeInsert;

  case NSDeleteFunctionKey:
    return SFTPETSCIIControlCodeDelete;

  case NSHomeFunctionKey:
    return SFTPETSCIIControlCodeHome;

  case 0x07:
  case 0x7F:
    return SFTPETSCIIControlCodeDelete;

  case 0x0D:
    return SFTPETSCIIControlCodeCarriageReturn;

  default:
    return SFTUnmappedPETSCIICharacter;
  }
}

+ (uint16_t)convertFromEventKeyCodeToPETSCII:(unichar)keyCode
                              usingLowerCase:(BOOL)lowerCase {
  uint16_t mapped =
      [SFTPETSCIIConverter convertFromEventKeyCodeToPETSCIIControlCode:keyCode];
  if (mapped != SFTUnmappedPETSCIICharacter) {
    return mapped;
  }

  if ((keyCode >= 0x20) && (keyCode <= 0x7F)) {
    if (keyCode >= 0x41 && keyCode <= 0x5A) {
      return (lowerCase == NO) ? keyCode : (keyCode + 0x20);
    }

    return keyCode;
  }

  return SFTUnmappedPETSCIICharacter;
}

+ (uint16_t)convertFromPETSCIIToLowerCaseFontIndex:(uint16_t)petscii {
  if (petscii > 0x00FF) {
    return SFTUnmappedPETSCIICharacter;
  }

  return kPETSCIIToFontIndex[petscii];
}

+ (nullable NSString *)nameForPETSCIIControlCode:(uint16_t)code {
  if (code <= SFTPETSCIIControlCodeFirstControlCode) {
    return nil;
  }

  uint16_t index = code - SFTPETSCIIControlCodeRunStop;
  if (index >= kControlCodeNames.count) {
    return nil;
  }

  return kControlCodeNames[index];
}

@end
