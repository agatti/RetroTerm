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

@import CoreData;
@import Foundation;

/**
 * Address book serialisation methods host object.
 */
@interface SFTAddressBookSerialiser : NSObject

/**
 * Serialises all managed objects contained in the given context into the
 * given data buffer.
 *
 * @param context the managed context containing the objects to serialise.
 * @param data the container that will hold the serialised data.
 * @param error a reference to an error container that will be filled if
 * anything goes wrong.
 *
 * @return YES if the serialisation process succeeded, NO otherwise.
 */
+ (BOOL)serialise:(nonnull NSManagedObjectContext *)context
         intoData:(nonnull NSMutableData *)data
        withError:(NSError *_Nullable __autoreleasing *_Nonnull)error;

/**
 * Deserialises all objects contained in the given data into the given data
 * holding context.
 *
 * @param context the managed context that will contain the desrialised objects.
 * @param data the container that holds the serialised data.
 * @param error a reference to an error container that will be filled if
 * anything goes wrong.
 *
 * @return YES if the deserialisation process succeeded, NO otherwise.
 */
+ (BOOL)deserialise:(nonnull NSManagedObjectContext *)context
           fromData:(nonnull NSData *)data
          withError:(NSError *_Nullable __autoreleasing *_Nonnull)error;

@end
