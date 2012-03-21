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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(arrayLoaded:) name:@"QSSourceArrayFinished" object:nil];
	}
	return self;
}

- (void)dealloc
{
	[pending release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"QSSourceArrayFinished" object:nil];
	[super dealloc];
}

- (void)arrayLoaded:(NSNotification *)notif
{
	NSArray *array = [notif object];
	
	NSString *key = [[pending allKeysForObject:array] lastObject];
//	NSLog(@"%@ finished %d",key,[array count]);
	//[pending removeObjectForKey:key];
	//[self invalidateSelf];
	[[QSLib entryForID:key] scanForced:YES];
}

- (NSImage *)iconForEntry:(NSDictionary *)theEntry
{
	return [QSResourceManager imageNamed:@"Spotlight"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSArray *array = [pending objectForKey:[theEntry objectForKey:kItemID]];
//	NSLog(@"scan %@ %d items",theEntry, [array count]);
	//NSLog(@"%@");
	if ([array count]) {
		return array;
	} else {
		NSString *query = [theEntry objectForKey:@"query"];
		QSMDFindWrapper *wrap = [QSMDFindWrapper findWrapperWithQuery:query path:nil keepalive:NO];
		NSMutableArray *results = [wrap results];
		[wrap performSelectorOnMainThread:@selector(startQuery) withObject:nil waitUntilDone:NO];
		//NSLog(@"started %@",wrap);
		[pending setObject:results forKey:[theEntry objectForKey:kItemID]];
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
