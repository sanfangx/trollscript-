#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import "quickjs.h"
#import "fishhook.h"
#import "TSPhotoHelper.h"

// QuickJS function pointers resolved dynamically from host
static JSValue (*p_JS_NewObject)(JSContext *ctx) = NULL;
static JSValue (*p_JS_NewArray)(JSContext *ctx) = NULL;
static JSValue (*p_JS_NewString)(JSContext *ctx, const char *str) = NULL;
static JSValue (*p_JS_NewInt32)(JSContext *ctx, int32_t val) = NULL;
static JSValue (*p_JS_NewBool)(JSContext *ctx, int val) = NULL;
static JSValue (*p_JS_NewCFunction2)(JSContext *ctx, JSCFunction *func, const char *name, int length, int cproto, int magic) = NULL;
static int (*p_JS_SetPropertyStr)(JSContext *ctx, JSValueConst this_obj, const char *prop, JSValue val) = NULL;
static int (*p_JS_SetPropertyUint32)(JSContext *ctx, JSValueConst this_obj, uint32_t idx, JSValue val) = NULL;
static JSValue (*p_JS_GetGlobalObject)(JSContext *ctx) = NULL;
static const char *(*p_JS_ToCString)(JSContext *ctx, JSValueConst val) = NULL;
static void (*p_JS_FreeCString)(JSContext *ctx, const char *ptr) = NULL;
static void (*p_JS_FreeValue)(JSContext *ctx, JSValue v) = NULL;

static void init_qjs_symbols(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        p_JS_NewObject = (JSValue (*)(JSContext *))dlsym(RTLD_DEFAULT, "JS_NewObject");
        p_JS_NewArray = (JSValue (*)(JSContext *))dlsym(RTLD_DEFAULT, "JS_NewArray");
        p_JS_NewString = (JSValue (*)(JSContext *, const char *))dlsym(RTLD_DEFAULT, "JS_NewString");
        p_JS_NewInt32 = (JSValue (*)(JSContext *, int32_t))dlsym(RTLD_DEFAULT, "JS_NewInt32");
        p_JS_NewBool = (JSValue (*)(JSContext *, int))dlsym(RTLD_DEFAULT, "JS_NewBool");
        p_JS_NewCFunction2 = (JSValue (*)(JSContext *, JSCFunction *, const char *, int, int, int))dlsym(RTLD_DEFAULT, "JS_NewCFunction2");
        p_JS_SetPropertyStr = (int (*)(JSContext *, JSValueConst, const char *, JSValue))dlsym(RTLD_DEFAULT, "JS_SetPropertyStr");
        p_JS_SetPropertyUint32 = (int (*)(JSContext *, JSValueConst, uint32_t, JSValue))dlsym(RTLD_DEFAULT, "JS_SetPropertyUint32");
        p_JS_GetGlobalObject = (JSValue (*)(JSContext *))dlsym(RTLD_DEFAULT, "JS_GetGlobalObject");
        p_JS_ToCString = (const char *(*)(JSContext *, JSValueConst))dlsym(RTLD_DEFAULT, "JS_ToCString");
        p_JS_FreeCString = (void (*)(JSContext *, const char *))dlsym(RTLD_DEFAULT, "JS_FreeCString");
        p_JS_FreeValue = (void (*)(JSContext *, JSValue))dlsym(RTLD_DEFAULT, "JS_FreeValue");
    });
}

static JSValue js_photo_requestPermission(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    init_qjs_symbols();
    NSString *status = [TSPhotoHelper requestPermission];
    return p_JS_NewString ? p_JS_NewString(ctx, [status UTF8String]) : JS_NULL();
}

