#include "trace.h"

#if ENABLE_TRACE

void trace_method_exit(const char **name) {
     OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, TAG, "TRACE-OUT %{public}s", *name);
}

#endif