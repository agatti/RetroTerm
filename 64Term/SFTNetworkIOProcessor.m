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

#import "SFTNetworkIOProcessor.h"
#import "SFTCommon.h"

#include <mach/mach.h>

#define NETWORK_READ_BUFFER_SIZE 512
#define NETWORK_WRITE_BUFFER_SIZE 64

static const NSUInteger kNetworkReadBufferSize = 512;
static const NSUInteger kNetworkWriteBufferSize = 64;

@class SFTNetworkIOProcessor;
@class SFTNetworkBackgroundThread;

@interface SFTNetworkIOProcessor () <NSStreamDelegate>

@property(strong, nonatomic, nonnull)
    SFTNetworkBackgroundThread *backgroundThread;
@property(strong, nonatomic, nonnull) NSURL *url;

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url;
- (void)backgroundThreadReceivedData:(nonnull NSData *)data;
- (void)backgroundThreadDisconnected;

@end

@interface SFTNetworkBackgroundThread : NSThread <NSStreamDelegate>

@property(strong, nonatomic, nonnull)
    NSMutableArray<NSData *> *outputBacklogQueue;

@property(strong, nonatomic, nonnull) NSInputStream *inputStream;
@property(strong, nonatomic, nonnull) NSOutputStream *outputStream;
@property(strong, nonatomic, nonnull) NSPort *port;

@property(assign, atomic) BOOL running;

@property(weak, nonatomic) SFTNetworkIOProcessor *processor;

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url
                     usingProcessor:(nonnull SFTNetworkIOProcessor *)processor;
- (void)readDataFromStream;
- (void)writeDataToStream;
- (void)disconnected;

- (void)enqueueBuffer:(nonnull NSData *)buffer;

@end

@implementation SFTNetworkBackgroundThread

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url
                     usingProcessor:(nonnull SFTNetworkIOProcessor *)processor {
  self = [super init];
  if (self != nil) {
    _port = [NSPort port];
    _outputBacklogQueue = [NSMutableArray<NSData *> new];

    NSInputStream *input;
    NSOutputStream *output;

    [NSStream getStreamsToHostWithName:url.host
                                  port:url.port.unsignedShortValue
                           inputStream:&input
                          outputStream:&output];

    _inputStream = input;
    _outputStream = output;

    _inputStream.delegate = self;
    _outputStream.delegate = self;

    _running = NO;

    _processor = processor;
  }

  return self;
}

- (void)main {
  self.running = YES;

  [self.port scheduleInRunLoop:NSRunLoop.currentRunLoop
                       forMode:NSDefaultRunLoopMode];

  [self.inputStream scheduleInRunLoop:NSRunLoop.currentRunLoop
                              forMode:NSDefaultRunLoopMode];
  [self.outputStream scheduleInRunLoop:NSRunLoop.currentRunLoop
                               forMode:NSDefaultRunLoopMode];

  [self.inputStream open];
  [self.outputStream open];

  while (self.running == YES) {
    if ([NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
                               beforeDate:NSDate.distantFuture] == NO) {
      break;
    }
  }

  [self.port removeFromRunLoop:NSRunLoop.currentRunLoop
                       forMode:NSDefaultRunLoopMode];

  [self.outputStream close];
  [self.outputStream removeFromRunLoop:NSRunLoop.currentRunLoop
                               forMode:NSDefaultRunLoopMode];
  self.outputStream.delegate = nil;

  [self.inputStream close];
  [self.inputStream removeFromRunLoop:NSRunLoop.currentRunLoop
                              forMode:NSDefaultRunLoopMode];
  self.inputStream.delegate = nil;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
  if (aStream == self.inputStream) {
    [self handleStreamInEvent:eventCode];
    return;
  }

  if (aStream == self.outputStream) {
    [self handleStreamOutEvent:eventCode];
    return;
  }
}

- (void)disconnected {
  [self.processor
      performSelectorOnMainThread:@selector(backgroundThreadDisconnected)
                       withObject:nil
                    waitUntilDone:YES];
}

- (void)readDataFromStream {
  uint8_t buffer[NETWORK_READ_BUFFER_SIZE];

  NSInteger bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
  switch (bytesRead) {
  case -1:
    // Error
    return;

  case 0:
    // Nothing
    return;

  default:
    break;
  }

  [self.processor
      performSelectorOnMainThread:@selector(backgroundThreadReceivedData:)
                       withObject:[NSData dataWithBytes:buffer
                                                 length:(NSUInteger)bytesRead]
                    waitUntilDone:YES];
}

