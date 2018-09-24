//
//  SFTAddressBookEntry+CoreDataProperties.h
//  RetroTerm
//
//  Created by Alessandro Gatti on 24/09/2018.
//  Copyright © 2018 Alessandro Gatti. All rights reserved.
//
//

#import "SFTAddressBookEntry+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface SFTAddressBookEntry (CoreDataProperties)

+ (NSFetchRequest<SFTAddressBookEntry *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSURL *address;
@property (nullable, nonatomic, retain) NSData *image;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *notes;

@end

NS_ASSUME_NONNULL_END
