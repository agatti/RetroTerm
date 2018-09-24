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

#import "SFTKeyConverter.h"

static const uint16_t kUnmappedKey = 0xFFFF;

static const uint16_t kControlBell = 0x0200;
static const uint16_t kControlBackspace = 0x0201;
static const uint16_t kControlNewLine = 0x0202;
static const uint16_t kControlCarriageReturn = 0x0203;
static const uint16_t kControlIgnore = 0x0208;

static const uint8_t kPETSCIIMovementUpKey = 145;
static const uint8_t kPETSCIIMovementDownKey = 17;
static const uint8_t kPETSCIIMovementLeftKey = 147;
static const uint8_t kPETSCIIMovementRightKey = 29;

#define ____ kUnmappedKey
#define CBEL kControlBell
#define CBSP kControlBackspace
#define CNLN kControlNewLine
#define CCRN kControlCarriageReturn
#define CIGN kControlIgnore

// clang-format off

static const uint16_t kPETSCIIKeyCodeToASCII[256] = {
    // 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
    0x40, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, // 0
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x5B, ____, 0x5D, ____, ____, // 1
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, // 2
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, // 3
    ____, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, // 4
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, ____, ____, ____, ____, ____, // 5
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 6
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 7
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 8
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 9
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // A
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // B
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // C
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // D
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // E
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____  // F
};

// @TODO: Merge with kASCIILookupLowerCase?
static const uint16_t kKeycodeToPETSCIILookup[256] = {
    // 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, 0x0D, ____, ____, // 0
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 1
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, // 2
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, // 3
    0x40, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, // 4
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, ____, 0x1D, ____, ____, // 5
    ____, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, // 6
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, ____, ____, ____, ____, 0x14, // 7
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 8
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // 9
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // A
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // B
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // C
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // D
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, // E
    ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____  // F
};

// clang-format on

#undef ____
#undef CBEL
#undef CBSP
#undef CNLN
#undef CCRN
#undef CIGN

const NSUInteger SFTUnmappedKey = NSUIntegerMax;

@implementation SFTKeyInformation

- (nonnull instancetype)init {
  self = [super init];
  if (self != nil) {
    _cocoaKeyName = nil;
    _asciiKeyName = nil;
    _petsciiKeyName = nil;
    _cocoaKeyCode = SFTUnmappedKey;
    _asciiKeyCode = SFTUnmappedKey;
    _petsciiKeyCode = SFTUnmappedKey;
    _isControlPressed = NO;
    _isOptionPressed = NO;
    _isCommandPressed = NO;
    _isShiftPressed = NO;
  }

  return self;
}

@end

@implementation SFTKeyConverter

+ (nonnull SFTKeyInformation *)convertFromKeyEvent:(nonnull NSEvent *)event {
  SFTKeyInformation *key = [SFTKeyInformation new];

  key.isCommandPressed =
      (event.modifierFlags & NSEventModifierFlagCommand) != 0;
  key.isControlPressed =
      (event.modifierFlags & NSEventModifierFlagControl) != 0;
  key.isOptionPressed = (event.modifierFlags & NSEventModifierFlagOption) != 0;
  key.isShiftPressed = (event.modifierFlags & NSEventModifierFlagShift) != 0;

  if (event.charactersIgnoringModifiers.length > 0) {
    unichar character = [event.charactersIgnoringModifiers characterAtIndex:0];

    key.cocoaKeyName = [SFTKeyConverter keyCodeToCocoaKeyName:character];
    if (key.cocoaKeyName != nil) {
      key.cocoaKeyCode = character;
    }

    key.asciiKeyName = [SFTKeyConverter keyCodeToASCIIKeyName:character];
    if (key.asciiKeyName != nil) {
      key.asciiKeyCode = character;
    }

    key.petsciiKeyCode = [SFTKeyConverter keyCodeToPETSCIIKeyCode:character];
    if (key.petsciiKeyCode != SFTUnmappedKey) {
      key.petsciiKeyName =
          [SFTKeyConverter petsciiKeyCodeToPETSCIIKeyName:key.petsciiKeyCode];
      NSAssert(key.petsciiKeyName != nil, @"Cannot get PETSCII Key name?");
    }
  }

  return key;
}

