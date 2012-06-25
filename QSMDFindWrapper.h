//
//  QSMDFindWrapper.h
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 3/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

@interface QSMDFindWrapper : NSObject {
	NSString *query;
	NSString *path;
	NSMutableArray *results;
	BOOL keepalive;
	NSTask *task;
	NSMutableString *resultPaths;
}
+ (QSMDFindWrapper *)findWrapperWithQuery:(NSString *)aQuery path:(NSString *)aPath keepalive:(BOOL)keepAlive;
- (void)startQuery;
- (NSMutableArray *)results;

@end
