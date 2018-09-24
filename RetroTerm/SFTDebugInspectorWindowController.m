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

#import "SFTDebugInspectorWindowController.h"
#import "SFTCommon.h"
#import "SFTDocument.h"
#import "SFTKeyConverter.h"

NSString *SFTEventToCocoaKeypressTransformerName =
    @"SFTEventToCocoaKeypressTransformer";
NSString *SFTEventToASCIIKeypressTransformerName =
    @"SFTEventToASCIIKeypressTransformer";
NSString *SFTEventToPETSCIIKeypressTransformerName =
    @"SFTEventToPETSCIIKeypressTransformer";
NSString *SFTEventToControlModifierTransformerName =
    @"SFTEventToControlModifierTransformer";
NSString *SFTEventToOptionModifierTransformerName =
    @"SFTEventToOptionModifierTransformer";
NSString *SFTEventToCommandModifierTransformerName =
    @"SFTEventToCommandModifierTransformer";
NSString *SFTEventToShiftModifierTransformerName =
    @"SFTEventToShiftModifierTransformer";
NSString *SFTIndexToPositionStringTransformerName =
    @"SFTIndexToPositionStringTransformer";

@interface SFTEventToCocoaKeypressTransformer : NSValueTransformer

@end

@interface SFTEventToASCIIKeypressTransformer : NSValueTransformer

@end

@interface SFTEventToPETSCIIKeypressTransformer : NSValueTransformer

@end

@interface SFTEventToBooleanModifierTransformer : NSValueTransformer

@property(assign, nonatomic, readonly) NSEventModifierFlags flagsMask;

- (nonnull instancetype)initWithModifierFlagsMask:
    (NSEventModifierFlags)flagsMask;

@end

@interface SFTIndexToPositionStringTransformer : NSValueTransformer

@end

@implementation SFTEventToCocoaKeypressTransformer

+ (Class)transformedValueClass {
  return NSString.class;
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  if (![value isKindOfClass:NSEvent.class]) {
    return nil;
  }

  NSEvent *event = (NSEvent *)value;
  if (event.charactersIgnoringModifiers.length == 0) {
    return nil;
  }
  unichar keyPress = [event.charactersIgnoringModifiers characterAtIndex:0];
  NSString *transformed = [SFTKeyConverter keyCodeToCocoaKeyName:keyPress];
  return (transformed != nil)
             ? [NSString stringWithFormat:@"(%hu / 0x%04hX) %@", keyPress,
                                          keyPress, transformed]
             : nil;
}

@end

@implementation SFTEventToASCIIKeypressTransformer

+ (Class)transformedValueClass {
  return NSString.class;
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  NSString *result = nil;
  if ((value != nil) && [value isKindOfClass:NSEvent.class]) {
    NSEvent *event = (NSEvent *)value;
    if (event.charactersIgnoringModifiers.length > 0) {
      unichar keyPress = [event.charactersIgnoringModifiers characterAtIndex:0];
      NSString *transformed = [SFTKeyConverter keyCodeToASCIIKeyName:keyPress];
      if (transformed != nil) {
        result = [NSString stringWithFormat:@"(%hu / 0x%04hX) %@", keyPress,
                                            keyPress, transformed];
      }
    }
  }

  return result;
}

@end

@implementation SFTEventToPETSCIIKeypressTransformer

+ (Class)transformedValueClass {
  return NSString.class;
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  if (![value isKindOfClass:NSEvent.class]) {
    return nil;
  }

  NSEvent *event = (NSEvent *)value;
  if (event.charactersIgnoringModifiers.length == 0) {
    return nil;
  }

  unichar keyPress = [event.charactersIgnoringModifiers characterAtIndex:0];
  NSUInteger keyCode = [SFTKeyConverter keyCodeToPETSCIIKeyCode:keyPress];
  NSAssert(keyCode != SFTUnmappedKey,
           @"Unmapped PETSCII Code for keyPress character %04hX", keyPress);
  NSString *transformed = [SFTKeyConverter keyCodeToASCIIKeyName:keyPress];
  return [NSString
      stringWithFormat:@"(%lu / 0x%04lX) %@", keyCode, keyCode, transformed];
}

@end

@implementation SFTEventToBooleanModifierTransformer

