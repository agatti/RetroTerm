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

#import "SFTDataFlowLogger.h"

NSNotificationName SFTDataFlowLoggerChangedNotificationName =
    @"SFTDataFlowLoggerChangedNotification";

@implementation SFTDataFlowLogEntry

+ (nonnull instancetype)dataFlowLogEntryWithBytes:(nonnull NSData *)bytes
                                     andDirection:
                                         (SFTDataPacketDirection)direction {
  SFTDataFlowLogEntry *entry = [[SFTDataFlowLogEntry alloc] init];
  entry.unixTimestamp = NSDate.date.timeIntervalSince1970;
  entry.direction = direction;
  entry.contents = bytes;

  return entry;
}

- (NSString *)description {
  return [NSString
      stringWithFormat:@"%f %@ %@", self.unixTimestamp,
                       self.direction == SFTDataPacketDirectionInbound ? @"<-"
                                                                       : @"->",
                       self.contents.description];
}

@end

@interface SFTDataFlowLogger ()

@end

@implementation SFTDataFlowLogger

- (nonnull instancetype)init {
  self = [super init];
  if (self != nil) {
    _packets = [[NSMutableArray alloc] init];
  }

  return self;
}

- (void)clear {
  [self.packets removeAllObjects];
  [NSNotificationCenter.defaultCenter
      postNotificationName:SFTDataFlowLoggerChangedNotificationName
                    object:nil];
}

- (void)appendEntry:(nonnull SFTDataFlowLogEntry *)entry {
  if (self.packets.count < NSIntegerMax) {
    [self.packets addObject:entry];
    [NSNotificationCenter.defaultCenter
        postNotificationName:SFTDataFlowLoggerChangedNotificationName
                      object:nil];
  }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return (NSInteger)self.packets.count;
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                          row:(NSInteger)row {
  return self.packets[(NSUInteger)row];
}

@end