+ (nullable NSString *)keyCodeToCocoaKeyName:(unichar)keyCode {
  switch (keyCode) {
  case NSUpArrowFunctionKey:
    return @"NSUpArrowFunctionKey";

  case NSDownArrowFunctionKey:
    return @"NSDownArrowFunctionKey";

  case NSLeftArrowFunctionKey:
    return @"NSLeftArrowFunctionKey";

  case NSRightArrowFunctionKey:
    return @"NSRightArrowFunctionKey";

  case NSF1FunctionKey:
    return @"NSF1FunctionKey";

  case NSF2FunctionKey:
    return @"NSF2FunctionKey";

  case NSF3FunctionKey:
    return @"NSF3FunctionKey";

  case NSF4FunctionKey:
    return @"NSF4FunctionKey";

  case NSF5FunctionKey:
    return @"NSF5FunctionKey";

  case NSF6FunctionKey:
    return @"NSF6FunctionKey";

  case NSF7FunctionKey:
    return @"NSF7FunctionKey";

  case NSF8FunctionKey:
    return @"NSF8FunctionKey";

  case NSF9FunctionKey:
    return @"NSF9FunctionKey";

  case NSF10FunctionKey:
    return @"NSF10FunctionKey";

  case NSF11FunctionKey:
    return @"NSF11FunctionKey";

  case NSF12FunctionKey:
    return @"NSF12FunctionKey";

  case NSF13FunctionKey:
    return @"NSF13FunctionKey";

  case NSF14FunctionKey:
    return @"NSF14FunctionKey";

  case NSF15FunctionKey:
    return @"NSF15FunctionKey";

  case NSF16FunctionKey:
    return @"NSF16FunctionKey";

  case NSF17FunctionKey:
    return @"NSF17FunctionKey";

  case NSF18FunctionKey:
    return @"NSF18FunctionKey";

  case NSF19FunctionKey:
    return @"NSF19FunctionKey";

  case NSF20FunctionKey:
    return @"NSF20FunctionKey";

  case NSF21FunctionKey:
    return @"NSF21FunctionKey";

  case NSF22FunctionKey:
    return @"NSF22FunctionKey";

  case NSF23FunctionKey:
    return @"NSF23FunctionKey";

  case NSF24FunctionKey:
    return @"NSF24FunctionKey";

  case NSF25FunctionKey:
    return @"NSF25FunctionKey";

  case NSF26FunctionKey:
    return @"NSF26FunctionKey";

  case NSF27FunctionKey:
    return @"NSF27FunctionKey";

  case NSF28FunctionKey:
    return @"NSF28FunctionKey";

  case NSF29FunctionKey:
    return @"NSF29FunctionKey";

  case NSF30FunctionKey:
    return @"NSF30FunctionKey";

  case NSF31FunctionKey:
    return @"NSF31FunctionKey";

  case NSF32FunctionKey:
    return @"NSF32FunctionKey";

  case NSF33FunctionKey:
    return @"NSF33FunctionKey";

  case NSF34FunctionKey:
    return @"NSF34FunctionKey";

  case NSF35FunctionKey:
    return @"NSF35FunctionKey";

  case NSInsertFunctionKey:
    return @"NSInsertFunctionKey";

  case NSDeleteFunctionKey:
    return @"NSDeleteFunctionKey";

  case NSHomeFunctionKey:
    return @"NSHomeFunctionKey";

  case NSBeginFunctionKey:
    return @"NSBeginFunctionKey";

  case NSEndFunctionKey:
    return @"NSEndFunctionKey";

  case NSPageUpFunctionKey:
    return @"NSPageUpFunctionKey";

  case NSPageDownFunctionKey:
    return @"NSPageDownFunctionKey";

  case NSPrintScreenFunctionKey:
    return @"NSPrintScreenFunctionKey";

  case NSScrollLockFunctionKey:
    return @"NSScrollLockFunctionKey";

  case NSPauseFunctionKey:
    return @"NSPauseFunctionKey";

  case NSSysReqFunctionKey:
    return @"NSSysReqFunctionKey";

  case NSBreakFunctionKey:
    return @"NSBreakFunctionKey";

  case NSResetFunctionKey:
    return @"NSResetFunctionKey";

  case NSStopFunctionKey:
    return @"NSStopFunctionKey";

  case NSMenuFunctionKey:
    return @"NSMenuFunctionKey";

  case NSUserFunctionKey:
    return @"NSUserFunctionKey";

  case NSSystemFunctionKey:
    return @"NSSystemFunctionKey";

  case NSPrintFunctionKey:
    return @"NSPrintFunctionKey";

  case NSClearLineFunctionKey:
    return @"NSClearLineFunctionKey";

  case NSClearDisplayFunctionKey:
    return @"NSClearDisplayFunctionKey";

  case NSInsertLineFunctionKey:
    return @"NSInsertLineFunctionKey";

  case NSDeleteLineFunctionKey:
    return @"NSDeleteLineFunctionKey";

  case NSInsertCharFunctionKey:
    return @"NSInsertCharFunctionKey";

  case NSDeleteCharFunctionKey:
    return @"NSDeleteCharFunctionKey";

  case NSPrevFunctionKey:
    return @"NSPrevFunctionKey";

  case NSNextFunctionKey:
    return @"NSNextFunctionKey";

  case NSSelectFunctionKey:
    return @"NSSelectFunctionKey";

  case NSExecuteFunctionKey:
    return @"NSExecuteFunctionKey";

  case NSUndoFunctionKey:
    return @"NSUndoFunctionKey";

  case NSRedoFunctionKey:
    return @"NSRedoFunctionKey";

  case NSFindFunctionKey:
    return @"NSFindFunctionKey";

  case NSHelpFunctionKey:
    return @"NSHelpFunctionKey";

  case NSModeSwitchFunctionKey:
    return @"NSModeSwitchFunctionKey";

  case 0x07:
    return @"Backspace";

  case 0x0D:
    return @"Enter";

  case 0x20:
    return @"Space";

  default:
    if ((keyCode >= 0x21) && (keyCode <= 0x7E)) {
      return [NSString stringWithFormat:@"%c", keyCode];
    }

    return nil;
  }
}

