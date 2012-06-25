//
//  QSSpotlightPlugIn_Action.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 10/28/04.
//  Updated by Rob McBroom on 2012/06/13.
//

#import "QSSpotlightPlugIn_Action.h"

// Allow us to bind to the icon of a NSMetadataItem by extending it
@implementation NSMetadataItem (ItemExtras)

- (NSImage *)icon
{
	NSString *path = [self valueForKey:(id)kMDItemPath];
	return [[NSWorkspace sharedWorkspace] iconForFile:path];
}

- (NSString *)displayName
{
	return [self valueForAttribute:(NSString *)kMDItemDisplayName];
}

+ (NSMetadataItem *)itemWithPath:(NSString *)path
{
	MDItemRef ref = MDItemCreate(NULL, (CFStringRef)path);
	[[[self alloc]_init:ref] autorelease];
	return nil;
}

@end

@implementation QSSpotlightPlugIn_Action

#pragma mark - Quicksilver Actions

- (QSObject *)internalSpotlightSearchForString:(QSObject *)dObject
{
	[self displayObjectsForSearch:[dObject stringValue] inFolders:nil];
	return nil;
}

- (QSObject *)finderSpotlightSearchForString:(QSObject *)dObject
{
	NSString *query = [dObject stringValue];
	[self runQueryInFinder:query name:query scope:nil];
	return nil;
}
	
- (QSObject *)spotlightSearchForString:(QSObject *)dObject
{
	OSStatus resultCode = noErr;
	resultCode = HISearchWindowShow((CFStringRef)[dObject stringValue], kNilOptions);
	if (resultCode != noErr) {
		// failed to open the panel
		// present an error to the user
	}
	return nil;
}

- (QSObject *)spotlightSearchInFolder:(QSObject *)dObject forString:(QSObject *)iObject
{
	NSSet *searchScope = [NSSet setWithObject:[dObject singleFilePath]];
	[self displayObjectsForSearch:[iObject stringValue] inFolders:searchScope];
	return nil;
}

- (QSObject *)spotlightSearchFinderInFolder:(QSObject *)dObject forString:(QSObject *)iObject
{
	NSString *query = [iObject stringValue];
	[self runQueryInFinder:query name:query scope:[dObject singleFilePath]];
	return nil;
}

- (QSObject *)spotlightSearchFilenamesInFolder:(QSObject *)dObject forString:(QSObject *)iObject
{
	NSString *path = [dObject singleFilePath];
	NSString *query = [NSString stringWithFormat:@"kMDItemFSName LIKE[cd] '%@*'", [iObject stringValue]];
	[self displayObjectsForSearch:query inFolders:[NSSet setWithObject:path]];
	return nil;
}

#pragma mark - Quicksilver Validation

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject
{
	NSString *searchString = [[NSPasteboard pasteboardWithName:NSFindPboard] stringForType:NSStringPboardType];
	QSObject *textObject = [QSObject textProxyObjectWithDefaultValue:searchString];
	return [NSArray arrayWithObject:textObject];
}

#pragma mark - Helper Methods

// See https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/Predicates/Articles/pSpotlightComparison.html for a discussion of the different styles

- (NSString *)trueQueryFor:(NSString *)query
{
	if ([query rangeOfString:@"kMD"].location == NSNotFound) {
		// turn simple string into a query (NSPredicate style)
		return [NSString stringWithFormat:@"kMDItemFSName LIKE[cd] '%@*' || kMDItemFinderComment LIKE[cd] '*%@*' || kMDItemTextContent LIKE[cd] '%@*'", query, query, query];
	} else {
		// this is a Spotlight query - pass it along untouched
		return query;
	}
}

- (NSString *)savedSearchQueryFor:(NSString *)query
{
	if ([query rangeOfString:@"kMD"].location == NSNotFound) {
		// turn simple string into a query (Spotlight style)
		return [NSString stringWithFormat:@"(((* = '%@*'cdw || kMDItemTextContent = '%@*'cdw))) && (true)", query, query];
	} else {
		// this is a Spotlight query - pass it along untouched
		return query;
	}
}

- (void)runQueryInFinder:(NSString *)query name:(NSString *)name scope:(NSString *)scope
{
	if (!name) {
		name = query;
	}
	query = [self savedSearchQueryFor:query];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"ToolbarVisible"] forKey:@"ViewOptions"];
	[dict setObject:[NSNumber numberWithInteger:0] forKey:@"CompatibleVersion"];
	[dict setObject:query forKey:@"RawQuery"];
	
	NSMutableDictionary *criteria = [NSMutableDictionary dictionary];
	[criteria setObject:name forKey:@"AnyAttributeContains"];
	if (scope) {
		[criteria setObject:[NSArray arrayWithObject:scope] forKey:@"FXScopeArrayOfPaths"];
	}
	[dict setObject:criteria forKey:@"SearchCriteria"];
	
	NSMutableString *filename = [[name mutableCopy] autorelease];
	[filename replaceOccurrencesOfString:@"/" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [filename length])];
	if ([filename length] > 242) {
		filename = (NSMutableString *)[filename substringToIndex:242];
	}
	[filename appendString:@".savedSearch"];
	filename = (NSMutableString *)[NSTemporaryDirectory() stringByAppendingPathComponent:filename];
	[dict writeToFile:filename atomically:NO];
	[[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden] ofItemAtPath:filename error:nil];
	[[NSWorkspace sharedWorkspace] openFile:filename];
}

- (void)displayObjectsForSearch:(NSString *)search inFolders:(NSSet *)scope
{
	NSString *queryString = [self trueQueryFor:search];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:1];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:results, kQSResultArrayKey, nil];
	NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
	// let the user know results are being collected
	QSObject *searching = [QSObject makeObjectWithIdentifier:@"QSSearchPending"];
	// pretty names sometimes require ugly hacks
	search = [search stringByReplacingOccurrencesOfString:@"kMDItemFSName LIKE[cd]" withString:@"file names like"];
	[searching setName:[NSString stringWithFormat:@"Searching for \"%@\"...", search]];
	[searching setIcon:[QSResourceManager imageNamed:@"Find"]];
	[results addObject:searching];
	[dc postNotificationName:@"QSSourceArrayCreated" object:self userInfo:userInfo];
	NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
	[results removeObject:searching];
	@try {
		[query resultsForSearchString:queryString inFolders:scope];
		NSString *resultPath = nil;
		// fast enumeration is not recommended for NSMetadataQuery
		for (NSUInteger i = 0; i < [query resultCount]; i++) {
			// get the path and create a QSObject with it
			resultPath = [[query resultAtIndex:i] valueForAttribute:@"kMDItemPath"];
			[results addObject:[QSObject fileObjectWithPath:resultPath]];
		}
	}
	@catch (NSException *exception) {
		if ([[exception name] isEqualToString:@"NSInvalidArgumentException"]) {
			NSLog(@"invalid syntax for Spotlight search: %@", queryString);
			QSObject *error = [QSObject objectWithString:@"Search Failed"];
			[error setDetails:[NSString stringWithFormat:@"Invalid syntax: %@", queryString]];
			[error setIcon:[QSResourceManager imageNamed:@"AlertStopIcon"]];
			[results addObject:error];
		} else {
			NSLog(@"Spotlight search failed: %@", exception);
		}
	}
	[query release];
	query = nil;
	[dc postNotificationName:@"QSSourceArrayUpdated" object:self userInfo:userInfo];
}

@end
