#pragma once

#include <stddef.h>
#include <stdint.h>
#include <malloc.h>
#include <hilog/log.h>

#define TAG "ClashMetaForHarmonyOS"

typedef const char *c_string;

typedef void (*mark_socket_func)(void *tun_interface, int fd);

typedef int (*query_socket_uid_func)(void *tun_interface, int protocol, const char *source, const char *target);

typedef void (*complete_func)(void *completable, const char *exception);

// typedef void (*fetch_report_func)(void *fetch_callback, const char *status_json);

typedef void (*fetch_complete_func)(const char *status_json, const char *error);

typedef int (*logcat_received_func)(void *logcat_interface, const char *payload);

// typedef void (*release_object_func)(void *obj);

// typedef int (*open_content_func)(const char *url, char *error, int error_length);

// cgo
extern void mark_socket(void *interface, int fd);

extern int query_socket_uid(void *interface, int protocol, char *source, char *target);

extern void complete(void *obj, char *error);

extern void fetch_complete(void *completable, char *exception);

extern void fetch_report(void *fetch_callback, char *status_json);

extern int logcat_received(void *logcat_interface, char *payload);

extern void release_object(void *obj);

extern int open_content(char *url, char *error, int error_length);

extern void log_info(char *msg);

extern void log_error(char *msg);

extern void log_warn(char *msg);

extern void log_debug(char *msg);

extern void log_verbose(char *msg);