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

#import "SFTPlaybackIOProcessor.h"

@interface SFTPlaybackIOProcessor ()

@property(strong, nonatomic, nullable) NSData *replayData;
@property(strong, nonatomic, nullable) NSTimer *replayTimer;
@property(assign, nonatomic) NSUInteger replayDataOffset;

@end

@implementation SFTPlaybackIOProcessor

- (void)injectSessionDataFromURL:(nonnull NSURL *)url
                  withSpeedInBps:(NSUInteger)speed {
  if ((self.replayTimer != nil) && (self.replayTimer.valid == YES)) {
    [self.replayTimer invalidate];
  }

  self.replayData = [NSData dataWithContentsOfURL:url];
  self.replayDataOffset = 0;
  NSTimeInterval interval = (NSTimeInterval)(1.0 / ((NSTimeInterval)speed / 8));

  __weak SFTPlaybackIOProcessor *weakSelf = self;
  self.replayTimer = [NSTimer
      scheduledTimerWithTimeInterval:interval
                             repeats:YES
                               block:^(NSTimer *_Nonnull timer) {
                                 SFTPlaybackIOProcessor *strongSelf = weakSelf;
                                 if (strongSelf.replayDataOffset >=
                                     strongSelf.replayData.length) {
                                   [strongSelf.replayTimer invalidate];
                                   return;
                                 }

                                 uint8_t byte =
                                     ((const uint8_t *)(strongSelf.replayData
                                                            .bytes))
                                         [strongSelf.replayDataOffset];
                                 [strongSelf.delegate
                                       ioProcessor:self
                                     receivedEvent:
                                         SFTIOProcessorEventReceivedData
                                          withData:[NSData
                                                       dataWithBytesNoCopy:&byte
                                                                    length:1
                                                              freeWhenDone:NO]];
                                 strongSelf.replayDataOffset++;
                               }];
}

- (void)start {
}

- (void)stop {
  [self.replayTimer invalidate];
}

- (void)sendData:(nonnull NSData *)data {
  [self.delegate ioProcessor:self
               receivedEvent:SFTIOProcessorEventReceivedData
                    withData:data];
}

@end
