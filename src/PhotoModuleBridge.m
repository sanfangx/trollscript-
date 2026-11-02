#import <Foundation/Foundation.h>
#import "quickjs.h"
#import "fishhook.h"
#import "TSPhotoHelper.h"

static JSValue js_photo_requestPermission(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    NSString *status = [TSPhotoHelper requestPermission];
    return JS_NewString(ctx, [status UTF8String]);
}

static JSValue js_photo_getRecent(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    NSInteger limit = 20;
    NSString *type = @"image";
    if (argc > 0 && argv[0].tag == JS_TAG_OBJECT) {
        // Can read options if needed
    }
    NSArray<NSDictionary *> *list = [TSPhotoHelper getRecentWithLimit:limit mediaType:type];
    JSValue arr = JS_NewArray(ctx);
    for (uint32_t i = 0; i < (uint32_t)list.count; i++) {
        NSDictionary *dict = list[i];
        JSValue item = JS_NewObject(ctx);
        JS_SetPropertyStr(ctx, item, "id", JS_NewString(ctx, [dict[@"id"] UTF8String]));
        JS_SetPropertyStr(ctx, item, "width", JS_NewInt32(ctx, [dict[@"width"] intValue]));
        JS_SetPropertyStr(ctx, item, "height", JS_NewInt32(ctx, [dict[@"height"] intValue]));
        JS_SetPropertyStr(ctx, item, "mediaType", JS_NewString(ctx, [dict[@"mediaType"] UTF8String]));
        JS_SetPropertyStr(ctx, item, "creationDate", JS_NewInt32(ctx, (int32_t)([dict[@"creationDate"] longLongValue] / 1000)));
        JS_SetPropertyUint32(ctx, arr, i, item);
    }
    return arr;
}

static JSValue js_photo_getBase64(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1) return JS_NULL();
    const char *c_id = JS_ToCString(ctx, argv[0]);
    if (!c_id) return JS_NULL();
    NSString *localId = [NSString stringWithUTF8String:c_id];
    JS_FreeCString(ctx, c_id);

    NSString *b64 = [TSPhotoHelper getBase64ForAssetId:localId targetWidth:0 targetHeight:0 quality:0.8];
    if (!b64) return JS_NULL();
    return JS_NewString(ctx, [b64 UTF8String]);
}

static JSValue js_photo_saveImage(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1) return JS_NewBool(ctx, 0);
    const char *c_path = JS_ToCString(ctx, argv[0]);
    if (!c_path) return JS_NewBool(ctx, 0);
    NSString *path = [NSString stringWithUTF8String:c_path];
    JS_FreeCString(ctx, c_path);

    BOOL ok = [TSPhotoHelper saveImageAtPath:path];
    return JS_NewBool(ctx, ok ? 1 : 0);
}

static JSValue js_photo_deletePhoto(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1) return JS_NewBool(ctx, 0);
    const char *c_id = JS_ToCString(ctx, argv[0]);
    if (!c_id) return JS_NewBool(ctx, 0);
    NSString *localId = [NSString stringWithUTF8String:c_id];
    JS_FreeCString(ctx, c_id);

    BOOL ok = [TSPhotoHelper deleteAssetWithId:localId];
    return JS_NewBool(ctx, ok ? 1 : 0);
}

static void register_photo_to_context(JSContext *ctx) {
    if (!ctx) return;
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue photoObj = JS_NewObject(ctx);

    JS_SetPropertyStr(ctx, photoObj, "requestPermission", JS_NewCFunction2(ctx, js_photo_requestPermission, "requestPermission", 0, 0, 0));
    JS_SetPropertyStr(ctx, photoObj, "getRecent", JS_NewCFunction2(ctx, js_photo_getRecent, "getRecent", 1, 0, 0));
    JS_SetPropertyStr(ctx, photoObj, "getBase64", JS_NewCFunction2(ctx, js_photo_getBase64, "getBase64", 2, 0, 0));
    JS_SetPropertyStr(ctx, photoObj, "saveImage", JS_NewCFunction2(ctx, js_photo_saveImage, "saveImage", 1, 0, 0));
    JS_SetPropertyStr(ctx, photoObj, "deletePhoto", JS_NewCFunction2(ctx, js_photo_deletePhoto, "deletePhoto", 1, 0, 0));

    JS_SetPropertyStr(ctx, global, "photo", photoObj);
    JS_FreeValue(ctx, global);
    NSLog(@"[TrollScript-Photo] Successfully registered 'photo' module to global context!");
}

static JSContext *(*orig_JS_NewContext)(JSRuntime *rt) = NULL;

static JSContext *hooked_JS_NewContext(JSRuntime *rt) {
    JSContext *ctx = orig_JS_NewContext ? orig_JS_NewContext(rt) : NULL;
    if (ctx) {
        register_photo_to_context(ctx);
    }
    return ctx;
}

__attribute__((constructor))
static void photo_module_entrypoint(void) {
    NSLog(@"[TrollScript-Photo] libPhotoModule loaded! Installing QuickJS hooks...");
    rebind_symbols((struct rebinding[1]){
        {"JS_NewContext", (void *)hooked_JS_NewContext, (void **)&orig_JS_NewContext}
    }, 1);
}
