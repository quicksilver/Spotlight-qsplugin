//
//  QSSpotlightObjectSource.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 3/26/05.
//  Updated by Rob McBroom 3/19/2012
//

#import "QSSpotlightObjectSource.h"
#import "QSMDFindWrapper.h"

@implementation QSSpotlightObjectSource
- (id)init
{
	self = [super init];
	if (self != nil) {
		pending = [[NSMutableDictionary alloc] init];
		query = [[NSMetadataQuery alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(arrayLoaded:) name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[pending release];
	[query release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	[super dealloc];
}

- (void)arrayLoaded:(NSNotification *)notif
{
	//NSLog(@"arrayLoaded");
	[query stopQuery];
	NSArray *results = [[notif object] results];
	NSString *key = [[pending allKeysForObject:results] lastObject];
	//NSLog(@"query finished for entry: %@ with %d results", key, [[notif object] resultCount]);
	// call objectsForEntry again now that results are ready
	[[QSLib entryForID:key] scanForced:YES];
}

- (NSImage *)iconForEntry:(NSDictionary *)theEntry
{
	return [QSResourceManager imageNamed:@"Spotlight"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSString *entryKey = [theEntry objectForKey:kItemID];
	NSArray *array = [pending objectForKey:entryKey];
	if ([array count]) {
		// process search results
		NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
		NSString *resultPath = nil;
		// fast enumeration is not recommended for NSMetadataQuery
		for (int i = 0; i < [query resultCount]; i++) {
			// get the path and create a QSObject with it
			//NSLog(@"result path: %@", [[query resultAtIndex:i] valueForAttribute:NSMetadataItemPathKey]);
			resultPath = [[query resultAtIndex:i] valueForAttribute:NSMetadataItemPathKey];
			[objects addObject:[QSObject fileObjectWithPath:resultPath]];
		}
		[pending removeObjectForKey:entryKey];
		query = nil;
		return objects;
	} else {
		// initiate the search
		NSString *searchString = [theEntry objectForKey:@"query"];
		NSString *path = [theEntry objectForKey:@"path"];
		// modify the search string to make NSMetadataQuery happy
		// "my text" should become "kMDItemTextContent == 'my text'"
		// wildcard searches need to use LIKE instead of ==
		NSPredicate *search = [NSPredicate predicateWithFormat:searchString];
		[query setPredicate:search];
		if (path) {
			NSURL *pathURL = [NSURL fileURLWithPath:path];
			[query setSearchScopes:[NSArray arrayWithObject:pathURL]];
		}
		[query startQuery];
		[pending setObject:[query results] forKey:entryKey];
		//NSLog(@"started search for entry: %@", entryKey);
	}
	return nil;
}

- (BOOL)isVisibleSource
{
	return YES;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
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
	NSLog(@"spotlight entry settings: %@", settings);
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
	[currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
}

- (NSString *)valueForUndefinedKey:(NSString *)key
{
	// prevent exceptions when entries created with older versions of the plug-in are loaded
	return nil;
}

@end
