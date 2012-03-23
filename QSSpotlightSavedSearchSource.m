//
//  QSSpotlightSavedSearchSource.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 3/19/05.
//

#import "QSSpotlightSavedSearchSource.h"
#import <QSInterface/QSInterfaceController.h>
#import "QSMDFindWrapper.h"

@implementation QSSpotlightSavedSearchSource

- (QSObject *)spotlightRunSavedQuery:(QSObject *)dObject
{
	NSString *path = [dObject singleFilePath];
	QSInterfaceController *controller = [[NSApp delegate] interfaceController];
	[controller showArray:[self targetArrayForSavedQueryAtPath:path]];
	return nil;
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
	NSString *path = [object singleFilePath];
	[object setChildren:[self targetArrayForSavedQueryAtPath:path]];
	return YES;
}

- (NSMutableArray *)targetArrayForSavedQueryAtPath:(NSString *)path
{
	NSDictionary *search = [NSDictionary dictionaryWithContentsOfFile:path];
	//NSLog(@"query %@",search);
	NSString *predicateString = [search objectForKey:@"RawQuery"];
	NSString *scope = [[search valueForKeyPath:@"SearchCriteria.FXScopeArrayOfPaths"] objectAtIndex:0];
	QSMDFindWrapper *wrap = [QSMDFindWrapper findWrapperWithQuery:predicateString path:scope keepalive:NO];
	NSMutableArray *results = [wrap results];
	[wrap startQuery];
	return results;
}

@end
