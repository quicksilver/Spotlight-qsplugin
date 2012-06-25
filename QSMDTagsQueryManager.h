//
//  QSMDTagsQueryManager.h
//  QSFileTagsPlugIn
//
//  Created by Etienne on 11/09/08.
//  Copyright 2008 Etienne Samson. All rights reserved.
//

#define gTagPrefix [[NSUserDefaults standardUserDefaults] objectForKey:@"QSTagPrefix"]
#define QSFileTagType @"qs.tag.file"

@interface QSObject (QSFileTagsHandling)
+ (QSObject *)objectForTag:(NSString *)tag;
@end

@interface QSMDTagsQueryManager : NSObject
{
}
+ (id)sharedInstance;

- (NSArray*)tagsWithTagPrefix:(NSString*)tagPrefix;
- (NSArray*)filesForTag:(NSString*)tag;
- (NSArray*)filesForTags:(NSArray*)tags;

/* NSString Helpers for tag prefixes */
- (NSString *)stringByAddingTagPrefix:(NSString *)string;
- (NSString *)stringByRemovingTagPrefix:(NSString *)string;
@end
