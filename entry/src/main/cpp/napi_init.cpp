#include "napi/native_api.h"
#include <map>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include "myapp.h"
#include "hilog/log.h"
#include <thread>

typedef void (*notifyDnsChanged_t)(c_string dnsList);
typedef void (*notifyInstalledAppsChanged_t)(c_string uids);
typedef void (*notifyTimeZoneChanged_t)(c_string name, int offset);
typedef char* (*queryConfiguration_t)();
typedef void (*fetchAndValid_t)(void* callback, c_string path, c_string url, int force);
typedef void (*load_t)(void* completable, c_string path);
typedef char* (*readOverride_t)(int slot);
typedef void (*writeOverride_t)(int slot, c_string content);
typedef void (*clearOverride_t)(int slot);
typedef void (*subscribeLogcat_t)(void* remote);
typedef void (*coreInit_t)(c_string home, c_string versionName, int sdkVersion);
typedef int (*coreTest_t)();
typedef void (*reset_t)();
typedef void (*forceGc_t)();
typedef char* (*startHttp_t)(c_string listenAt);
typedef void (*stopHttp_t)();
typedef int (*startTun_t)(int fd, c_string gateway, c_string portal, c_string dns, void* callback);
typedef void (*stopTun_t)();
typedef char* (*queryTunnelState_t)();
typedef void (*queryNow_t)(uint64_t* upload, uint64_t* download);
typedef void (*queryTotal_t)(uint64_t* upload, uint64_t* download);
typedef char* (*queryGroupNames_t)(int excludeNotSelectable);
typedef char* (*queryGroup_t)(c_string name, c_string sortMode);
typedef void (*healthCheck_t)(void* completable, c_string name);
typedef void (*healthCheckAll_t)();
typedef int (*patchSelector_t)(c_string selector, c_string name);
typedef char* (*queryProviders_t)();
typedef void (*updateProvider_t)(void* completable, c_string pType, c_string name);
typedef void (*suspend_t)(int suspended);
typedef char* (*installSideloadGeoip_t)(void* block, int blockSize);


// 声明函数指针变量
notifyDnsChanged_t notifyDnsChanged;
notifyInstalledAppsChanged_t notifyInstalledAppsChanged;
notifyTimeZoneChanged_t notifyTimeZoneChanged;
queryConfiguration_t queryConfiguration;
fetchAndValid_t fetchAndValid;
load_t load;
readOverride_t readOverride;
writeOverride_t writeOverride;
clearOverride_t clearOverride;
subscribeLogcat_t subscribeLogcat;
coreInit_t coreInit;
coreTest_t coreTest;
reset_t reset;
forceGc_t forceGc;
startHttp_t startHttp;
stopHttp_t stopHttp;
startTun_t startTun;
stopTun_t stopTun;
queryTunnelState_t queryTunnelState;
queryNow_t queryNow;
queryTotal_t queryTotal;
queryGroupNames_t queryGroupNames;
queryGroup_t queryGroup;
healthCheck_t healthCheck;
healthCheckAll_t healthCheckAll;
patchSelector_t patchSelector;
queryProviders_t queryProviders;
updateProvider_t updateProvider;
suspend_t suspend;
installSideloadGeoip_t installSideloadGeoip;


