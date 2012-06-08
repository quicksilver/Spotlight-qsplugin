//
//  QSSpotlightObjectSource.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 3/26/05.
//  Rewritten by Rob McBroom 3/22/2012
//

#import "QSSpotlightObjectSource.h"

@implementation QSSpotlightObjectSource
- (id)init
{
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(arrayLoaded:) name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	[super dealloc];
}

- (void)arrayLoaded:(NSNotification *)notif
{
	// Spotlight query results are ready
	NSMetadataQuery *query = [notif object];
	[query stopQuery];
	// continue processing in objectsForEntry
	CFRunLoopStop(CFRunLoopGetCurrent());
}

- (NSImage *)iconForEntry:(NSDictionary *)theEntry
{
	return [QSResourceManager imageNamed:@"Find"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	// initiate the search
	NSString *searchString = [theEntry objectForKey:@"query"];
	NSString *path = [theEntry objectForKey:@"path"];
	BOOL localDiskOnly = [[theEntry objectForKey:@"ignoreRemovable"] boolValue];
	NSMutableSet *skipPrefixes = [NSMutableSet setWithObjects:@"tmp", @"private", nil];
	if (localDiskOnly) {
		// don't include results from FireWire, USB, etc.
		[skipPrefixes addObject:@"Volumes"];
	}
	NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
	if (path) {
		[query resultsForSearchString:searchString inFolders:[NSSet setWithObject:path]];
	} else {
		[query resultsForSearchString:searchString];
	}
	// process search results
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	NSString *resultPath = nil;
	// fast enumeration is not recommended for NSMetadataQuery
	for (NSUInteger i = 0; i < [query resultCount]; i++) {
		// get the path and create a QSObject with it
		resultPath = [[query resultAtIndex:i] valueForAttribute:@"kMDItemPath"];
		// omit ignored paths
		NSString *root = [[resultPath pathComponents] objectAtIndex:1];
		if ([skipPrefixes containsObject:root]) {
			continue;
		}
		[objects addObject:[QSObject fileObjectWithPath:resultPath]];
	}
	[query release];
	query = nil;
	return objects;
}

- (BOOL)isVisibleSource
{
	return YES;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
	// no good way to tell if the results will be different, so always rescan
	return NO;
}

- (NSView *)settingsView
{
    if (![super settingsView]){
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
    return [super settingsView];
}

- (IBAction)selectSearchPath:(NSButton *)sender
{
	NSMutableDictionary *settings = [self currentEntry];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSString *oldPath = [[settings objectForKey:kItemPath] stringByStandardizingPath];
	if (!oldPath) {
		oldPath = @"/";
	}
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	if (![openPanel runModalForDirectory:[oldPath stringByDeletingLastPathComponent] file:[oldPath lastPathComponent] types:nil]) return;
	NSString *newPath = [openPanel filename];
	[searchPath setStringValue:[newPath stringByAbbreviatingWithTildeInPath]];
	// update catalog entry
	[settings setObject:newPath forKey:kItemPath];
	//[settings setObject:[settings objectForKey:@"query"] forKey:kItemName];
	[currentEntry setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
}

- (NSString *)valueForUndefinedKey:(NSString *)key
{
	// prevent exceptions when entries created with older versions of the plug-in are loaded
	return nil;
}

@end
