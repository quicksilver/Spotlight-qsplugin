//
//  QSFileTagsPlugInSource.m
//  QSFileTagsPlugIn
//
//  Created by Nicholas Jitkoff on 5/3/05.
//  Copyright __MyCompanyName__ 2005. All rights reserved.
//

#import "QSMDTagsQueryManager.h"
#import "QSFileTagsPlugInSource.h"

@implementation QSFileTagsPlugInSource

- (id)init
{
    self = [super init];
    if (self) {
		if (!gTagPrefix) {
			// make sure the tag prefix is set (and let the user know)
			[[NSUserDefaults standardUserDefaults] setObject:@"#" forKey:@"QSTagPrefix"];
			NSString *message = [NSString stringWithFormat:@"The prefix for Spotlight tags has been set to \"%@\". You can change it in the Preferences.", gTagPrefix];
			QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"SpotlightPluginNotification", QSNotifierType, [QSResourceManager imageNamed:@"Tag"], QSNotifierIcon, @"Spotlight Tagging", QSNotifierTitle, message, QSNotifierText, nil]);
		}
    }
    return self;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
    return NO;
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {
    return [QSResourceManager imageNamed:@"Tag"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
    NSMutableArray *objects = nil;
    NSArray *tags = [[QSMDTagsQueryManager sharedInstance] tagsWithTagPrefix:gTagPrefix];
	if ([tags count] != 0) {        
		objects = [QSObject performSelector:@selector(objectForTag:) onObjectsInArray:tags returnValues:YES];
	}
    return objects;
}

// Object Handler Methods
- (void)setQuickIconForObject:(QSObject *)object {
    [object setIcon:[QSResourceManager imageNamed:@"Tag"]]; // An icon that is either already in memory or easy to load
}

- (NSMutableArray *)targetArrayForTag:(NSString *)tag {
    NSMutableArray *objects = nil;
    NSArray *files = [[QSMDTagsQueryManager sharedInstance] filesForTag:tag];
	if ([files count] != 0) {
		objects = [QSObject performSelector:@selector(fileObjectWithPath:) onObjectsInArray:files returnValues:YES];
	}
    return objects;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	[object setChildren:[self targetArrayForTag:[object objectForType:QSFileTagType]]];
	return YES;
}

/*
 - (BOOL)loadIconForObject:(QSObject *)object {
	 return NO;
	 id data = [object objectForType:QSFileTagsPlugInType];
	 [object setIcon:nil];
	 return YES;
 }
 */
@end
