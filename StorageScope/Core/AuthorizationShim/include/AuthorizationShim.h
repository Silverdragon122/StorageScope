#ifndef AuthorizationShim_h
#define AuthorizationShim_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *NSDAuthorizationSession;

enum {
    NSDAuthorizationResultSucceeded = 0,
    NSDAuthorizationResultCanceled = 1,
    NSDAuthorizationResultFailed = 2
};

NSDAuthorizationSession NSDAuthorizationSessionCreate(
    const char *recoveryRootPath
);
void NSDAuthorizationSessionDestroy(NSDAuthorizationSession session);

int32_t NSDAuthorizationMovePathsAreAllowed(
    const char *recoveryRootPath,
    const char *sourcePath,
    const char *destinationPath
);

int32_t NSDAuthorizationRemovalPathIsAllowed(
    const char *recoveryRootPath,
    const char *path
);

int32_t NSDAuthorizationMoveItem(
    NSDAuthorizationSession session,
    const char *sourcePath,
    const char *destinationPath,
    const char *prompt
);

int32_t NSDAuthorizationRemoveItem(
    NSDAuthorizationSession session,
    const char *path,
    const char *prompt
);

#ifdef __cplusplus
}
#endif

#endif
