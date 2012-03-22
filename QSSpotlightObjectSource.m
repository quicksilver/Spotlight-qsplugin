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
//		queries = [[NSMutableDictionary alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(arrayLoaded:) name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
//	[queries release];
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
	return [QSResourceManager imageNamed:@"Spotlight"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	// initiate the search
	NSString *searchString = [theEntry objectForKey:@"query"];
	NSString *path = [theEntry objectForKey:@"path"];
	// modify the search string to make NSMetadataQuery happy
	// "my text" should become "kMDItemTextContent == 'my text'"
	// wildcard searches need to use LIKE instead of ==
	NSPredicate *search = [NSPredicate predicateWithFormat:searchString];
	NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
	[query setPredicate:search];
	if (path) {
		NSURL *pathURL = [NSURL fileURLWithPath:path];
		[query setSearchScopes:[NSArray arrayWithObject:pathURL]];
	}
	if ([query startQuery]) {
		// wait here until query results are available
		CFRunLoopRun();
		// process search results
		NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
		NSString *resultPath = nil;
		// fast enumeration is not recommended for NSMetadataQuery
		for (int i = 0; i < [query resultCount]; i++) {
			// get the path and create a QSObject with it
			resultPath = [[query resultAtIndex:i] valueForAttribute:NSMetadataItemPathKey];
			[objects addObject:[QSObject fileObjectWithPath:resultPath]];
		}
		[query release];
		query = nil;
		return objects;
	} else {
		NSLog(@"Spotlight query unable to start for '%@'", [theEntry objectForKey:kItemName]);
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
