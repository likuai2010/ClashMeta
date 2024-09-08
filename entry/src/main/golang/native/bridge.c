#include "bridge.h"
#include "trace.h"
#include <stdio.h>
// void (*mark_socket_func)(void *tun_interface, int fd);

// int (*query_socket_uid_func)(void *tun_interface, int protocol, const char *source, const char *target);

// void (*complete_func)(void *completable, const char *exception);

// void (*fetch_report_func)(void *fetch_callback, const char *status_json);

// void (*fetch_complete_func)(void *fetch_callback, const char *error);

// int (*logcat_received_func)(void *logcat_interface, const char *payload);

// int (*open_content_func)(const char *url, char *error, int error_length);

// void (*release_object_func)(void *obj);


void mark_socket(void *interface, int fd) {
    TRACE_METHOD();
    mark_socket_func func = (mark_socket_func)(interface);
    func(interface, fd);
}

int query_socket_uid(void *interface, int protocol, char *source, char *target) {
    TRACE_METHOD();
 // ohos 暂时不支持
//     int result = query_socket_uid_func(interface, protocol, source, target);

    free(source);
    free(target);

    return -1;
}

void complete(void *obj, char *error) {
    TRACE_METHOD();

    complete_func func = (complete_func)(obj);
    func(obj, error);

    free(error);
}

void fetch_complete(void *fetch_callback, char *exception) {
    TRACE_METHOD();
    fetch_complete_func func = (fetch_complete_func)(fetch_callback);
    func("fetch_complete", exception);

    free(exception);
}

void fetch_report(void *fetch_callback, char *json_status) {
    TRACE_METHOD();

    fetch_complete_func func = (fetch_complete_func)(fetch_callback);
    func("fetch_report", json_status);

    free(json_status);
}

int logcat_received(void *logcat_interface, char *payload) {
    TRACE_METHOD();

    logcat_received_func func = (logcat_received_func)(logcat_interface);
    int result = func(logcat_interface, payload);

    free(payload);

    return result;
}

int open_content(char *url, char *error, int error_length) {
    TRACE_METHOD();
    // ohos 暂时不支持
    // int result = open_content_func(url, error, error_length);

    free(url);

    return -1;
}

void release_object(void *obj) {
    TRACE_METHOD();

    //release_object_func(obj);
}

void log_info(char *msg) {
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, TAG, "%{public}s", msg);
    free(msg);
}

void log_error(char *msg) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN,TAG, "%{public}s", msg);

    free(msg);
}

void log_warn(char *msg) {
    OH_LOG_Print(LOG_APP, LOG_WARN, LOG_DOMAIN, TAG, "%{public}s", msg);

    free(msg);
}

void log_debug(char *msg) {
    OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, TAG, "%{public}s", msg);

    free(msg);
}

void log_verbose(char *msg) {
    OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, TAG, "%{public}s", msg);
    free(msg);
}