+ (Class)transformedValueClass {
  return NSNumber.class;
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (nonnull instancetype)initWithModifierFlagsMask:
    (NSEventModifierFlags)flagsMask {
  self = [super init];
  if (self != nil) {
    _flagsMask = flagsMask;
  }

  return self;
}

- (id)transformedValue:(id)value {
  NSNumber *result = nil;
  if ((value != nil) && [value isKindOfClass:NSEvent.class]) {
    NSEvent *event = (NSEvent *)value;
    if (event.charactersIgnoringModifiers.length > 0) {
      result = @((event.modifierFlags & self.flagsMask) != self.flagsMask);
    }
  }

  return result;
}

@end

@implementation SFTIndexToPositionStringTransformer

+ (Class)transformedValueClass {
  return NSString.class;
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  NSString *result = nil;
  if ((value != nil) && [value isKindOfClass:NSNumber.class]) {
    NSNumber *number = (NSNumber *)value;
    if (number.integerValue >= 0) {
      result = [NSString
          stringWithFormat:@"%ld (x: %lu y: %lu)",
                           (long)number.unsignedIntegerValue,
                           number.unsignedIntegerValue % SFTViewColumns,
                           number.unsignedIntegerValue / SFTViewColumns];
    }
  }

  return result;
}

@end

@interface SFTDebugInspectorWindowController () <NSWindowDelegate>

@property(weak) IBOutlet NSButton *hoverReversed;
@property(weak) IBOutlet NSView *hoverForegroundColour;
@property(weak) IBOutlet NSView *hoverBackgroundColour;
@property(weak) IBOutlet NSImageView *characterImage;
@property(strong, nonatomic, nonnull) NSImage *image;
@property(strong, nonatomic, nonnull) NSImage *lowerCaseFont;

@end

@implementation SFTDebugInspectorWindowController

+ (void)initialize {
  [NSValueTransformer
      setValueTransformer:[SFTEventToCocoaKeypressTransformer new]
                  forName:SFTEventToCocoaKeypressTransformerName];
  [NSValueTransformer
      setValueTransformer:[SFTEventToASCIIKeypressTransformer new]
                  forName:SFTEventToASCIIKeypressTransformerName];
  [NSValueTransformer
      setValueTransformer:[SFTEventToPETSCIIKeypressTransformer new]
                  forName:SFTEventToPETSCIIKeypressTransformerName];

  [NSValueTransformer
      setValueTransformer:
          [[SFTEventToBooleanModifierTransformer alloc]
              initWithModifierFlagsMask:NSEventModifierFlagControl]
                  forName:SFTEventToControlModifierTransformerName];
  [NSValueTransformer
      setValueTransformer:
          [[SFTEventToBooleanModifierTransformer alloc]
              initWithModifierFlagsMask:NSEventModifierFlagOption]
                  forName:SFTEventToOptionModifierTransformerName];
  [NSValueTransformer
      setValueTransformer:
          [[SFTEventToBooleanModifierTransformer alloc]
              initWithModifierFlagsMask:NSEventModifierFlagCommand]
                  forName:SFTEventToCommandModifierTransformerName];
  [NSValueTransformer
      setValueTransformer:
          [[SFTEventToBooleanModifierTransformer alloc]
              initWithModifierFlagsMask:NSEventModifierFlagShift]
                  forName:SFTEventToShiftModifierTransformerName];

  [NSValueTransformer
      setValueTransformer:[SFTIndexToPositionStringTransformer new]
                  forName:SFTIndexToPositionStringTransformerName];
}

- (void)awakeFromNib {
  self.hoverForegroundColour.wantsLayer = YES;
  self.hoverBackgroundColour.wantsLayer = YES;
  self.image = [[NSImage alloc] initWithSize:NSMakeSize(8.0, 8.0)];
  self.lowerCaseFont = [NSImage imageNamed:@"CharsetLowerImage"];
}

- (void)windowDidLoad {
  [super windowDidLoad];

  //  [NSApp.mainWindow.windowController.document
  //      addObserver:self
  //       forKeyPath:@"pointerPosition"
  //          options:NSKeyValueObservingOptionNew
  //          context:nil];
}

//- (void)windowWillClose:(NSNotification *)notification {
//    [NSApp.mainWindow.windowController.document
//     removeObserver:self
//     forKeyPath:@"pointerPosition"];
//}

//- (void)observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
//                       context:(void *)context {
//  if ([@"pointerPosition" isEqualToString:keyPath]) {
//    NSAssert([change[NSKeyValueChangeKindKey] isKindOfClass:NSNumber.class],
//             @"Invalid type for pointer position change notifications");
//    NSNumber *kind = (NSNumber *)change[NSKeyValueChangeKindKey];
//    if (kind.unsignedIntegerValue == NSKeyValueChangeSetting) {
//      NSAssert([change[NSKeyValueChangeNewKey] isKindOfClass:NSNumber.class],
//               @"Invalid type for pointer position value");
//      NSNumber *value = (NSNumber *)change[NSKeyValueChangeNewKey];
//      if ((value.integerValue < 0) || (value.integerValue > SFTViewSize)) {
//        return;
//      }
//
//      NSUInteger index = value.unsignedIntegerValue;
//
//      NSData *rawContents =
//          [(SFTDocument *)
//                  NSApp.mainWindow.windowController.document
//                  rawContentsBuffer];
//      SFTTerminalEmulatorCell *cells =
//          (SFTTerminalEmulatorCell *)rawContents.bytes;
//      SFTTerminalEmulatorCell cell = cells[index];
//      self.hoverForegroundColour.layer.backgroundColor =
//          SFTSharedResources.sharedInstance
//              .paletteColours[SFTTerminalEmulatorCellGetForeground(cell)]
//              .CGColor;
//      self.hoverBackgroundColour.layer.backgroundColor =
//          SFTSharedResources.sharedInstance
//              .paletteColours[SFTTerminalEmulatorCellGetBackground(cell)]
//              .CGColor;
//      self.hoverReversed.state = SFTTerminalEmulatorCellGetReverse(cell) ==
//      YES
//                                     ? NSControlStateValueOn
//                                     : NSControlStateValueOff;
//
//      NSUInteger characterIndex = SFTTerminalEmulatorCellGetCharacter(cell);
//      NSUInteger rectX = (characterIndex % 32) * 8;
//      NSUInteger rectY = (characterIndex / 32) * 8;
//
//      [self.image lockFocus];
//      NSEraseRect(NSMakeRect(0.0, 0.0, 8.0, 8.0));
//      [self.lowerCaseFont drawInRect:NSMakeRect(0.0, 0.0, 8.0, 8.0)
//                            fromRect:NSMakeRect(rectX, rectY, 8.0, 8.0)
//                           operation:NSCompositingOperationCopy
//                            fraction:1.0];
//      [self.image unlockFocus];
//      self.characterImage.image = self.image;
//    }
//  }
//}

+ (nonnull instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static SFTDebugInspectorWindowController *instance;
  dispatch_once(&onceToken, ^{
    instance = [[SFTDebugInspectorWindowController alloc]
        initWithWindowNibName:@"DebugInspector"];
  });

  return instance;
}

@end
