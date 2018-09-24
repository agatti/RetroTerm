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

#import "SFTDocument.h"
#import "SFTCommon.h"
#import "SFTConnectionWindowController.h"
#import "SFTSharedMetalResources.h"

static NSString *kDocumentType = @"SFTDocument";
static NSString *kDebugWindowName = @"Debug Window";

@interface SFTDocument ()

@property(assign, nonatomic, readwrite) NSRange selectionRange;

@property(assign, nonatomic) BOOL isDebugWindow;
@property(strong, nonatomic, nonnull)
    SFTConnectionWindowController *connectionWindowController;

- (void)secondStageInitialisation;

- (IBAction)useScreenshotAsEntryImage:(id)sender;
- (IBAction)copyScreenshotToClipboard:(id)sender;
- (IBAction)replaySavedSession:(id)sender;
- (IBAction)clearLoggedPackets:(id)sender;

@end

@implementation SFTDocument

- (void)secondStageInitialisation {
  _selectionStart = NSIntegerMin;
  _selectionEnd = NSIntegerMin;
  _pointerPosition = NSIntegerMin;

  _selectionRange = NSMakeRange(0, 0);
  _shaderContext = [SFTSharedMetalResources.sharedInstance.device
      newBufferWithLength:sizeof(SFTShaderContext)
                  options:MTLResourceStorageModeManaged |
                          MTLResourceCPUCacheModeWriteCombined];
  SFTShaderContext *context = (SFTShaderContext *)[_shaderContext contents];

  context->cellsTall = (uint16_t)SFTViewRows;
  context->cellsWide = (uint16_t)SFTViewColumns;
  context->selectionStart = 0;
  context->selectionEnd = 0;
  context->cursorRow = 0;
  context->cursorColumn = 0;
  context->flags.lowerCase = YES;
  context->flags.blink = YES;
  context->flags.disconnected = NO;
  context->flags.reserved = 0;

  [_shaderContext
      didModifyRange:NSMakeRange(offsetof(SFTShaderContext, cellsWide),
                                 sizeof(SFTShaderContext) -
                                     offsetof(SFTShaderContext, cellsWide))];
}

- (nonnull instancetype)init {
  self = [super init];
  if (self != nil) {
    self.displayName = kDebugWindowName;
    _isDebugWindow = YES;
    _hasBackingEntry = NO;
    [self secondStageInitialisation];
  }

  return self;
}

- (nonnull instancetype)initWithEntry:(nonnull SFTAddressBookEntry *)entry
                                error:(NSError *_Nonnull *_Nullable)error {
  self = [super initWithType:kDocumentType error:error];
  if (self != nil) {
    _entry = entry;
    self.displayName = _entry.address.absoluteString;
    _packetLogger = [[SFTDataFlowLogger alloc] init];
    _logPackets = YES;
    _isDebugWindow = NO;
    _hasBackingEntry = YES;
    [self secondStageInitialisation];
  }

  return self;
}

- (nonnull instancetype)initWithAddress:(nonnull NSURL *)address
                                  error:(NSError *_Nonnull *_Nullable)error {
  self = [super initWithType:kDocumentType error:error];
  if (self != nil) {
    _address = address;
    self.displayName =
        [NSString stringWithFormat:@"%@:%d", address.host,
                                   address.port.unsignedShortValue];
    _packetLogger = [[SFTDataFlowLogger alloc] init];
    _logPackets = YES;
    _isDebugWindow = NO;
    _hasBackingEntry = NO;
    [self secondStageInitialisation];
  }

  return self;
}

- (void)makeWindowControllers {
  self.connectionWindowController = [[SFTConnectionWindowController alloc]
      initWithWindowNibName:SFTConnectionWindowController.nibName];
  [self addWindowController:self.connectionWindowController];
}

