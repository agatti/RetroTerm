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

@import Foundation;

extern NSExceptionName SFTMetalException;
extern NSExceptionName SFTMemoryException;
extern NSExceptionName SFTInternalErrorException;

extern NSErrorDomain SFTErrorDomain;

extern const NSUInteger SFTViewColumns;
extern const NSUInteger SFTViewRows;
extern const NSUInteger SFTViewSize;

typedef NS_ENUM(NSUInteger, SFTC64Colour) {
  SFTC64ColourBlack = 0,
  SFTC64ColourWhite,
  SFTC64ColourRed,
  SFTC64ColourCyan,
  SFTC64ColourPurple,
  SFTC64ColourGreen,
  SFTC64ColourBlue,
  SFTC64ColourYellow,
  SFTC64ColourOrange,
  SFTC64ColourBrown,
  SFTC64ColourLightRed,
  SFTC64ColourDarkGray,
  SFTC64ColourMiddleGray,
  SFTC64ColourLightGreen,
  SFTC64ColourLightBlue,
  SFTC64ColourLightGray
};

typedef NS_ENUM(NSInteger, SFTUserInterfaceTag) {
  SFTUserInterfaceTagMenuConnection = 1,
  SFTUserInterfaceTagMenuDebug,
  SFTUserInterfaceTagMenuDebugSessionReplayMenuItem
};

typedef NS_ENUM(NSInteger, SFTErrorDomainCodes) {
  SFTErrorCannotUnarchiveSerialisedAddressBook = -1,
  SFTErrorInvalidUnarchivedItemClass = -2,
  SFTErrorCannotCreateManagedObjectFromUnarchivedItem = -3
};

extern const NSUInteger SFTDefaultPort;
extern NSString *SFTDefaultScheme;
