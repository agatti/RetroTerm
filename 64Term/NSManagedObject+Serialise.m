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

// Adapted from https://gist.github.com/pkclsoft/4958148

#import "NSManagedObject+Serialise.h"

#define DATE_ATTR_PREFIX @"_date_attr_:"

static NSDictionary *traverseHistory(NSManagedObject *object,
                                     NSMutableArray *history);
static id decodeValue(id codedValue, NSString *key);

@implementation NSManagedObject (Serialise)

- (NSDictionary *)serialise {
  return traverseHistory(self, nil);
}

- (void)populate:(NSDictionary *)serialised {
  NSManagedObjectContext *context = self.managedObjectContext;

  for (NSString *key in serialised) {
    if ([key isEqualToString:@"class"]) {
      continue;
    }

    NSObject *value = serialised[key];

    if ([value isKindOfClass:NSDictionary.class]) {
      NSManagedObject *relatedObject = [NSManagedObject
          createManagedObjectFromSerialisation:(NSDictionary *)value
                                     inContext:context];

      [self setValue:relatedObject forKey:key];
      continue;
    }

    if ([value isKindOfClass:NSArray.class]) {
      NSArray *relatedObjectDictionaries = (NSArray *)value;
      NSMutableSet *relatedObjects = [self mutableSetValueForKey:key];

      for (NSDictionary *relatedObjectDict in relatedObjectDictionaries) {
        NSManagedObject *relatedObject = [NSManagedObject
            createManagedObjectFromSerialisation:relatedObjectDict
                                       inContext:context];
        [relatedObjects addObject:relatedObject];
      }
      continue;
    }

    if (value != nil) {
      [self setValue:decodeValue(value, key)
              forKey:[key stringByReplacingOccurrencesOfString:DATE_ATTR_PREFIX
                                                    withString:@""]];
    }
  }
}

+ (NSManagedObject *)
createManagedObjectFromSerialisation:(NSDictionary *)serialisation
                           inContext:(NSManagedObjectContext *)context {
  NSString *class = serialisation[@"class"];

  NSManagedObject *newObject =
      [NSEntityDescription insertNewObjectForEntityForName:class
                                    inManagedObjectContext:context];

  [newObject populate:serialisation];

  return newObject;
}

@end

id decodeValue(id codedValue, NSString *key) {
  if ([key hasPrefix:DATE_ATTR_PREFIX]) {
    NSTimeInterval dateAttr = ((NSNumber *)codedValue).doubleValue;
    return [NSDate dateWithTimeIntervalSinceReferenceDate:dateAttr];
  }

  return codedValue;
}

NSDictionary *traverseHistory(NSManagedObject *object,
                              NSMutableArray *history) {
  NSArray *attributes = object.entity.attributesByName.allKeys;
  NSArray *relationships = object.entity.relationshipsByName.allKeys;
  NSMutableDictionary *result = [NSMutableDictionary
      dictionaryWithCapacity:attributes.count + relationships.count + 1];

  NSMutableArray *localTraversalHistory =
      history == nil
          ? [NSMutableArray
                arrayWithCapacity:attributes.count + relationships.count + 1]
          : history;

  [localTraversalHistory addObject:object];
  result[@"class"] = [[object class] description];

  for (NSString *attr in attributes) {
    NSObject *value = [object valueForKey:attr];

    if (value != nil) {
      if ([value isKindOfClass:NSDate.class]) {
        NSTimeInterval date = ((NSDate *)value).timeIntervalSinceReferenceDate;
        NSString *dateAttr =
            [NSString stringWithFormat:@"%@%@", DATE_ATTR_PREFIX, attr];
        result[dateAttr] = @(date);
      } else {
        result[attr] = value;
      }
    }
  }

  for (NSString *relationship in relationships) {
    NSObject *value = [object valueForKey:relationship];

    if ([value isKindOfClass:NSSet.class]) {
      NSSet *relatedObjects = (NSSet *)value;
      NSMutableArray *dictSet =
          [NSMutableArray arrayWithCapacity:relatedObjects.count];

      for (NSManagedObject *relatedObject in relatedObjects) {
        if (![localTraversalHistory containsObject:relatedObject]) {
          [dictSet
              addObject:traverseHistory(relatedObject, localTraversalHistory)];
        }
      }

      result[relationship] = [NSArray arrayWithArray:dictSet];
      continue;
    }

    if ([value isKindOfClass:NSManagedObject.class]) {
      NSManagedObject *relatedObject = (NSManagedObject *)value;
      if (![localTraversalHistory containsObject:relatedObject]) {
        result[relationship] =
            traverseHistory(relatedObject, localTraversalHistory);
      }
    }
  }

  if (history == nil) {
    [localTraversalHistory removeAllObjects];
  }

  return result;
}