- (NSData *)dataOfType:(NSString *__unused)typeName
                 error:(NSError *__autoreleasing *__unused)outError {
  [NSException raise:@"UnimplementedMethod"
              format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
  return nil;
}

- (BOOL)readFromData:(NSData *__unused)data
              ofType:(NSString *__unused)typeName
               error:(NSError *__autoreleasing *__unused)outError {
  [NSException raise:@"UnimplementedMethod"
              format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
  return YES;
}

- (nonnull NSData *)rawContentsBuffer {
  return self.connectionWindowController.rawContentsBuffer;
}

- (IBAction)useScreenshotAsEntryImage:(id __unused)sender {
  NSImage *screenshot = self.connectionWindowController.contentsImage;
  if (screenshot != nil) {
    self.entry.image = screenshot.TIFFRepresentation;
  }
}

- (IBAction)copyScreenshotToClipboard:(id __unused)sender {
  NSImage *screenshot = self.connectionWindowController.contentsImage;
  if (screenshot != nil) {
    [NSPasteboard.generalPasteboard clearContents];
    [NSPasteboard.generalPasteboard writeObjects:@[ screenshot ]];
  }
}

- (IBAction)clearLoggedPackets:(id __unused)sender {
  [self.packetLogger clear];
}

- (IBAction)replaySavedSession:(id __unused)sender {
  [self.connectionWindowController replaySession];
}

- (IBAction)printDocument:(id __unused)sender {
  NSImage *screenshot = self.connectionWindowController.contentsImage;
  if ((screenshot == nil) || (screenshot.isValid == NO)) {
    return;
  }

  NSPrintInfo *printInfo = NSPrintInfo.sharedPrintInfo;
  printInfo.horizontalPagination = NSFitPagination;
  printInfo.verticalPagination = NSFitPagination;
  printInfo.horizontallyCentered = YES;
  printInfo.verticallyCentered = YES;

  NSImageView *view = [NSImageView imageViewWithImage:screenshot];
  NSData *pdfImageData = [view dataWithPDFInsideRect:view.frame];
  NSPDFImageRep *pdfImageRepresentation =
      [NSPDFImageRep imageRepWithData:pdfImageData];
  NSImage *pdfImage = [[NSImage alloc] initWithSize:view.frame.size];
  [pdfImage addRepresentation:pdfImageRepresentation];

  NSImageView *pdfImageView = [[NSImageView alloc] init];
  pdfImageView.image = pdfImage;
  pdfImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
  [pdfImageView setBoundsOrigin:NSMakePoint(0, 0)];
  [pdfImageView setBoundsSize:pdfImage.size];
  [pdfImageView
      translateOriginToPoint:NSMakePoint(0, printInfo.paperSize.height -
                                                pdfImage.size.height)];

  NSPrintOperation *printOperation =
      [NSPrintOperation printOperationWithView:pdfImageView
                                     printInfo:printInfo];
  printOperation.showsPrintPanel = YES;
  printOperation.canSpawnSeparateThread = YES;
  [self runModalPrintOperation:printOperation
                      delegate:nil
                didRunSelector:nil
                   contextInfo:nil];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
  if (item.tag == SFTUserInterfaceTagMenuDebugSessionReplayMenuItem) {
    return self.isDebugWindow;
  }

  return YES;
}

- (void)setSelectionRangeFromIndex:(NSUInteger)startIndex
                           toIndex:(NSUInteger)endIndex {
  if (endIndex < startIndex) {
    self.selectionRange = NSMakeRange(endIndex, endIndex - startIndex);
  } else {
    self.selectionRange = NSMakeRange(startIndex, startIndex - endIndex);
  }

  SFTShaderContext *shaderContext =
      (SFTShaderContext *)self.shaderContext.contents;
  shaderContext->selectionStart =
      (uint16_t)(self.selectionRange.location & 0xFFFF);
  shaderContext->selectionEnd = shaderContext->selectionStart +
                                (uint16_t)(self.selectionRange.length & 0xFFFF);
  [self.shaderContext
      didModifyRange:NSMakeRange(offsetof(SFTShaderContext, selectionStart),
                                 sizeof(uint16_t) * 2)];
}

- (void)setSelectionRangeStart:(NSUInteger)start {
  [self setSelectionRangeFromIndex:start toIndex:start];
}

- (void)setSelectionRangeEnd:(NSUInteger)end {
  [self setSelectionRangeFromIndex:self.selectionRange.location toIndex:end];
}

@end
