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

@import Metal;
@import MetalKit;

#import "SFTConnectionWindowController.h"
#import "SFTCommon.h"
#import "SFTDataFlowLogger.h"
#import "SFTDocument.h"
#import "SFTIOProcessor.h"
#import "SFTNetworkIOProcessor.h"
#import "SFTPlaybackIOProcessor.h"
#import "SFTReplaySpeedSelectorViewController.h"
#import "SFTSharedMetalResources.h"
#import "SFTSharedResources.h"

#import "MTKView+Screenshot.h"

static NSString *kWindowNibName = @"Connection";

static const NSTimeInterval kCursorStateChangeInterval = 0.5f;

@interface SFTConnectionWindowController () <MTKViewDelegate, NSWindowDelegate,
                                             SFTIOProcessorDelegate>

@property(weak) IBOutlet MTKView *contentsView;

@property(strong, nonatomic) id<MTLCommandQueue> metalCommandQueue;
@property(strong, nonatomic, nonnull) NSTimer *cursorBlinkTimer;
@property(strong, nonatomic, nullable) SFTIOProcessor *ioProcessor;

@property(strong, nonatomic, nonnull)
    SFTTerminalEmulatorContext *terminalContext;

- (void)initialiseGraphics;
- (void)initialiseTerminal;
- (void)initialiseNetwork;

- (void)updateWindowSize:(CGSize)size;
- (void)processIncomingBuffer:(nonnull NSData *)buffer;

- (void)setEnabledForMenuItemTag:(SFTUserInterfaceTag)menuItemTag
                         enabled:(BOOL)enabled;

@end

@implementation SFTConnectionWindowController

- (void)awakeFromNib {
  self.window.acceptsMouseMovedEvents = YES;
}

- (void)windowDidLoad {
  [super windowDidLoad];

  [self initialiseGraphics];
  [self initialiseTerminal];
  [self initialiseNetwork];
}

- (void)initialiseGraphics {
  id<MTLDevice> device = SFTSharedMetalResources.sharedInstance.device;

  self.contentsView.delegate = self;
  self.contentsView.device = device;
  self.contentsView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
  self.contentsView.framebufferOnly = NO;

  self.metalCommandQueue = [device newCommandQueue];
  [self updateWindowSize:self.window.frame.size];
  [self.document
      setScreenContents:
          [device
              newBufferWithLength:SFTViewSize * sizeof(SFTTerminalEmulatorCell)
                          options:MTLResourceStorageModeManaged |
                                  MTLResourceCPUCacheModeWriteCombined]];

  __weak SFTConnectionWindowController *weakSelf = self;
  self.cursorBlinkTimer = [NSTimer
      scheduledTimerWithTimeInterval:kCursorStateChangeInterval
                             repeats:YES
                               block:^(NSTimer *_Nonnull timer) {
                                 SFTConnectionWindowController *strongSelf =
                                     weakSelf;
                                 SFTShaderContext *shaderContext =
                                     (SFTShaderContext *)
                                         [strongSelf.document shaderContext]
                                             .contents;
                                 shaderContext->flags.blink =
                                     (uint8_t)!shaderContext->flags.blink;
                                 [[strongSelf.document shaderContext]
                                     didModifyRange:NSMakeRange(
                                                        offsetof(
                                                            SFTShaderContext,
                                                            flags),
                                                        sizeof(uint8_t))];
                                 [strongSelf.contentsView draw];
                               }];
}

- (void)initialiseTerminal {
  // @TODO: Default to upper case
  self.terminalContext =
      [[SFTTerminalEmulatorContext alloc] initWithWidth:SFTViewColumns
                                              andHeight:SFTViewRows
                                        usingBackground:SFTC64ColourBlack
                                          andForeground:SFTC64ColourLightBlue
                                            inASCIIMode:YES
                                         usingLowerCase:NO];

  [SFTSharedResources.sharedInstance.terminalEmulator
      clearScreenForContext:self.terminalContext
               onCellBuffer:(SFTTerminalEmulatorCell *)
                                [self.document screenContents]
                                    .contents];
  [[self.document screenContents]
      didModifyRange:NSMakeRange(0, sizeof(SFTViewSize) *
                                        sizeof(SFTTerminalEmulatorCell))];
}

