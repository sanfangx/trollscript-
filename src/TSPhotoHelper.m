#import "TSPhotoHelper.h"

@implementation TSPhotoHelper

+ (NSString *)requestPermission {
    __block NSString *res = @"notDetermined";
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized:
                res = @"authorized"; break;
            case PHAuthorizationStatusDenied:
                res = @"denied"; break;
            case PHAuthorizationStatusRestricted:
                res = @"restricted"; break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
            case PHAuthorizationStatusLimited:
                res = @"limited"; break;
#endif
            default:
                res = @"notDetermined"; break;
        }
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    return res;
}

+ (NSArray<NSDictionary *> *)getRecentWithLimit:(NSInteger)limit mediaType:(NSString *)type {
    PHFetchOptions *opts = [[PHFetchOptions alloc] init];
    opts.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    opts.fetchLimit = limit > 0 ? limit : 20;

    if ([type isEqualToString:@"image"]) {
        opts.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    } else if ([type isEqualToString:@"video"]) {
        opts.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeVideo];
    }

    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithOptions:opts];
    NSMutableArray *arr = [NSMutableArray array];
    for (PHAsset *asset in assets) {
        [arr addObject:@{
            @"id": asset.localIdentifier ?: @"",
            @"width": @(asset.pixelWidth),
            @"height": @(asset.pixelHeight),
            @"mediaType": (asset.mediaType == PHAssetMediaTypeImage) ? @"image" : @"video",
            @"creationDate": @(asset.creationDate ? [asset.creationDate timeIntervalSince1970] * 1000 : 0)
        }];
    }
    return arr;
}

+ (NSString *)getBase64ForAssetId:(NSString *)localId targetWidth:(CGFloat)w targetHeight:(CGFloat)h quality:(CGFloat)q {
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil];
    PHAsset *asset = assets.firstObject;
    if (!asset) return nil;

    PHImageRequestOptions *opts = [[PHImageRequestOptions alloc] init];
    opts.synchronous = YES;
    opts.networkAccessAllowed = YES;
    opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

    CGSize targetSize = (w > 0 && h > 0) ? CGSizeMake(w, h) : CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    __block NSString *b64 = nil;

    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:PHImageContentModeAspectFit
                                                  options:opts
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            CGFloat comp = (q > 0.0 && q <= 1.0) ? q : 0.8;
            NSData *data = UIImageJPEGRepresentation(result, comp);
            b64 = [data base64EncodedStringWithOptions:0];
        }
    }];
    return b64;
}

+ (BOOL)saveImageAtPath:(NSString *)path {
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    if (!img) return NO;

    __block BOOL success = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:img];
    } completionHandler:^(BOOL ok, NSError * _Nullable error) {
        success = ok;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    return success;
}

+ (BOOL)deleteAssetWithId:(NSString *)localId {
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil];
    if (assets.count == 0) return NO;

    __block BOOL success = NO;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assets];
    } completionHandler:^(BOOL ok, NSError * _Nullable error) {
        success = ok;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    return success;
}

@end
