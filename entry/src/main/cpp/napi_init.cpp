#include "napi/native_api.h"
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include "myapp.h"

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

typedef void (*mark_socket_func2)(void *tun_interface, int fd);


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

mark_socket_func2 mark_socket_func;

#define LOAD_FUNCTION(handle, func) \
    func = (typeof(func))dlsym(handle, #func); \
    if (!func) { \
        fprintf(stderr, "Failed to load function: %s\n", #func); \
        return nullptr; \
    }



#include <thread>
napi_threadsafe_function tsfn;
struct MyData {
    int fd;
    void *tun_interface;
};
static MyData socket;
void mark_socket(void *tun_interface, int fd){
  
    socket.fd=fd;
    socket.tun_interface=tun_interface;
    napi_call_threadsafe_function(tsfn, &socket, napi_tsfn_blocking);
}
void complete(void *obj, char *error){
    
}
void printFunc(int fd) {
     int dd = startTun(fd,"172.19.0.1/30", "172.19.0.2", "0.0.0.0", (void*)mark_socket);
}


static void Napi_OnVideoStatus(napi_env env, napi_value js_callback, void *context, void *data) {
    MyData* sock = (MyData *)data;
    if (sock == nullptr)
        return ;
    napi_value params[1];
    napi_value result;
    napi_create_int32(env, sock->fd, &result);
    params[0] = result;
    napi_call_function(env, nullptr, js_callback, 1, params, nullptr);
}

static napi_value Add(napi_env env, napi_callback_info info)
{
 
    size_t argc = 3;
    napi_value args[3] = {nullptr};

    napi_get_cb_info(env, info, &argc, args , nullptr, nullptr);
    
    
    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);

    napi_valuetype valuetype1;
    napi_typeof(env, args[1], &valuetype1);
    napi_value resourceName;
    napi_create_string_latin1(env, "onCallback'", NAPI_AUTO_LENGTH, &resourceName);
    napi_create_threadsafe_function(env, args[2], NULL, resourceName, 0, 1, NULL, NULL, NULL, Napi_OnVideoStatus, &tsfn);

    double value0;
    napi_get_value_double(env, args[0], &value0);
    load((void *)&complete, "/storage/Users/currentUser/Download/config");
    std::thread t(printFunc, value0);
    t.join();
    napi_value sum;
    napi_create_double(env, 1, &sum);
  
    return sum;

}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
   mark_socket_func = &mark_socket;
   void *handle = dlopen("myapp.so", RTLD_LAZY);
     const char* dlsym_error = dlerror();
     if (!handle) {
        fprintf(stderr, "Failed to load library: %s\n", dlsym_error);
        return nullptr;
    }
    LOAD_FUNCTION(handle, notifyDnsChanged);
    LOAD_FUNCTION(handle, coreInit);
    LOAD_FUNCTION(handle, stopHttp);
    LOAD_FUNCTION(handle, startTun);
    LOAD_FUNCTION(handle, load);
    LOAD_FUNCTION(handle, mark_socket_func);
    coreInit("/storage/Users/currentUser/Download/", "1.1.1", 30);
    napi_property_descriptor desc[] = {
        { "add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr }
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
