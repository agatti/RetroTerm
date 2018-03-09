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

#import "MTKView+Screenshot.h"

@implementation MTKView (Screenshot)

// @TODO: Maybe this should be in MTLTexture?

- (nullable NSImage *)screenshot {
  if (self.framebufferOnly) {
    return nil;
  }

  id<MTLTexture> texture = self.currentDrawable.texture;
  NSMutableData *buffer =
      [NSMutableData dataWithLength:texture.width * texture.height * 4];
  [texture getBytes:buffer.mutableBytes
        bytesPerRow:texture.width * 4
         fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height)
        mipmapLevel:0];

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;

  CGDataProviderRef provider =
      CGDataProviderCreateWithData(nil, buffer.bytes, buffer.length, nil);
  CGImageRef cgImage =
      CGImageCreate(texture.width, texture.height, 8, 32, texture.width * 4,
                    colorSpace, bitmapInfo, provider, nil, true,
                    (CGColorRenderingIntent)kCGRenderingIntentDefault);
  NSBitmapImageRep *representation =
      [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
  representation.size =
      NSMakeSize(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));

  NSImage *image = [[NSImage alloc] initWithSize:representation.size];
  [image addRepresentation:representation];
  CFRelease(cgImage);
  CFRelease(colorSpace);
  CFRelease(provider);

  return image;
}

@end
