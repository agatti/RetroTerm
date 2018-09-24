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

#import "SFTAddressBookSerialiser.h"
#import "SFTCommon.h"

#import "NSManagedObject+Serialise.h"

/**
 * Address mode entry entity name for the Core Data stack.
 */
static NSString *kEntityName = @"SFTAddressBookEntry";

/**
 * The sorting key to use for serialising entity objects.
 */
static NSString *kEntitySortKey = @"name";

/**
 * Root key name for the serialised entity tree.
 */
static NSString *kRootKey = @"addressBook";

@implementation SFTAddressBookSerialiser

+ (BOOL)serialise:(nonnull NSManagedObjectContext *)context
         intoData:(nonnull NSMutableData *)data
        withError:(NSError *_Nullable __autoreleasing *_Nonnull)error {

  NSError *innerError;
  NSFetchRequest *fetchRequest =
      [NSFetchRequest fetchRequestWithEntityName:kEntityName];
  fetchRequest.sortDescriptors =
      @[ [[NSSortDescriptor alloc] initWithKey:kEntitySortKey ascending:YES] ];
  NSArray *fetchedObjects =
      [context executeFetchRequest:fetchRequest error:&innerError];
  if (fetchedObjects == nil) {
    *error = innerError;
    return NO;
  }

  NSMutableArray *serialised =
      [NSMutableArray arrayWithCapacity:fetchedObjects.count];
  for (NSManagedObject *entry in fetchedObjects) {
    [serialised addObject:[entry serialise]];
  }

  data.length = 0;
  NSKeyedArchiver *archiver =
      [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  archiver.outputFormat = NSPropertyListXMLFormat_v1_0;
  archiver.requiresSecureCoding = YES;
  [archiver encodeObject:serialised forKey:kRootKey];
  [archiver finishEncoding];

  return YES;
}

+ (BOOL)deserialise:(nonnull NSManagedObjectContext *)context
           fromData:(nonnull NSData *)data
          withError:(NSError *_Nullable __autoreleasing *_Nonnull)error {

  NSKeyedUnarchiver *unarchiver =
      [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  unarchiver.decodingFailurePolicy = NSDecodingFailurePolicySetErrorAndReturn;
  unarchiver.requiresSecureCoding = YES;

  NSSet *classes = [NSSet
      setWithObjects:NSMutableArray.class, NSMutableDictionary.class, nil];
  id unarchived = [unarchiver decodeObjectOfClasses:classes forKey:kRootKey];
  [unarchiver finishDecoding];
  if (unarchiver.error != nil) {
    if (error != nil) {
      *error = unarchiver.error;
    }
    return NO;
  }

  if (![unarchived isKindOfClass:NSArray.class]) {
    if (error != nil) {
      *error =
          [NSError errorWithDomain:SFTErrorDomain
                              code:SFTErrorCannotUnarchiveSerialisedAddressBook
                          userInfo:nil];
    }
    return NO;
  }

  NSArray *unarchivedArray = (NSArray *)unarchived;
  for (id item in unarchivedArray) {
    if (![item isKindOfClass:NSDictionary.class]) {
      if (error != nil) {
        *error = [NSError errorWithDomain:SFTErrorDomain
                                     code:SFTErrorInvalidUnarchivedItemClass
                                 userInfo:nil];
      }
      return NO;
    }
  }

  NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc]
      initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  temporaryContext.parentContext = context;
  temporaryContext.retainsRegisteredObjects = YES;

  for (id item in unarchivedArray) {
    NSManagedObject *managedObject = [NSManagedObject
        createManagedObjectFromSerialisation:(NSDictionary *)item
                                   inContext:temporaryContext];
    if (managedObject == nil) {
      if (error != nil) {
        *error = [NSError
            errorWithDomain:SFTErrorDomain
                       code:SFTErrorCannotCreateManagedObjectFromUnarchivedItem
                   userInfo:nil];
      }
      return NO;
    }
  }

  NSError *innerError;

  if (temporaryContext.hasChanges && ![temporaryContext save:&innerError]) {
    *error = innerError;
    return NO;
  }

  return YES;
}

@end
