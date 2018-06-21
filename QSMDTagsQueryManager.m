//
//  QSMDTagsQueryManager.m
//  QSFileTagsPlugIn
//
//  Created by Etienne on 11/09/08.
//  Copyright 2008 Etienne Samson. All rights reserved.
//

#import "QSMDTagsQueryManager.h"

static QSMDTagsQueryManager *defaultQueryManager = nil;

@implementation QSObject (QSFileTagsHandling)
+ (QSObject *)objectForTag:(NSString *)tag {
	return [self objectWithType:QSFileTagType value:tag name:[[QSMDTagsQueryManager sharedInstance] stringByRemovingTagPrefix:tag]]; 	
}

@end

@implementation QSMDTagsQueryManager

+ (id)sharedInstance {
    if (!defaultQueryManager)
        defaultQueryManager = [[QSMDTagsQueryManager alloc] init];
    return defaultQueryManager;
}

#pragma mark NSMetadataQueries Management
- (NSArray *)tagsFromQuery:(NSMetadataQuery *)aQuery {	
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *commentEnum = [[[aQuery results] valueForKey:(NSString *)kMDItemFinderComment] objectEnumerator];
	NSString *comment;
	while(comment = [commentEnum nextObject]) {
		for(NSString * word in [comment componentsSeparatedByString:@" "]) {
			if ([word hasPrefix:gTagPrefix])
				[set addObject:word];
		}
	}
	return [set allObjects];
}

- (NSArray *)filesWithTag:(NSString*)tag fromQuery:(NSMetadataQuery *)aQuery {	
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *resultsEnum = [[aQuery results] objectEnumerator];
	NSMetadataItem *result;
	while(result = [resultsEnum nextObject]) {
        NSString *name = [result valueForAttribute:(NSString *)kMDItemPath];
        NSString *comment = [result valueForAttribute:(NSString *)kMDItemFinderComment];
		for(NSString * word in [comment componentsSeparatedByString:@" "]) {
			if ([word isEqualToString:tag])
				[set addObject:name];
		}
	}
	return [set allObjects];
}

#pragma mark Quicksilver accessors
- (NSArray*)tagsWithTagPrefix:(NSString*)tagPrefix {
    NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
    NSArray *objects = nil;
	NSString *string = [NSString stringWithFormat:@"kMDItemFinderComment LIKE[cd] '*%@*'", tagPrefix];
    [query resultsForSearchString:string];
    if ([query resultCount] != 0) {
        objects = [self tagsFromQuery:query];
    }
    [query release];
    return objects;
}

- (NSArray*)filesForTag:(NSString*)tag {
    NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
    NSArray *objects = nil;
	NSString *string = [NSString stringWithFormat:@"kMDItemFinderComment LIKE[cd] '*%@*'", tag];
    [query resultsForSearchString:string];
    if ([query resultCount] != 0) {
        objects = [self filesWithTag:tag fromQuery:query];
    }
    [query release];
    return objects;
}

- (NSArray*)filesForTags:(NSArray*)tags {
    NSMutableSet * files = nil;
    for(NSString * tag in tags) {
        NSArray *tempArray = [self filesForTag:tag];
        if (tempArray) {
            files = [NSMutableSet setWithCapacity:[tempArray count]];
            [files addObjectsFromArray:tempArray];
        }
    }
    return [files allObjects];
}

#pragma mark NSString additions
- (NSString *)stringByAddingTagPrefix:(NSString *)tag {
    NSString *string = tag;
	if (![tag hasPrefix:gTagPrefix])
		string = [gTagPrefix stringByAppendingString:tag];
	return string;
}

- (NSString *)stringByRemovingTagPrefix:(NSString *)tag {
    NSString *string = tag;
	if ([tag hasPrefix:gTagPrefix]) {
		string = [tag substringFromIndex:[gTagPrefix length]];
		return string;
	}
	return nil;
}

@end