#define LOAD_FUNCTION(handle, func) \
    func = (typeof(func))dlsym(handle, #func); \
    if (!func) { \
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, "ClashNative", "Failed to load function: %{public}s \n", #func); \
        return nullptr; \
    }

char* get_string_from_js(napi_env env, napi_value js_str) {
    // 获取字符串长度
    size_t str_len;
    napi_get_value_string_utf8(env, js_str, NULL, 0, &str_len);

    // 为字符串分配内存
    char* buffer = (char*)malloc((str_len + 1) * sizeof(char));
    if (buffer == NULL) {
        napi_throw_error(env, NULL, "Failed to allocate memory for string");
        return NULL;
    }

    // 获取字符串内容
    napi_get_value_string_utf8(env, js_str, buffer, str_len + 1, &str_len);

    return buffer;
}

struct TsfnPool {
    std::map<std::string, napi_threadsafe_function> tsfnMap; // 存储多个线程安全函数
};
static TsfnPool tsfnPool;

struct CallbackData {
    int fd;
    char* type;
    char* content;
};
static CallbackData callbackData;

static napi_value nativeFetchAndValid(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value args[4] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* path = get_string_from_js(env, args[0]);
    char* url = get_string_from_js(env, args[1]);
    bool force = false;
    napi_get_value_bool(env, args[1],  &force);
    napi_value resourceName;
    napi_create_string_latin1(env, "nativeFetchAndValid'", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn;
    napi_create_threadsafe_function(env, args[3], NULL, resourceName, 0, 1, NULL, NULL, NULL, [](napi_env env, napi_value js_callback, void *context, void *data){
       CallbackData* cd = static_cast<CallbackData *>(data);
        if (cd == nullptr)
            return ;
        napi_value params[2];
        napi_create_string_utf8(env, cd->type, NAPI_AUTO_LENGTH, &params[0]);
        if(cd->content != NULL){
            napi_create_string_utf8(env, cd->content, NAPI_AUTO_LENGTH, &params[1]);
            
        } else {
            napi_get_undefined(env, &params[1]);
        }
        napi_call_function(env, nullptr, js_callback, 2, params, nullptr);
        }, &tsfn);
    tsfnPool.tsfnMap["nativeFetchAndValid"] = tsfn;
   
    
    // storage/Users/currentUser/Download/pending
    OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x0000, "ClashMeta", "fetchAndValid %{public}s %{public}s" ,path, url);
    std::thread t([](char * path, char * url, bool force){
         fetchAndValid((void *)+[](char *completable, char *exception) {
                callbackData.type = completable;
                if(exception != NULL){
                    size_t len = strlen(exception) + 1;
                    char *result = (char *)malloc(len);
                    strcat(result, exception);
                    callbackData.content = result;
                }else{
                    callbackData.content = "";
                }
                auto it = tsfnPool.tsfnMap.find("nativeFetchAndValid");
                if (it != tsfnPool.tsfnMap.end()){
                    napi_call_threadsafe_function(it->second, &callbackData, napi_tsfn_blocking);
                }
        }, path, url, force);
    }, path, url, force);
    t.join();
    free(path);
    free(url);
    return NULL;
}


static napi_value nativeLoad(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* path = get_string_from_js(env, args[0]);
    
    napi_value resourceName;
    napi_create_string_latin1(env, "nativeLoad'", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn;
    napi_create_threadsafe_function(env, args[1], NULL, resourceName, 0, 1, NULL, NULL, NULL, [](napi_env env, napi_value js_callback, void *context, void *data){
       CallbackData* cd = static_cast<CallbackData *>(data);
        if (cd == nullptr)
            return ;
        napi_value params[1];
        if (cd->content != NULL){
            napi_create_string_utf8(env, cd->content, strlen(cd->content), &params[0]);
        } else {
            napi_get_undefined(env, &params[0]);
        }
        napi_call_function(env, nullptr, js_callback, 1, params, nullptr);
        }, &tsfn);
    tsfnPool.tsfnMap["nativeLoad"] = tsfn;
    std::thread t([](char * path){
        load((void*)+[](char* completable, char* exception){
                callbackData.content = exception;
                auto it = tsfnPool.tsfnMap.find("nativeLoad");
                if (it != tsfnPool.tsfnMap.end()){
                    napi_call_threadsafe_function(it->second, &callbackData, napi_tsfn_blocking);
                }
            }, path);
    }, path);
    t.join();
    return NULL;
}
static napi_value nativeHealthCheck(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* name = get_string_from_js(env, args[0]);
    napi_value resourceName;
    napi_create_string_latin1(env, "nativeHealthCheck'", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn;
    napi_create_threadsafe_function(env, args[1], NULL, resourceName, 0, 1, NULL, NULL, NULL, [](napi_env env, napi_value js_callback, void *context, void *data){
        CallbackData* cd = (CallbackData *)data;
        if (cd == nullptr)
            return ;
        napi_value params[1];
        if (cd->content != NULL){
            napi_create_string_utf8(env, cd->content, strlen(cd->content), &params[0]);
        } else {
            napi_get_undefined(env, &params[0]);
        }
        napi_call_function(env, nullptr, js_callback, 1, params, nullptr);
    }, &tsfn);
    tsfnPool.tsfnMap["nativeHealthCheck"] = tsfn;
    std::thread t([](char* name){
         healthCheck((void *)+[](char* completable, char* exception){ 
            callbackData.content = exception;
            auto it = tsfnPool.tsfnMap.find("nativeHealthCheck");
            if (it != tsfnPool.tsfnMap.end()){
                napi_call_threadsafe_function(it->second, &callbackData, napi_tsfn_blocking);
            }
         }, name);
    }, name);
    t.join();
    free(name);
    return NULL;
}
static napi_value nativeSubscribeLogcat(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    napi_value resourceName;
    napi_create_string_latin1(env, "nativeSubscribeLogcat'", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn;
    napi_create_threadsafe_function(env, args[0], NULL, resourceName, 0, 1, NULL, NULL, NULL, [](napi_env env, napi_value js_callback, void *context, void *data){
       CallbackData* cd = (CallbackData *)data;
        if (cd == nullptr)
            return ;
        napi_value params[1];
        if(cd->content != NULL){
            napi_create_string_utf8(env, cd->content, strlen(cd->content), &params[0]);
        } else {
           napi_get_undefined(env, &params[0]);
        }
        napi_call_function(env, nullptr, js_callback, 1, params, nullptr);
        }, &tsfn);
    tsfnPool.tsfnMap["nativeSubscribeLogcat"] = tsfn;
    std::thread t([](){
        subscribeLogcat((void *)+[](void *logcat_interface, char *payload){ 
            callbackData.content = payload;
            auto it = tsfnPool.tsfnMap.find("nativeSubscribeLogcat");
            if (it != tsfnPool.tsfnMap.end()){
                napi_call_threadsafe_function(it->second, &callbackData, napi_tsfn_blocking);
            }
        });
    });
    t.join();
    return NULL;
}
static napi_value nativeUpdateProvider(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* type = get_string_from_js(env, args[0]);
    char* name = get_string_from_js(env, args[1]);
    
     napi_value resourceName;
    napi_create_string_latin1(env, "nativeUpdateProvider", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn;
    napi_create_threadsafe_function(env, args[0], NULL, resourceName, 0, 1, NULL, NULL, NULL, [](napi_env env, napi_value js_callback, void *context, void *data){
        napi_value params[1];
        napi_call_function(env, nullptr, js_callback, 0, params, nullptr);
    }, &tsfn);
    tsfnPool.tsfnMap["nativeUpdateProvider"] = tsfn;
    
    updateProvider((void *)+[](){
        auto it = tsfnPool.tsfnMap.find("nativeUpdateProvider");
        if (it != tsfnPool.tsfnMap.end()){
            napi_call_threadsafe_function(it->second, &callbackData, napi_tsfn_blocking);
        }
    },type, name);
    free(type);
    free(name);
    return NULL;
}
static napi_value nativeStartTun(napi_env env, napi_callback_info info)
{
 
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    
    int tunFd;
    napi_get_value_int32(env, args[0], &tunFd);

    napi_value resourceName;
    napi_create_string_latin1(env, "nativeStartTun'", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn;
    napi_create_threadsafe_function(env, args[1], NULL, resourceName, 0, 1, NULL, NULL, NULL, [](napi_env env, napi_value js_callback, void *context, void *data){
   
        CallbackData* cd = (CallbackData *)data;
        if (cd == nullptr)
            return ;
        napi_value params[1];
        napi_value result;
        napi_create_int32(env, cd->fd, &result);
        params[0] = result;
        napi_call_function(env, nullptr, js_callback, 1, params, nullptr);
        }, &tsfn);
    tsfnPool.tsfnMap["nativeStartTun"] = tsfn;
    
    std::thread t([](int fd){
        OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x00000, "ClashVpn", "startRun %{public}d", fd);
        startTun(fd, "172.19.0.1/30", "172.19.0.2", "0.0.0.0", (void*)+[](void *tun_interface, int fd){
            callbackData.fd = fd;
            auto it = tsfnPool.tsfnMap.find("nativeStartTun");
            if (it != tsfnPool.tsfnMap.end()){
                 napi_call_threadsafe_function(it->second, &callbackData, napi_tsfn_blocking);
            }
        });
    }, tunFd);
    t.detach();
    return NULL;
}


static napi_value nativeInit(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* path = get_string_from_js(env, args[0]);
    char* version = get_string_from_js(env, args[1]);
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, "ClashNative", "nativeInit %{public}s", path);
    std::thread t([](char* path, char *version){
         coreInit(path, version, 30);
         OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, "ClashNative", "coreInit %{public}s", "success");
    },path, version);
    t.join();
    return NULL;
}

static napi_value nativeStopTun(napi_env env, napi_callback_info info)
{
    std::thread t([](){
       stopTun();
    });
    t.join();
    return NULL;
}

static napi_value nativeQueryGroupNames(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    int excludeNotSelectable = 0;
   
    napi_get_value_int32(env, args[0], &excludeNotSelectable);
    char* groupInfo;
    std::thread t([](int excludeNotSelectable, char* &groupInfo){
         groupInfo = queryGroupNames(excludeNotSelectable);
    }, excludeNotSelectable, std::ref(groupInfo));
    t.join();
    napi_value result;
    napi_create_string_utf8(env, groupInfo, NAPI_AUTO_LENGTH, &result);
    free(groupInfo);
    return result;
}
static napi_value nativeQueryGroup(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* groupName = get_string_from_js(env, args[0]);
    char* sortMode = get_string_from_js(env, args[1]);
    char* groupInfo;
    std::thread t([](char* groupName, char* sortMode, char* &groupInfo){
        char* newValue = queryGroup(groupName, sortMode);
        groupInfo = new char[strlen(newValue) + 1];
        strcpy(groupInfo, newValue); 
     }, groupName, sortMode, std::ref(groupInfo));
    t.join();
    free(groupName);
    free(sortMode);
    napi_value result;
    napi_create_string_utf8(env, groupInfo, NAPI_AUTO_LENGTH, &result);
    free(groupInfo);
    return result;
}

static napi_value nativeQueryTunnelState(napi_env env, napi_callback_info info)
{
    char* groupInfo = queryTunnelState();
    napi_value result;
    napi_create_string_utf8(env, groupInfo, NAPI_AUTO_LENGTH, &result);
    free(groupInfo);
    return result;
}

static napi_value nativeWriteOverride(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    int slot = 0;
    napi_get_value_int32(env, args[0], &slot);
    char* groupName = get_string_from_js(env, args[1]);
    std::thread t([](int slot, char * groupName){
        writeOverride(slot, groupName);
    }, slot, groupName);
    t.join();
    return NULL;
}
static napi_value nativeReadOverride(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    int slot = 0;
    napi_get_value_int32(env, args[0], &slot);
  
    char* groupInfo;
    std::thread t([](int slot, char* &groupInfo){
         groupInfo = readOverride(slot);
    }, slot, std::ref(groupInfo));
    t.join();
    napi_value result;
    napi_create_string_utf8(env, groupInfo, NAPI_AUTO_LENGTH, &result);
    free(groupInfo);
    return result;
}
static napi_value nativeClearOverride(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    int slot = 0;
    napi_get_value_int32(env, args[0], &slot);
    std::thread t([](int slot){
         clearOverride(slot);
    },slot);
    t.join();
    return NULL;
}

static napi_value nativePatchSelector(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* selector = get_string_from_js(env, args[0]);
    char* name = get_string_from_js(env, args[1]);
    bool res;
    
    std::thread t([](char* selector, char *name, bool &result){
        result = patchSelector(selector, name);
    },selector, name, std::ref(res));
    t.join();
    napi_value result;
    napi_get_boolean(env, res, &result);
    return result;
}


static napi_value nativeQueryProviders(napi_env env, napi_callback_info info)
{
    char* groupInfo;
    std::thread t([]( char* &groupInfo){
        groupInfo = queryProviders();
    }, std::ref(groupInfo));
    t.join();
    napi_value result;
    napi_create_string_utf8(env, groupInfo, NAPI_AUTO_LENGTH, &result);
    free(groupInfo);
    return result;
}
static napi_value nativeQueryConfiguration(napi_env env, napi_callback_info info)
{
    char* groupInfo;
    std::thread t([]( char* &groupInfo){
        groupInfo = queryConfiguration();
    }, std::ref(groupInfo));
    t.join();
    napi_value result;
    napi_create_string_utf8(env, groupInfo, NAPI_AUTO_LENGTH, &result);
    free(groupInfo);
    return result;
}
static napi_value nativeCoreVersion(napi_env env, napi_callback_info info)
{
    napi_value result;
    napi_create_string_utf8(env, "1.1.1", NAPI_AUTO_LENGTH, &result);
    return result;
}

uint64_t down_scale_traffic(uint64_t value) {
    if (value > 1042 * 1024 * 1024)
        return ((value * 100u / 1024u / 1024u / 1024u) & 0x3FFFFFFFu) | (3u << 30u);
    if (value > 1024 * 1024)
        return ((value * 100u / 1024u / 1024u) & 0x3FFFFFFFu) | (2u << 30u);
    if (value > 1024)
        return ((value * 100u / 1024u) & 0x3FFFFFFFu) | (1u << 30u);
    return value & 0x3FFFFFFFu;
}


static napi_value nativeQueryTrafficNow(napi_env env, napi_callback_info info)
{
    uint64_t upload = 0l, download = 0l;
    queryNow(&upload, &download);
    napi_value result;
    long now = down_scale_traffic(upload) << 32u | down_scale_traffic(download);
    napi_create_int64(env, now, &result);
    return result;
}
static napi_value nativeQueryTrafficTotal(napi_env env, napi_callback_info info)
{
    uint64_t upload = 0l, download = 0l;
    queryTotal(&upload, &download);
    napi_value result;
    long now = down_scale_traffic(upload) << 32u | down_scale_traffic(download);
    napi_create_int64(env, now, &result);
    return result;
}



static napi_value nativeHealthCheckAll(napi_env env, napi_callback_info info)
{
    healthCheckAll();
    return NULL;
}static napi_value nativeReset(napi_env env, napi_callback_info info)
{
    std::thread t([](){
        reset();
    });
    t.join();
    return NULL;
}
static napi_value nativeForceGc(napi_env env, napi_callback_info info)
{
    std::thread t([](){
        forceGc();
    });
    t.join();
    return NULL;
}
static napi_value nativeStopHttp(napi_env env, napi_callback_info info)
{
    std::thread t([](){
        stopHttp();
    });
    t.join();
    return NULL;   
}
static napi_value nativeStartHttp(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    char* groupInfo = get_string_from_js(env, args[0]);
    std::thread t([](char * groupInfo){
        startHttp(groupInfo);
    }, groupInfo);
    t.join();
    free(groupInfo);
    return NULL;
}

static napi_value nativeSuspend(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    int suspended = 0;
    napi_get_value_int32(env, args[0], &suspended);
    suspend(suspended);
    return NULL;
}
static napi_value nativeInstallSideloadGeoip(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    
    napi_typedarray_type array_type;
    size_t byte_length;
    void* data;
    napi_value arraybuffer;
    size_t byte_offset;
    napi_get_typedarray_info(env, args[0], &array_type, &byte_length, &data, &arraybuffer, &byte_offset);
    
    void* uint8_data = static_cast<uint8_t*>(data);
    installSideloadGeoip(uint8_data, byte_length);
    free(data);
    return NULL;
}


EXTERN_C_START

void* loadClashSo(){
    void *handle = dlopen("myapp.so", RTLD_LAZY);
    const char* dlsym_error = dlerror();
    if (!handle) {
        fprintf(stderr, "Failed to load library: %s\n", dlsym_error);
        return nullptr;
    }
    LOAD_FUNCTION(handle, notifyDnsChanged);
    LOAD_FUNCTION(handle, coreInit);
    LOAD_FUNCTION(handle, startHttp);
    LOAD_FUNCTION(handle, stopHttp);
    LOAD_FUNCTION(handle, startTun);
    LOAD_FUNCTION(handle, stopTun);
    LOAD_FUNCTION(handle, fetchAndValid);
    LOAD_FUNCTION(handle, load);
    LOAD_FUNCTION(handle, queryGroupNames);
    LOAD_FUNCTION(handle, queryGroup);
    LOAD_FUNCTION(handle, queryTunnelState);
    LOAD_FUNCTION(handle, writeOverride);
    LOAD_FUNCTION(handle, readOverride);
    LOAD_FUNCTION(handle, clearOverride);
    LOAD_FUNCTION(handle, patchSelector);
    LOAD_FUNCTION(handle, reset);
    LOAD_FUNCTION(handle, forceGc);
    LOAD_FUNCTION(handle, healthCheck);
    LOAD_FUNCTION(handle, healthCheckAll);
    LOAD_FUNCTION(handle, queryProviders);
    LOAD_FUNCTION(handle, updateProvider);
    LOAD_FUNCTION(handle, suspend);
    LOAD_FUNCTION(handle, queryNow);
    LOAD_FUNCTION(handle, queryTotal);
    LOAD_FUNCTION(handle, queryConfiguration);
    LOAD_FUNCTION(handle, installSideloadGeoip);
    LOAD_FUNCTION(handle, subscribeLogcat);
    LOAD_FUNCTION(handle, coreTest);
    
    return nullptr;
}

static napi_value Init(napi_env env, napi_value exports)
{
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, "ClashNative", "%{public}s", "init");
    loadClashSo();
    if(coreInit == nullptr){
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, "ClashNative", "%{public}s", "coreInit no load");
    } else {
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, "ClashNative", "%{public}s", "coreInit load success");
    }
//    必须这里调用
//     coreInit("/storage/Users/currentUser/Download/", "1.1.1", 30);
    napi_property_descriptor desc[] = {
        { "nativeFetchAndValid", nullptr, nativeFetchAndValid, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeStopTun", nullptr, nativeStopTun, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeStartTun", nullptr, nativeStartTun, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryGroupNames", nullptr, nativeQueryGroupNames, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryGroup", nullptr, nativeQueryGroup, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeLoad", nullptr, nativeLoad, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryTunnelState", nullptr, nativeQueryTunnelState, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeWriteOverride", nullptr, nativeWriteOverride, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeReadOverride", nullptr, nativeReadOverride, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeClearOverride", nullptr, nativeClearOverride, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativePatchSelector", nullptr, nativePatchSelector, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeHealthCheckAll", nullptr, nativeHealthCheckAll, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeInit", nullptr, nativeInit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeHealthCheck", nullptr, nativeHealthCheck, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeReset", nullptr, nativeReset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeForceGc", nullptr, nativeForceGc, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeSuspend", nullptr, nativeSuspend, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryProviders", nullptr, nativeQueryProviders, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeUpdateProvider", nullptr, nativeUpdateProvider, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryTrafficNow", nullptr, nativeQueryTrafficNow, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryTrafficTotal", nullptr, nativeQueryTrafficTotal, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeStartHttp", nullptr, nativeStartHttp, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeStopHttp", nullptr, nativeStopHttp, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeInstallSideloadGeoip", nullptr, nativeInstallSideloadGeoip, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeSubscribeLogcat", nullptr, nativeSubscribeLogcat, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeCoreVersion", nullptr, nativeCoreVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "nativeQueryConfiguration", nullptr, nativeQueryConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}