static JSValue js_photo_getRecent(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    init_qjs_symbols();
    if (!p_JS_NewArray || !p_JS_NewObject) return JS_NULL();

    NSInteger limit = 20;
    NSString *type = @"image";
    NSArray<NSDictionary *> *list = [TSPhotoHelper getRecentWithLimit:limit mediaType:type];

    JSValue arr = p_JS_NewArray(ctx);
    for (uint32_t i = 0; i < (uint32_t)list.count; i++) {
        NSDictionary *dict = list[i];
        JSValue item = p_JS_NewObject(ctx);
        p_JS_SetPropertyStr(ctx, item, "id", p_JS_NewString(ctx, [dict[@"id"] UTF8String]));
        p_JS_SetPropertyStr(ctx, item, "width", p_JS_NewInt32(ctx, [dict[@"width"] intValue]));
        p_JS_SetPropertyStr(ctx, item, "height", p_JS_NewInt32(ctx, [dict[@"height"] intValue]));
        p_JS_SetPropertyStr(ctx, item, "mediaType", p_JS_NewString(ctx, [dict[@"mediaType"] UTF8String]));
        p_JS_SetPropertyStr(ctx, item, "creationDate", p_JS_NewInt32(ctx, (int32_t)([dict[@"creationDate"] longLongValue] / 1000)));
        p_JS_SetPropertyUint32(ctx, arr, i, item);
    }
    return arr;
}

static JSValue js_photo_getBase64(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    init_qjs_symbols();
    if (argc < 1 || !p_JS_ToCString || !p_JS_NewString) return JS_NULL();
    const char *c_id = p_JS_ToCString(ctx, argv[0]);
    if (!c_id) return JS_NULL();
    NSString *localId = [NSString stringWithUTF8String:c_id];
    p_JS_FreeCString(ctx, c_id);

    NSString *b64 = [TSPhotoHelper getBase64ForAssetId:localId targetWidth:0 targetHeight:0 quality:0.8];
    if (!b64) return JS_NULL();
    return p_JS_NewString(ctx, [b64 UTF8String]);
}

static JSValue js_photo_saveImage(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    init_qjs_symbols();
    if (argc < 1 || !p_JS_ToCString || !p_JS_NewBool) return JS_NewBool(ctx, 0);
    const char *c_path = p_JS_ToCString(ctx, argv[0]);
    if (!c_path) return p_JS_NewBool(ctx, 0);
    NSString *path = [NSString stringWithUTF8String:c_path];
    p_JS_FreeCString(ctx, c_path);

    BOOL ok = [TSPhotoHelper saveImageAtPath:path];
    return p_JS_NewBool(ctx, ok ? 1 : 0);
}

static JSValue js_photo_deletePhoto(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    init_qjs_symbols();
    if (argc < 1 || !p_JS_ToCString || !p_JS_NewBool) return JS_NewBool(ctx, 0);
    const char *c_id = p_JS_ToCString(ctx, argv[0]);
    if (!c_id) return p_JS_NewBool(ctx, 0);
    NSString *localId = [NSString stringWithUTF8String:c_id];
    p_JS_FreeCString(ctx, c_id);

    BOOL ok = [TSPhotoHelper deleteAssetWithId:localId];
    return p_JS_NewBool(ctx, ok ? 1 : 0);
}

static void register_photo_to_context(JSContext *ctx) {
    if (!ctx) return;
    init_qjs_symbols();
    if (!p_JS_GetGlobalObject || !p_JS_NewObject || !p_JS_NewCFunction2 || !p_JS_SetPropertyStr) return;

    JSValue global = p_JS_GetGlobalObject(ctx);
    JSValue photoObj = p_JS_NewObject(ctx);

    p_JS_SetPropertyStr(ctx, photoObj, "requestPermission", p_JS_NewCFunction2(ctx, js_photo_requestPermission, "requestPermission", 0, 0, 0));
    p_JS_SetPropertyStr(ctx, photoObj, "getRecent", p_JS_NewCFunction2(ctx, js_photo_getRecent, "getRecent", 1, 0, 0));
    p_JS_SetPropertyStr(ctx, photoObj, "getBase64", p_JS_NewCFunction2(ctx, js_photo_getBase64, "getBase64", 2, 0, 0));
    p_JS_SetPropertyStr(ctx, photoObj, "saveImage", p_JS_NewCFunction2(ctx, js_photo_saveImage, "saveImage", 1, 0, 0));
    p_JS_SetPropertyStr(ctx, photoObj, "deletePhoto", p_JS_NewCFunction2(ctx, js_photo_deletePhoto, "deletePhoto", 1, 0, 0));

    p_JS_SetPropertyStr(ctx, global, "photo", photoObj);
    if (p_JS_FreeValue) {
        p_JS_FreeValue(ctx, global);
    }
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
    rebind_symbols((struct rebinding[1]){
        {"JS_NewContext", (void *)hooked_JS_NewContext, (void **)&orig_JS_NewContext}
    }, 1);
}
