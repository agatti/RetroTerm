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
@import Foundation;

typedef NS_ENUM(NSUInteger, SFTDataPacketDirection) {
  SFTDataPacketDirectionInbound,
  SFTDataPacketDirectionOutbound
};

extern NSNotificationName _Nonnull SFTDataFlowLoggerChangedNotificationName;

@interface SFTDataFlowLogEntry : NSObject

@property(assign, nonatomic) NSTimeInterval unixTimestamp;
@property(assign, nonatomic) SFTDataPacketDirection direction;
@property(strong, nonatomic, nonnull) NSData *contents;

+ (nonnull instancetype)dataFlowLogEntryWithBytes:(nonnull NSData *)bytes
                                     andDirection:
                                         (SFTDataPacketDirection)direction;

@end

@interface SFTDataFlowLogger
    : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property(strong, nonatomic, nonnull)
    NSMutableArray<SFTDataFlowLogEntry *> *packets;

- (void)appendEntry:(nonnull SFTDataFlowLogEntry *)entry;
- (void)clear;

@end
