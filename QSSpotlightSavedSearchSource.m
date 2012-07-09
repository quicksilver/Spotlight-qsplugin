//
//  QSSpotlightSavedSearchSource.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 3/19/05.
//

#import "QSSpotlightSavedSearchSource.h"
#import "QSMDFindWrapper.h"

@implementation QSSpotlightSavedSearchSource

- (QSObject *)spotlightRunSavedQuery:(QSObject *)dObject
{
	NSString *path = [dObject singleFilePath];
	
	NSMutableArray *results = [[NSMutableArray alloc] init];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:results, kQSResultArrayKey, nil];
	NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
	// let the user know results are being collected
	QSObject *searching = [QSObject makeObjectWithIdentifier:@"QSSearchPending"];
	[searching setName:[NSString stringWithFormat:@"Searching in \"%@\"...", [dObject displayName]]];
	[searching setIcon:[QSResourceManager imageNamed:@"Find"]];
	[results addObject:searching];
	[dc postNotificationName:@"QSSourceArrayCreated" object:self userInfo:userInfo];
	[results removeObject:searching];
	[results addObjectsFromArray:[self targetArrayForSavedQueryAtPath:path]];
	[dc postNotificationName:@"QSSourceArrayUpdated" object:self userInfo:userInfo];
	[results release];
	return nil;
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
	NSString *path = [object singleFilePath];
	NSArray *results = [self targetArrayForSavedQueryAtPath:path];
	[object setChildren:results];
	return YES;
}

- (NSArray *)targetArrayForSavedQueryAtPath:(NSString *)path
{
	NSDictionary *search = [NSDictionary dictionaryWithContentsOfFile:path];
	NSString *predicateString = [search objectForKey:@"RawQuery"];
	//NSLog(@"original query: %@", predicateString);
	NSString *scope = [[search valueForKeyPath:@"SearchCriteria.FXScopeArrayOfPaths"] objectAtIndex:0];
	QSMDFindWrapper *wrap = [QSMDFindWrapper findWrapperWithQuery:predicateString path:scope keepalive:NO];
	NSArray *results = [wrap results];
	[wrap startQuery];
	return results;
}

@end
