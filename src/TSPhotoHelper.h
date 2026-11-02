#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface TSPhotoHelper : NSObject

+ (NSString *)requestPermission;
+ (NSArray<NSDictionary *> *)getRecentWithLimit:(NSInteger)limit mediaType:(NSString *)type;
+ (NSString *)getBase64ForAssetId:(NSString *)localId targetWidth:(CGFloat)w targetHeight:(CGFloat)h quality:(CGFloat)q;
+ (BOOL)saveImageAtPath:(NSString *)path;
+ (BOOL)deleteAssetWithId:(NSString *)localId;

@end