- (void)handleStreamInEvent:(NSStreamEvent)event {
  switch (event) {
  case NSStreamEventNone:
    break;

  case NSStreamEventOpenCompleted:
    break;

  case NSStreamEventHasBytesAvailable:
    [self readDataFromStream];
    break;

  case NSStreamEventHasSpaceAvailable:
    break;

  case NSStreamEventErrorOccurred:
    break;

  case NSStreamEventEndEncountered:
    [self disconnected];
    self.running = NO;
    break;
  }
}

- (void)writeDataToStream {
  BOOL canLoop = YES;

  while (canLoop) {
    if (!(self.outputStream).hasSpaceAvailable ||
        self.outputBacklogQueue.count == 0) {
      canLoop = NO;
      continue;
    }

    NSData *item = self.outputBacklogQueue.firstObject;
    NSInteger bytesWritten =
        [self.outputStream write:item.bytes
                       maxLength:(kNetworkWriteBufferSize < item.length)
                                     ? kNetworkReadBufferSize
                                     : item.length];
    switch (bytesWritten) {
    case -1:
      // Error
      return;

    case 0:
      // Nothing
      return;

    default:
      break;
    }

    if ((NSUInteger)bytesWritten >= item.length) {
      [self.outputBacklogQueue removeObjectAtIndex:0];
    } else {
      (self.outputBacklogQueue)[0] = [item
          subdataWithRange:NSMakeRange((NSUInteger)bytesWritten,
                                       item.length - (NSUInteger)bytesWritten)];
    }
  }
}

- (void)handleStreamOutEvent:(NSStreamEvent)event {
  switch (event) {
  case NSStreamEventNone:
    break;

  case NSStreamEventOpenCompleted:
    break;

  case NSStreamEventHasBytesAvailable:
    break;

  case NSStreamEventHasSpaceAvailable:
    [self writeDataToStream];
    break;

  case NSStreamEventErrorOccurred:
    break;

  case NSStreamEventEndEncountered:
    [self disconnected];
    self.running = NO;
    break;
  }
}

- (void)enqueueBuffer:(nonnull NSData *)buffer {
  [self.outputBacklogQueue addObject:buffer];
  [self writeDataToStream];
}

- (void)handlePortMessage:(NSPortMessage *)message {
  [self.outputBacklogQueue addObject:message.components[0]];
  [self writeDataToStream];
}

@end

@implementation SFTNetworkIOProcessor

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url {
  self = [super init];
  if (self != nil) {
    _url = url;
  }

  return self;
}

+ (BOOL)parseAddress:(nonnull NSString *)address
        intoHostName:(NSString *_Nonnull *_Nullable)hostName
             andPort:(nonnull NSUInteger *)port {
  *hostName = nil;
  *port = 0;
  NSArray<NSString *> *items = [address componentsSeparatedByString:@":"];
  switch (items.count) {
  case 1:
    *hostName = items[0];
    *port = SFTDefaultPort;
    break;

  case 2:
    *hostName = items[0];
    *port = (NSUInteger)items[1].integerValue;
    break;

  default:
    return NO;
  }

  return YES;
}

+ (nullable instancetype)networkIOProcessorWithURL:(nonnull NSURL *)url {
  return [[SFTNetworkIOProcessor alloc] initWithURL:url];
}

- (void)start {
  self.backgroundThread =
      [[SFTNetworkBackgroundThread alloc] initWithURL:self.url
                                       usingProcessor:self];
  self.backgroundThread.name = @"SFTNetworkIOProcessorBackgroundThread";
  [self.backgroundThread start];
}

- (void)sendData:(nonnull NSData *)data {
  [self.backgroundThread performSelector:@selector(enqueueBuffer:)
                                onThread:self.backgroundThread
                              withObject:data
                           waitUntilDone:YES];
}

- (void)stop {
  if (self.backgroundThread.running == NO) {
    return;
  }

  self.backgroundThread.running = NO;
  [self.backgroundThread.port sendBeforeDate:NSDate.distantPast
                                  components:[NSMutableArray new]
                                        from:nil
                                    reserved:0];
  while (self.backgroundThread.isExecuting) {
    if ([NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
                               beforeDate:NSDate.distantFuture] == NO) {
      break;
    }
  }
}

- (void)backgroundThreadReceivedData:(NSData *)data {
  [self.delegate ioProcessor:self
               receivedEvent:SFTIOProcessorEventReceivedData
                    withData:data];
}

- (void)backgroundThreadDisconnected {
  [self.delegate ioProcessor:self
               receivedEvent:SFTIOProcessorEventDisconnected
                    withData:nil];
}

@end