+ (nullable NSString *)keyCodeToASCIIKeyName:(unichar)keyCode {
  switch (keyCode) {
  case 0x07:
    return @"Backspace";

  case 0x0D:
    return @"Enter";

  default:
    if ((keyCode >= 0x20) && (keyCode <= 0x7E)) {
      NSString *transformed = [[NSString stringWithFormat:@"%c", keyCode]
          stringByApplyingTransform:NSStringTransformToUnicodeName
                            reverse:NO];
      NSString *scanStart = @"{";
      NSString *scanEnd = @"}";

      NSScanner *scanner = [NSScanner scannerWithString:transformed];
      [scanner scanUpToString:scanStart intoString:nil];
      if ([scanner scanString:scanEnd intoString:nil]) {
        NSString *result = nil;
        if ([scanner scanUpToString:scanEnd intoString:&result]) {
          return result;
        }
      } else {
        return [NSString stringWithFormat:@"%c", keyCode];
      }
    }

    return nil;
  }
}

+ (NSUInteger)keyCodeToPETSCIIKeyCode:(unichar)keyCode {
  switch (keyCode) {
  case NSUpArrowFunctionKey:
    return kPETSCIIMovementUpKey;

  case NSDownArrowFunctionKey:
    return kPETSCIIMovementDownKey;

  case NSLeftArrowFunctionKey:
    return kPETSCIIMovementLeftKey;

  case NSRightArrowFunctionKey:
    return kPETSCIIMovementRightKey;

  default:
    break;
  }

  if (keyCode > 0xFF) {
    return SFTUnmappedKey;
  }

  uint16_t mapped = kKeycodeToPETSCIILookup[keyCode & 0xFF];
  if (mapped == kUnmappedKey) {
    return SFTUnmappedKey;
  }

  return mapped;
}

+ (nullable NSString *)petsciiKeyCodeToPETSCIIKeyName:(NSUInteger)keyCode {
  if (keyCode > 0xFF) {
    return nil;
  }

  switch (keyCode) {
  default: {
    uint16_t mapped = kPETSCIIKeyCodeToASCII[keyCode];
    switch (mapped) {
    case kControlBell:
      return @"BELL";

    case kControlBackspace:
      return @"BACKSPACE";

    case kControlNewLine:
      return @"NEW LINE";

    case kControlCarriageReturn:
      return @"CARRIAGE RETURN";

    case kControlIgnore:
      return nil;

    case kUnmappedKey:
      switch (keyCode) {
      case kPETSCIIMovementUpKey:
        return @"CURSOR UP";

      case kPETSCIIMovementDownKey:
        return @"CURSOR DOWN";

      case kPETSCIIMovementLeftKey:
        return @"CURSOR LEFT";

      case kPETSCIIMovementRightKey:
        return @"CURSOR RIGHT";
      default:
        return nil;
      }

    default:
      return [NSString stringWithFormat:@"%c", (unichar)mapped];
    }
  }
  }
}

@end
