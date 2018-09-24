//
//  SFTAddressBookEntry+CoreDataProperties.m
//  RetroTerm
//
//  Created by Alessandro Gatti on 24/09/2018.
//  Copyright © 2018 Alessandro Gatti. All rights reserved.
//
//

#import "SFTAddressBookEntry+CoreDataProperties.h"

@implementation SFTAddressBookEntry (CoreDataProperties)

+ (NSFetchRequest<SFTAddressBookEntry *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"SFTAddressBookEntry"];
}

@dynamic address;
@dynamic image;
@dynamic name;
@dynamic notes;

@end
