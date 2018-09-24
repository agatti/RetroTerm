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
@import MetalKit;

#import "SFTAddressBookEntry+CoreDataClass.h"
#import "SFTDataFlowLogger.h"

@interface SFTDocument : NSDocument

@property(strong, nonatomic, nullable) SFTAddressBookEntry *entry;
@property(strong, nonatomic, nullable) NSURL *address;
@property(strong, nonatomic, nullable) NSEvent *lastKeyEvent;
@property(assign, nonatomic) BOOL filterKeypresses;
@property(assign, nonatomic) BOOL logPackets;
@property(strong, nonatomic, nonnull) SFTDataFlowLogger *packetLogger;
@property(assign, nonatomic) NSInteger selectionStart;
@property(assign, nonatomic) NSInteger selectionEnd;
@property(assign, nonatomic) BOOL hasBackingEntry;
@property(assign, nonatomic) NSInteger pointerPosition;
@property(assign, nonatomic, readonly) NSRange selectionRange;

/**
 * Buffer containing a SFTShaderContext instance to pass information data to
 * the GPU via Metal uniforms.
 */
@property(strong, nonatomic, nonnull) id<MTLBuffer> shaderContext;

/**
 * Buffer containing a list of SFTTerminalEmulatorCell instances that represent
 * the screen contents.
 */
@property(strong, nonatomic, nonnull) id<MTLBuffer> screenContents;

- (nonnull instancetype)initWithEntry:(nonnull SFTAddressBookEntry *)entry
                                error:(NSError *_Nonnull *_Nullable)error;

- (nonnull instancetype)initWithAddress:(nonnull NSURL *)address
                                  error:(NSError *_Nonnull *_Nullable)error;

@property(NS_NONATOMIC_IOSONLY, readonly, copy)
    NSData *_Nonnull rawContentsBuffer;

- (void)setSelectionRangeFromIndex:(NSUInteger)startIndex
                           toIndex:(NSUInteger)endIndex;
- (void)setSelectionRangeStart:(NSUInteger)start;
- (void)setSelectionRangeEnd:(NSUInteger)end;

@end
