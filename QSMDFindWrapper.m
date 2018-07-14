//
//  QSMDFindWrapper.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 3/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSMDFindWrapper.h"


@implementation QSMDFindWrapper

+ (QSMDFindWrapper *)findWrapperWithQuery:(NSString *)query path:(NSString *)path keepalive:(BOOL)flag{
	return [[self alloc] initWithQuery:(NSString *)query path:(NSString *)path keepalive:(BOOL)flag];
}

- (id)initWithQuery:(NSString *)aQuery path:(NSString *)aPath keepalive:(BOOL)flag{
	if (self=[super init]){
		results=[[NSMutableArray alloc]init];
		resultPaths=[[NSMutableString alloc]init];
		path=aPath;
		query=aQuery;
		keepalive=flag;
	}
	return self;
}

- (NSMutableArray *)results
{
	return results;
}
- (void)startQuery
{
	task = [NSTask taskWithLaunchPath:@"/usr/bin/mdfind" arguments:[NSArray arrayWithObjects:query, path ? @"-onlyin" : nil, path, nil]];
	[task setStandardOutput:[NSPipe pipe]];
	NSFileHandle *handle = [[task standardOutput]fileHandleForReading];
	[task launch];
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleReadCompletionNotification object:handle];
	[handle readInBackgroundAndNotify];
	//	results=[[NSMutableArray alloc]init];
//	QSObject *searchObject=[QSObject objectWithString:@"Searching"];
//	[searchObject setIcon:[QSResourceManager imageNamed:@"Find"]];
//	[results addObject:searchObject];
	
	QSTask *spotlightTask = [QSTasks taskWithIdentifier:@"QSSpotlight"];
	[spotlightTask setStatus:@"Performing Search"];
	[spotlightTask setProgress:0];
	//return results;
}

-(void)dataAvailable:(NSNotification *)notif{
	
	NSFileHandle *handle=[notif object];
	//return;
	NSData *data=[[notif userInfo]
                  objectForKey: NSFileHandleNotificationDataItem];
	NSString *newString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
	if ([newString length])
		[resultPaths appendString:newString];
	
	
	NSArray *pathArray=[resultPaths componentsSeparatedByString:@"\n"];
	
	[resultPaths setString:[pathArray lastObject]];
	pathArray=[pathArray subarrayWithRange:NSMakeRange(0,[pathArray count]-1)];
//	NSLog(@"paths %d",[pathArray count]);	
	//NSLog(@"remaining:%@",resultPaths);
	
	[results addObjectsFromArray:[QSObject fileObjectsWithPathArray:pathArray]];
//	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:results, kQSResultArrayKey, nil];
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSSourceArrayUpdated" object:self userInfo:userInfo];
	
	//	[results release];
	//	results=nil;
	if ([data length])
		[handle readInBackgroundAndNotify];
	else{
		
		[[QSTasks taskWithIdentifier:@"QSSpotlight"] stop];
//		[results removeObjectAtIndex:0];
		
//		[[NSNotificationCenter defaultCenter]postNotificationName:@"QSSourceArrayUpdated" object:self userInfo:userInfo];
	}
}
@end
