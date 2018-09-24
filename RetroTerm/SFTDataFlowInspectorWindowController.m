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

#import "SFTDataFlowInspectorWindowController.h"
#import "SFTDataFlowLogger.h"
#import "SFTDocument.h"

NSString *SFTDataFlowEntryDirectionToGlyphTransformerName =
    @"SFTDataFlowEntryDirectionToGlyphTransformer";

@interface SFTDataFlowEntryDirectionToGlyphTransformer : NSValueTransformer

@end

@implementation SFTDataFlowEntryDirectionToGlyphTransformer

+ (Class)transformedValueClass {
  return NSString.class;
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  NSString *result = nil;
  if ((value != nil) && [value isKindOfClass:NSNumber.class]) {
    if ((SFTDataPacketDirection)((NSNumber *)value).integerValue ==
        SFTDataPacketDirectionInbound) {
      result = @"←";
    } else {
      result = @"→";
    }
  }

  return result;
}

@end

@interface SFTDataFlowInspectorWindowController ()

@property(weak) IBOutlet NSTableView *packetsTable;
@property(strong, nonatomic, nonnull) id<NSObject> changedNotificationObserver;
@property(strong) IBOutlet NSObjectController *packetLoggerController;

@end

@implementation SFTDataFlowInspectorWindowController

- (void)windowDidLoad {
  [super windowDidLoad];

  __weak SFTDataFlowInspectorWindowController *weakSelf = self;
  self.changedNotificationObserver = [NSNotificationCenter.defaultCenter
      addObserverForName:SFTDataFlowLoggerChangedNotificationName
                  object:nil
                   queue:nil
              usingBlock:^(NSNotification *_Nonnull __unused note) {
                SFTDataFlowInspectorWindowController *strongSelf = weakSelf;
                (strongSelf.packetLoggerController).content =
                    [strongSelf.document packetLogger].packets;
                [strongSelf.packetsTable reloadData];
              }];
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter
      removeObserver:self.changedNotificationObserver
                name:SFTDataFlowLoggerChangedNotificationName
              object:nil];
}

+ (nonnull instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static SFTDataFlowInspectorWindowController *instance;
  dispatch_once(&onceToken, ^{
    instance = [[SFTDataFlowInspectorWindowController alloc]
        initWithWindowNibName:@"DataFlowInspector"];
  });

  return instance;
}

@end
