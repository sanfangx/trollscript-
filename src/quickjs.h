#ifndef QUICKJS_MIN_H
#define QUICKJS_MIN_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct JSRuntime JSRuntime;
typedef struct JSContext JSContext;
typedef struct JSObject JSObject;

#if defined(__x86_64__) || defined(__aarch64__)
typedef union JSValueUnion {
    int32_t int32;
    double float64;
    void *ptr;
} JSValueUnion;

typedef struct JSValue {
    JSValueUnion u;
    int64_t tag;
} JSValue;
#else
typedef struct JSValue {
    union {
        int32_t int32;
        double float64;
        void *ptr;
    } u;
    int32_t tag;
} JSValue;
#endif

#define JS_TAG_UNINITIALIZED -1
#define JS_TAG_INT            0
#define JS_TAG_BOOL           1
#define JS_TAG_NULL           2
#define JS_TAG_UNDEFINED      3
#define JS_TAG_CATCH_OFFSET   4
#define JS_TAG_EXCEPTION      6
#define JS_TAG_FLOAT64        7
#define JS_TAG_STRING        -7
#define JS_TAG_OBJECT        -1

typedef JSValue JSCFunction(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv);
typedef const JSValue JSValueConst;

// QuickJS exported symbols provided by host (TrollScript)
JSValue JS_NewObject(JSContext *ctx);
JSValue JS_NewArray(JSContext *ctx);
JSValue JS_NewString(JSContext *ctx, const char *str);
JSValue JS_NewInt32(JSContext *ctx, int32_t val);
JSValue JS_NewBool(JSContext *ctx, int val);
JSValue JS_NewCFunction2(JSContext *ctx, JSCFunction *func, const char *name, int length, int cproto, int magic);
int JS_SetPropertyStr(JSContext *ctx, JSValueConst this_obj, const char *prop, JSValue val);
int JS_SetPropertyUint32(JSContext *ctx, JSValueConst this_obj, uint32_t idx, JSValue val);
JSValue JS_GetGlobalObject(JSContext *ctx);
const char *JS_ToCString(JSContext *ctx, JSValueConst val);
void JS_FreeCString(JSContext *ctx, const char *ptr);
void JS_FreeValue(JSContext *ctx, JSValue v);
int JS_ToInt32(JSContext *ctx, int32_t *pres, JSValueConst val);

static inline JSValue JS_UNDEFINED(void) {
    JSValue v;
    v.u.ptr = NULL;
    v.tag = JS_TAG_UNDEFINED;
    return v;
}

static inline JSValue JS_NULL(void) {
    JSValue v;
    v.u.ptr = NULL;
    v.tag = JS_TAG_NULL;
    return v;
}

#ifdef __cplusplus
}
#endif

#endif
