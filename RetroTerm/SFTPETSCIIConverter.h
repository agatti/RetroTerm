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

typedef NS_ENUM(uint16_t, SFTPETSCIIControlCode) {
  SFTPETSCIIControlCodeFirstControlCode = 0x0100,
  SFTPETSCIIControlCodeRunStop,
  SFTPETSCIIControlCodeBell,
  SFTPETSCIIControlCodeShiftDisable,
  SFTPETSCIIControlCodeShiftEnable,
  SFTPETSCIIControlCodeCarriageReturn,
  SFTPETSCIIControlCodeLineFeed,
  SFTPETSCIIControlCodeHome,
  SFTPETSCIIControlCodeClear,
  SFTPETSCIIControlCodeInsert,
  SFTPETSCIIControlCodeDelete,
  SFTPETSCIIControlCodeCursorUp,
  SFTPETSCIIControlCodeCursorDown,
  SFTPETSCIIControlCodeCursorLeft,
  SFTPETSCIIControlCodeCursorRight,
  SFTPETSCIIControlCodeReverseOn,
  SFTPETSCIIControlCodeReverseOff,
  SFTPETSCIIControlCodeTextMode,
  SFTPETSCIIControlCodeGraphicsMode,
  SFTPETSCIIControlCodeColourBlack,
  SFTPETSCIIControlCodeColourWhite,
  SFTPETSCIIControlCodeColourRed,
  SFTPETSCIIControlCodeColourCyan,
  SFTPETSCIIControlCodeColourPurple,
  SFTPETSCIIControlCodeColourGreen,
  SFTPETSCIIControlCodeColourBlue,
  SFTPETSCIIControlCodeColourYellow,
  SFTPETSCIIControlCodeColourOrange,
  SFTPETSCIIControlCodeColourBrown,
  SFTPETSCIIControlCodeColourLightRed,
  SFTPETSCIIControlCodeColourDarkGray,
  SFTPETSCIIControlCodeColourMiddleGray,
  SFTPETSCIIControlCodeColourLightGreen,
  SFTPETSCIIControlCodeColourLightBlue,
  SFTPETSCIIControlCodeColourLightGray,
  SFTPETSCIIControlCodeF1,
  SFTPETSCIIControlCodeF2,
  SFTPETSCIIControlCodeF3,
  SFTPETSCIIControlCodeF4,
  SFTPETSCIIControlCodeF5,
  SFTPETSCIIControlCodeF6,
  SFTPETSCIIControlCodeF7,
  SFTPETSCIIControlCodeF8,
  SFTUnmappedPETSCIICharacter = 0xFFFF
};

@interface SFTPETSCIIConverter : NSObject

+ (uint16_t)convertFromEventKeyCodeToPETSCIIControlCode:(unichar)keyCode;

+ (uint16_t)convertFromEventKeyCodeToPETSCII:(unichar)keyCode
                              usingLowerCase:(BOOL)upperCase;

+ (uint16_t)convertFromPETSCIIToLowerCaseFontIndex:(uint16_t)petscii;

+ (nullable NSString *)nameForPETSCIIControlCode:(uint16_t)code;

@end