- (void)initialiseNetwork {
  SFTAddressBookEntry *entry = [self.document entry];
  NSURL *potentialAddress = entry != nil
                                ? entry.address
                                : ((SFTDocument *)self.document).address;
  NSURL *address = potentialAddress;
  if ((entry != nil) && (potentialAddress.host == nil) &&
      (potentialAddress.scheme != nil)) {
    address = [NSURL URLWithString:[NSString stringWithFormat:@"telnet://%@",
                                                              entry.address]];
  }

  self.ioProcessor = [SFTNetworkIOProcessor networkIOProcessorWithURL:address];
  if (self.ioProcessor == nil) {
    self.ioProcessor = [SFTPlaybackIOProcessor new];
  }

  self.ioProcessor.delegate = self;
  [self.ioProcessor start];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
  [self updateWindowSize:size];
}

- (void)drawInMTKView:(MTKView *)view {
  id<MTLCommandBuffer> commandBuffer = [self.metalCommandQueue commandBuffer];

  MTLRenderPassDescriptor *passDescriptor =
      self.contentsView.currentRenderPassDescriptor;
  if (passDescriptor != nil) {
    id<MTLRenderCommandEncoder> encoder =
        [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    [encoder setRenderPipelineState:SFTSharedMetalResources.sharedInstance
                                        .renderPipelineState];
    [encoder setFragmentBuffer:[self.document shaderContext]
                        offset:0
                       atIndex:0];
    [encoder setFragmentBuffer:[self.document screenContents]
                        offset:0
                       atIndex:1];
    [encoder
        setFragmentTexture:SFTSharedMetalResources.sharedInstance.charsetTexture
                   atIndex:0];
    [encoder
        setVertexBuffer:SFTSharedMetalResources.sharedInstance.vertexBufferQuad
                 offset:0
                atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                vertexStart:0
                vertexCount:SFTVertexBufferQuadItemsCount];
    [encoder endEncoding];
  }

  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}

- (void)updateWindowSize:(CGSize)size {
  SFTShaderContext *shaderContext =
      (SFTShaderContext *)[self.document shaderContext].contents;
  shaderContext->screenWidth = (float)size.width;
  shaderContext->screenHeight = (float)size.height;
  [[self.document shaderContext]
      didModifyRange:NSMakeRange(offsetof(SFTShaderContext, screenWidth),
                                 sizeof(float) * 2)];
}

- (void)mouseDown:(NSEvent *)event {
  NSPoint location = [self.contentsView convertPoint:event.locationInWindow
                                            fromView:self.contentsView];
  CGSize size = self.contentsView.frame.size;
  CGFloat x = location.x / size.width;
  CGFloat y = 1.0 - (location.y / size.height);

  if ((x < 0.0) || (y < 0.0)) {
    [super mouseDown:event];
    return;
  }

  uint16_t start =
      (uint16_t)(((((NSInteger)(y * SFTViewRows)) * SFTViewColumns) +
                  (NSInteger)(x * SFTViewColumns)) &
                 0xFFFF);
  [self.document setSelectionRangeFromIndex:start toIndex:start];
  [super mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event {
  if ((NSEvent.pressedMouseButtons & (1 << 0)) != (1 << 0)) {
    [self.document setSelectionRangeFromIndex:0 toIndex:0];
    [super mouseMoved:event];
    return;
  }

  NSPoint location = [self.contentsView convertPoint:event.locationInWindow
                                            fromView:self.contentsView];
  CGSize size = self.contentsView.frame.size;
  CGFloat x = location.x / size.width;
  CGFloat y = 1.0 - (location.y / size.height);

  if ((x < 0.0) || (x > 1.0) || (y < 0.0) || (y > 1.0)) {
    [self.document setSelectionRangeFromIndex:0 toIndex:0];
  } else {
    uint16_t end =
        (uint16_t)(((((NSInteger)(y * SFTViewRows)) * SFTViewColumns) +
                    (NSInteger)(x * SFTViewColumns)) &
                   0xFFFF);
    [self.document setSelectionEnd:end];
  }

  [super mouseDragged:event];
}

- (void)mouseUp:(NSEvent *)event {
  NSPoint location = [self.contentsView convertPoint:event.locationInWindow
                                            fromView:self.contentsView];
  CGSize size = self.contentsView.frame.size;
  CGFloat x = location.x / size.width;
  CGFloat y = 1.0 - (location.y / size.height);

  if ((x < 0.0) || (x > 1.0) || (y < 0.0) || (y > 1.0)) {
    [self.document setSelectionRangeFromIndex:0 toIndex:0];
  } else {
    uint16_t end =
        (uint16_t)(((((NSInteger)(y * SFTViewRows)) * SFTViewColumns) +
                    (NSInteger)(x * SFTViewColumns)) &
                   0xFFFF);
    [self.document setSelectionEnd:end];
  }

  [super mouseUp:event];
}

//- (void)mouseMoved:(NSEvent *)event {
//  NSPoint location = [self.contentsView convertPoint:event.locationInWindow
//                                            fromView:self.contentsView];
//  CGSize size = self.contentsView.frame.size;
//  CGFloat x = location.x / size.width;
//  CGFloat y = 1.0 - (location.y / size.height);
//
//  if ((x < 0.0) || (x > 1.0) || (y < 0.0) || (y > 1.0)) {
//    [self.document setPointerPosition:NSIntegerMin];
//    [super mouseMoved:event];
//    return;
//  }
//
//  [self.document
//      setPointerPosition:((((NSInteger)(y * SFTViewRows)) * SFTViewColumns) +
//                          (NSInteger)(x * SFTViewColumns))];
//
//  [super mouseMoved:event];
//}

- (void)keyDown:(NSEvent *)event {
  [self.document setSelectionRangeFromIndex:0 toIndex:0];

  if (event.characters.length == 0) {
    [super keyDown:event];
    return;
  }

  [self.document setLastKeyEvent:event];
  if ([self.document filterKeypresses]) {
    return;
  }

  unichar character = [event.characters characterAtIndex:0];

  NSMutableData *keyboardBuffer = [NSMutableData new];

  if ([SFTSharedResources.sharedInstance.terminalEmulator
          convertKeyCodeForContext:self.terminalContext
                       withKeyCode:character
                      toCharacters:keyboardBuffer]) {

    [self.ioProcessor sendData:keyboardBuffer];
  } else {
    [super keyDown:event];
  }
}

- (void)processIncomingBuffer:(nonnull NSData *)buffer {
  if ([SFTSharedResources.sharedInstance.terminalEmulator
          processIncomingDataForContext:self.terminalContext
                           onCellBuffer:(SFTTerminalEmulatorCell *)
                                            [self.document screenContents]
                                                .contents
                                forData:buffer]) {
    [[self.document screenContents]
        didModifyRange:NSMakeRange(0, sizeof(SFTViewSize) *
                                          sizeof(SFTTerminalEmulatorCell))];
  }

  SFTShaderContext *shaderContext =
      (SFTShaderContext *)[self.document shaderContext].contents;
  shaderContext->flags.lowerCase = (uint8_t)self.terminalContext.useLowerCase;
  shaderContext->cursorRow = (uint16_t)(self.terminalContext.row & 0xFFFF);
  shaderContext->cursorColumn =
      (uint16_t)(self.terminalContext.column & 0xFFFF);

  [[self.document shaderContext]
      didModifyRange:NSMakeRange(offsetof(SFTShaderContext, cursorRow),
                                 sizeof(uint8_t) + (sizeof(uint16_t) * 2))];
}

- (void)windowWillClose:(NSNotification *)notification {
  NSAssert([notification.object isKindOfClass:NSWindow.class],
           @"Window close notification without window object?");
  NSWindow *window = (NSWindow *)notification.object;

  if (window == self.window) {
    [self.cursorBlinkTimer invalidate];
    [self.ioProcessor stop];
  }
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
  [self setEnabledForMenuItemTag:SFTUserInterfaceTagMenuConnection enabled:YES];
  [self setEnabledForMenuItemTag:SFTUserInterfaceTagMenuDebug enabled:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification {
  [self setEnabledForMenuItemTag:SFTUserInterfaceTagMenuConnection enabled:NO];
  [self setEnabledForMenuItemTag:SFTUserInterfaceTagMenuDebug enabled:NO];
}

// @TODO: Keep aspect ratio when resizing.

//- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
//    return self.window.frame.size;
//}

- (nullable NSImage *)contentsImage {
  return self.contentsView.screenshot;
}

- (void)replaySession {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.canCreateDirectories = NO;
  panel.resolvesAliases = YES;
  panel.allowsMultipleSelection = NO;

  SFTReplaySpeedSelectorViewController *accessoryViewController =
      [[SFTReplaySpeedSelectorViewController alloc]
          initWithNibName:@"ReplaySpeedSelector"
                   bundle:NSBundle.mainBundle];
  accessoryViewController.openPanel = panel;
  panel.delegate = accessoryViewController;

  panel.accessoryView = accessoryViewController.view;
  panel.accessoryViewDisclosed = YES;

  switch ([panel runModal]) {
  case NSModalResponseOK: {
    NSUInteger bps = [SFTReplaySpeedSelectorViewController
        bpsForSpeed:accessoryViewController.replaySpeed];

    [SFTSharedResources.sharedInstance.terminalEmulator
        clearScreenForContext:self.terminalContext
                 onCellBuffer:(SFTTerminalEmulatorCell *)
                                  [self.document screenContents]
                                      .contents];
    [[self.document screenContents]
        didModifyRange:NSMakeRange(0, sizeof(SFTViewSize) *
                                          sizeof(SFTTerminalEmulatorCell))];

    if ([self.ioProcessor isKindOfClass:SFTPlaybackIOProcessor.class]) {
      [(SFTPlaybackIOProcessor *)self.ioProcessor
          injectSessionDataFromURL:panel.URL
                    withSpeedInBps:bps > 0 ? bps
                                           : accessoryViewController
                                                 .customBaudRate];
    }

    break;
  }

  case NSModalResponseStop:
  case NSModalResponseAbort:
  case NSModalResponseCancel:
  case NSModalResponseContinue:
    break;

  default:
    break;
  }
}

- (NSData *)rawContentsBuffer {
  return [NSData dataWithBytes:[self.document screenContents].contents
                        length:SFTViewSize * sizeof(SFTTerminalEmulatorCell)];
}

+ (nonnull NSString *)nibName {
  return kWindowNibName;
}

- (void)setEnabledForMenuItemTag:(SFTUserInterfaceTag)menuItemTag
                         enabled:(BOOL)enabled {
  NSMenuItem *item = [NSApp.menu itemWithTag:menuItemTag];
  if (item != nil) {
    item.enabled = enabled;
  }
}

- (void)ioProcessor:(SFTIOProcessor *)processor
      receivedEvent:(SFTIOProcessorEvent)event
           withData:(NSData *)data {
  switch (event) {
  case SFTIOProcessorEventReceivedData:
    //    if ([self.document logPackets]) {
    //      SFTDataFlowLogEntry *entry = [SFTDataFlowLogEntry
    //          dataFlowLogEntryWithBytes:data
    //                       andDirection:SFTDataPacketDirectionInbound];
    //      [[self.document packetLogger] appendEntry:entry];
    //      NSLog(@"%@", entry);
    //    }

    [self processIncomingBuffer:data];
    break;

  case SFTIOProcessorEventDisconnected: {
    SFTShaderContext *shaderContext =
        (SFTShaderContext *)[self.document shaderContext].contents;
    shaderContext->flags.disconnected = YES;

    [[self.document shaderContext]
        didModifyRange:NSMakeRange(offsetof(SFTShaderContext, flags),
                                   sizeof(uint8_t))];

    [self.contentsView draw];

    self.window.title =
        [self.window.title stringByAppendingString:@" - DISCONNECTED"];
  }

  break;
  }
}

- (IBAction)copy:(id)sender {
#if 0
  if (([self.document selectionStart] < 0) ||
      ([self.document selectionEnd] < 0)) {
    return;
  }

  NSFont *font =
      [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];

  NSMutableAttributedString *attributedString = [NSMutableAttributedString new];

  [attributedString beginEditing];

  SFTTerminalEmulatorCell *contents =
      (SFTTerminalEmulatorCell *)[self.document screenContents].contents;
  NSUInteger index = 0;

  for (NSUInteger offset = (NSUInteger)[self.document selectionStart];
       offset <= (NSUInteger)[self.document selectionEnd]; offset++) {
    uint8_t character = SFTTerminalEmulatorCellGetCharacter(contents[offset]);
    NSColor *foreground;
    NSColor *background;
    if (SFTTerminalEmulatorCellGetReverse(contents[offset])) {
      background = SFTSharedResources.sharedInstance
                       .paletteColours[SFTTerminalEmulatorCellGetForeground(
                           contents[offset])];
      foreground = SFTSharedResources.sharedInstance
                       .paletteColours[SFTTerminalEmulatorCellGetBackground(
                           contents[offset])];
    } else {
      background = SFTSharedResources.sharedInstance
                       .paletteColours[SFTTerminalEmulatorCellGetBackground(
                           contents[offset])];
      foreground = SFTSharedResources.sharedInstance
                       .paletteColours[SFTTerminalEmulatorCellGetForeground(
                           contents[offset])];
    }

    [attributedString.mutableString appendFormat:@"%c", character];

    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:foreground
                             range:NSMakeRange(index, 1)];
    [attributedString addAttribute:NSBackgroundColorAttributeName
                             value:background
                             range:NSMakeRange(index, 1)];

    ++index;
  }

  [attributedString addAttribute:NSFontAttributeName
                           value:font
                           range:NSMakeRange(0, index - 1)];

  [attributedString endEditing];

  [NSPasteboard.generalPasteboard clearContents];
  [NSPasteboard.generalPasteboard writeObjects:@[ attributedString ]];
#endif
}

@end
