#pragma once

#include "bridge.h"

#include <hilog/log.h>

#define ENABLE_TRACE 1

#if ENABLE_TRACE

extern void trace_method_exit(const char **name);

#define TRACE_METHOD() __attribute__((cleanup(trace_method_exit))) const char *__method_name = __FUNCTION__; OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, TAG, "TRACE-IN  %{public}s", __method_name) 

#else

#define TRACE_METHOD()

#endif