#include "AuthorizationShim.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#include <errno.h>
#include <limits.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <uuid/uuid.h>

enum {
    NSDMaximumPromptLength = 1024,
    NSDMaximumStagedEntryIndex = 99999,
    NSDDefaultUserDatabaseBufferLength = 16384,
    NSDMaximumUserDatabaseBufferLength = 1048576
};

static const char NSDRecoveryRootSuffix[] =
    "/Library/Application Support/StorageScope/Interrupted Cleanups";

typedef struct {
    AuthorizationRef authorization;
    char recoveryRoot[PATH_MAX];
    dev_t recoveryDevice;
    ino_t recoveryInode;
    uid_t owner;
} NSDAuthorizationSessionStorage;

static char NSDMoveToolPath[] = "/bin/mv";
static char NSDRemoveToolPath[] = "/bin/rm";

static bool NSDPathResolvesToItself(const char *path);

static void NSDSecureZero(void *memory, size_t length) {
    volatile unsigned char *bytes = (volatile unsigned char *)memory;
    while (length > 0) {
        *bytes = 0;
        bytes++;
        length--;
    }
}

static bool NSDPathIsCanonicalAbsolute(const char *path) {
    if (path == NULL) {
        return false;
    }

    size_t length = strnlen(path, PATH_MAX);
    if (
        length < 2 || length >= PATH_MAX || path[0] != '/'
            || path[length - 1] == '/'
    ) {
        return false;
    }

    const char *component = path + 1;
    while (*component != '\0') {
        const char *separator = strchr(component, '/');
        size_t componentLength = separator == NULL
            ? strlen(component)
            : (size_t)(separator - component);
        if (
            componentLength == 0
                || (componentLength == 1 && component[0] == '.')
                || (
                    componentLength == 2 && component[0] == '.'
                        && component[1] == '.'
                )
        ) {
            return false;
        }
        if (separator == NULL) {
            break;
        }
        component = separator + 1;
    }
    return true;
}

static bool NSDCopyCanonicalPath(
    const char *path,
    char destination[PATH_MAX]
) {
    if (!NSDPathIsCanonicalAbsolute(path)) {
        return false;
    }
    return strlcpy(destination, path, PATH_MAX) < PATH_MAX;
}

static bool NSDExpectedRecoveryRootPath(char destination[PATH_MAX]) {
    long configuredLength = sysconf(_SC_GETPW_R_SIZE_MAX);
    size_t bufferLength = configuredLength > 0
            && configuredLength <= NSDMaximumUserDatabaseBufferLength
        ? (size_t)configuredLength
        : (size_t)NSDDefaultUserDatabaseBufferLength;
    char *databaseBuffer = NULL;
    struct passwd passwordEntry;
    struct passwd *result = NULL;
    int lookupStatus = ERANGE;

    while (
        lookupStatus == ERANGE
            && bufferLength <= NSDMaximumUserDatabaseBufferLength
    ) {
        char *resizedBuffer = (char *)realloc(databaseBuffer, bufferLength);
        if (resizedBuffer == NULL) {
            free(databaseBuffer);
            return false;
        }
        databaseBuffer = resizedBuffer;
        lookupStatus = getpwuid_r(
            getuid(),
            &passwordEntry,
            databaseBuffer,
            bufferLength,
            &result
        );
        if (lookupStatus == ERANGE) {
            if (bufferLength > NSDMaximumUserDatabaseBufferLength / 2) {
                break;
            }
            bufferLength *= 2;
        }
    }

    char canonicalHome[PATH_MAX];
    bool foundHome = lookupStatus == 0 && result != NULL
        && result->pw_dir != NULL
        && realpath(result->pw_dir, canonicalHome) != NULL;
    free(databaseBuffer);
    if (!foundHome) {
        return false;
    }

    int writtenLength = snprintf(
        destination,
        PATH_MAX,
        "%s%s",
        strcmp(canonicalHome, "/") == 0 ? "" : canonicalHome,
        NSDRecoveryRootSuffix
    );
    return writtenLength > 0 && (size_t)writtenLength < PATH_MAX;
}

static bool NSDRecoveryRootIsExpectedForCurrentUser(const char *path) {
    char expectedPath[PATH_MAX];
    return NSDExpectedRecoveryRootPath(expectedPath)
        && strcmp(path, expectedPath) == 0;
}

static bool NSDAncestorChainIsSafe(const char *path) {
    char ancestorPath[PATH_MAX];
    if (!NSDCopyCanonicalPath(path, ancestorPath)) {
        return false;
    }

    while (true) {
        char *separator = strrchr(ancestorPath, '/');
        if (separator == NULL) {
            return false;
        }
        if (separator == ancestorPath) {
            ancestorPath[1] = '\0';
        } else {
            *separator = '\0';
        }

        struct stat information;
        if (
            lstat(ancestorPath, &information) != 0
                || !S_ISDIR(information.st_mode)
                || (
                    (information.st_mode & 0022) != 0
                        && (information.st_mode & S_ISVTX) == 0
                )
                || !NSDPathResolvesToItself(ancestorPath)
        ) {
            return false;
        }
        if (strcmp(ancestorPath, "/") == 0) {
            return true;
        }
    }
}

static bool NSDPathIsDirectChildOf(
    const char *path,
    const char *root
) {
    size_t rootLength = strlen(root);
    if (
        strncmp(path, root, rootLength) != 0 || path[rootLength] != '/'
    ) {
        return false;
    }

    const char *child = path + rootLength + 1;
    return child[0] != '\0' && strchr(child, '/') == NULL;
}

static bool NSDPathIsApprovedSystemEntry(const char *path) {
    if (!NSDPathIsCanonicalAbsolute(path)) {
        return false;
    }

    return NSDPathIsDirectChildOf(path, "/Library/Caches")
        || NSDPathIsDirectChildOf(path, "/Library/Logs")
        || NSDPathIsDirectChildOf(path, "/cores")
        || strcmp(path, "/Library/Application Support/Adobe") == 0;
}

static bool NSDStringIsCanonicalUnsignedInteger(const char *value) {
    if (value == NULL || value[0] == '\0') {
        return false;
    }
    if (value[0] == '0' && value[1] != '\0') {
        return false;
    }

    for (const char *cursor = value; *cursor != '\0'; cursor++) {
        if (*cursor < '0' || *cursor > '9') {
            return false;
        }
    }

    errno = 0;
    char *end = NULL;
    unsigned long parsed = strtoul(value, &end, 10);
    return errno == 0 && end != NULL && *end == '\0'
        && parsed <= NSDMaximumStagedEntryIndex;
}

static bool NSDPathIsRecoveryEntry(
    const char *recoveryRoot,
    const char *path
) {
    if (
        !NSDPathIsCanonicalAbsolute(recoveryRoot)
            || !NSDPathIsCanonicalAbsolute(path)
    ) {
        return false;
    }

    size_t rootLength = strlen(recoveryRoot);
    if (
        strncmp(path, recoveryRoot, rootLength) != 0
            || path[rootLength] != '/'
    ) {
        return false;
    }

    const char *operationID = path + rootLength + 1;
    const char *separator = strchr(operationID, '/');
    if (separator == NULL || separator == operationID) {
        return false;
    }
    if ((size_t)(separator - operationID) != 36) {
        return false;
    }

    char operationIDBuffer[37];
    memcpy(operationIDBuffer, operationID, 36);
    operationIDBuffer[36] = '\0';
    uuid_t parsedUUID;
    if (uuid_parse(operationIDBuffer, parsedUUID) != 0) {
        return false;
    }
    char canonicalOperationID[37];
    uuid_unparse_upper(parsedUUID, canonicalOperationID);
    if (strcmp(operationIDBuffer, canonicalOperationID) != 0) {
        return false;
    }

    const char *stagedName = separator + 1;
    return strchr(stagedName, '/') == NULL
        && NSDStringIsCanonicalUnsignedInteger(stagedName);
}

static bool NSDMovePathsAreAllowed(
    const char *recoveryRoot,
    const char *sourcePath,
    const char *destinationPath
) {
    return (
        NSDPathIsApprovedSystemEntry(sourcePath)
            && NSDPathIsRecoveryEntry(recoveryRoot, destinationPath)
    ) || (
        NSDPathIsRecoveryEntry(recoveryRoot, sourcePath)
            && NSDPathIsApprovedSystemEntry(destinationPath)
    );
}

int32_t NSDAuthorizationMovePathsAreAllowed(
    const char *recoveryRootPath,
    const char *sourcePath,
    const char *destinationPath
) {
    return NSDMovePathsAreAllowed(
        recoveryRootPath,
        sourcePath,
        destinationPath
    ) ? 1 : 0;
}

int32_t NSDAuthorizationRemovalPathIsAllowed(
    const char *recoveryRootPath,
    const char *path
) {
    return NSDPathIsRecoveryEntry(recoveryRootPath, path) ? 1 : 0;
}

static bool NSDStatIsRegularFileOrDirectory(const struct stat *information) {
    return S_ISREG(information->st_mode) || S_ISDIR(information->st_mode);
}

static bool NSDPathResolvesToItself(const char *path) {
    char resolvedPath[PATH_MAX];
    return realpath(path, resolvedPath) != NULL
        && strcmp(path, resolvedPath) == 0;
}

static bool NSDValidateRecoveryRoot(
    const NSDAuthorizationSessionStorage *session
) {
    struct stat information;
    if (lstat(session->recoveryRoot, &information) != 0) {
        return false;
    }

    return S_ISDIR(information.st_mode)
        && information.st_dev == session->recoveryDevice
        && information.st_ino == session->recoveryInode
        && information.st_uid == session->owner
        && (information.st_mode & 0077) == 0
        && (information.st_mode & 0700) == 0700
        && NSDPathResolvesToItself(session->recoveryRoot)
        && NSDAncestorChainIsSafe(session->recoveryRoot);
}

static bool NSDValidateRecoveryEntryParent(
    const NSDAuthorizationSessionStorage *session,
    const char *entryPath
) {
    if (!NSDPathIsRecoveryEntry(session->recoveryRoot, entryPath)) {
        return false;
    }

    char operationPath[PATH_MAX];
    if (strlcpy(operationPath, entryPath, sizeof(operationPath)) >= sizeof(operationPath)) {
        return false;
    }
    char *separator = strrchr(operationPath, '/');
    if (separator == NULL) {
        return false;
    }
    *separator = '\0';

    struct stat information;
    if (lstat(operationPath, &information) != 0) {
        return false;
    }

    return S_ISDIR(information.st_mode)
        && information.st_dev == session->recoveryDevice
        && information.st_uid == session->owner
        && (information.st_mode & 0077) == 0
        && (information.st_mode & 0700) == 0700
        && NSDPathResolvesToItself(operationPath);
}

static bool NSDValidateExistingPath(
    const char *path,
    dev_t expectedDevice,
    struct stat *information
) {
    if (
        lstat(path, information) != 0
            || !NSDStatIsRegularFileOrDirectory(information)
            || information->st_dev != expectedDevice
    ) {
        return false;
    }
    return NSDPathResolvesToItself(path);
}

static bool NSDValidateMissingDestination(
    const char *path,
    dev_t expectedDevice
) {
    struct stat destinationInformation;
    if (lstat(path, &destinationInformation) == 0 || errno != ENOENT) {
        return false;
    }

    char parentPath[PATH_MAX];
    if (strlcpy(parentPath, path, sizeof(parentPath)) >= sizeof(parentPath)) {
        return false;
    }
    char *separator = strrchr(parentPath, '/');
    if (separator == NULL || separator == parentPath) {
        return false;
    }
    *separator = '\0';

    struct stat parentInformation;
    return lstat(parentPath, &parentInformation) == 0
        && S_ISDIR(parentInformation.st_mode)
        && parentInformation.st_dev == expectedDevice
        && NSDPathResolvesToItself(parentPath);
}

static bool NSDValidateTool(const char *toolPath) {
    struct stat information;
    return lstat(toolPath, &information) == 0
        && S_ISREG(information.st_mode)
        && information.st_uid == 0
        && (information.st_mode & 0022) == 0
        && NSDPathResolvesToItself(toolPath);
}

static int32_t NSDExecute(
    AuthorizationRef authorization,
    char *toolPath,
    char *const arguments[],
    const char *prompt
) {
    size_t promptLength = prompt == NULL
        ? 0
        : strnlen(prompt, NSDMaximumPromptLength + 1);
    if (
        authorization == NULL || promptLength == 0
            || promptLength > NSDMaximumPromptLength
            || !NSDValidateTool(toolPath)
    ) {
        return NSDAuthorizationResultFailed;
    }

    char *promptCopy = strndup(prompt, promptLength);
    if (promptCopy == NULL) {
        return NSDAuthorizationResultFailed;
    }

    AuthorizationItem right = {
        kAuthorizationRightExecute,
        strlen(toolPath),
        toolPath,
        0
    };
    AuthorizationRights rights = {1, &right};
    AuthorizationItem promptItem = {
        kAuthorizationEnvironmentPrompt,
        promptLength,
        promptCopy,
        0
    };
    AuthorizationEnvironment environment = {1, &promptItem};
    AuthorizationFlags flags =
        kAuthorizationFlagInteractionAllowed
        | kAuthorizationFlagExtendRights;
    OSStatus status = AuthorizationCopyRights(
        authorization,
        &rights,
        &environment,
        flags,
        NULL
    );
    if (status == errAuthorizationCanceled) {
        free(promptCopy);
        return NSDAuthorizationResultCanceled;
    }
    if (status != errAuthorizationSuccess) {
        free(promptCopy);
        return NSDAuthorizationResultFailed;
    }

    FILE *communicationsPipe = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    status = AuthorizationExecuteWithPrivileges(
        authorization,
        toolPath,
        kAuthorizationFlagDefaults,
        arguments,
        &communicationsPipe
    );
#pragma clang diagnostic pop
    free(promptCopy);
    if (status == errAuthorizationCanceled) {
        return NSDAuthorizationResultCanceled;
    }
    if (status != errAuthorizationSuccess) {
        return NSDAuthorizationResultFailed;
    }

    bool communicationSucceeded = communicationsPipe != NULL;
    if (communicationsPipe != NULL) {
        char buffer[512];
        while (fread(buffer, 1, sizeof(buffer), communicationsPipe) > 0) {}
        communicationSucceeded = ferror(communicationsPipe) == 0;
        if (fclose(communicationsPipe) != 0) {
            communicationSucceeded = false;
        }
    }
    return communicationSucceeded
        ? NSDAuthorizationResultSucceeded
        : NSDAuthorizationResultFailed;
}

NSDAuthorizationSession NSDAuthorizationSessionCreate(
    const char *recoveryRootPath
) {
    char recoveryRoot[PATH_MAX];
    if (!NSDCopyCanonicalPath(recoveryRootPath, recoveryRoot)) {
        return NULL;
    }

    struct stat recoveryInformation;
    if (
        lstat(recoveryRoot, &recoveryInformation) != 0
            || !S_ISDIR(recoveryInformation.st_mode)
            || !NSDRecoveryRootIsExpectedForCurrentUser(recoveryRoot)
            || recoveryInformation.st_uid != getuid()
            || (recoveryInformation.st_mode & 0077) != 0
            || (recoveryInformation.st_mode & 0700) != 0700
            || !NSDPathResolvesToItself(recoveryRoot)
            || !NSDAncestorChainIsSafe(recoveryRoot)
    ) {
        return NULL;
    }

    AuthorizationRef authorization = NULL;
    OSStatus status = AuthorizationCreate(
        NULL,
        NULL,
        kAuthorizationFlagDefaults,
        &authorization
    );
    if (status != errAuthorizationSuccess || authorization == NULL) {
        return NULL;
    }

    NSDAuthorizationSessionStorage *session = (NSDAuthorizationSessionStorage *)calloc(
        1,
        sizeof(*session)
    );
    if (session == NULL) {
        AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
        return NULL;
    }

    session->authorization = authorization;
    strlcpy(session->recoveryRoot, recoveryRoot, sizeof(session->recoveryRoot));
    session->recoveryDevice = recoveryInformation.st_dev;
    session->recoveryInode = recoveryInformation.st_ino;
    session->owner = recoveryInformation.st_uid;
    return session;
}

void NSDAuthorizationSessionDestroy(NSDAuthorizationSession session) {
    if (session != NULL) {
        NSDAuthorizationSessionStorage *storage =
            (NSDAuthorizationSessionStorage *)session;
        AuthorizationFree(
            storage->authorization,
            kAuthorizationFlagDestroyRights
        );
        NSDSecureZero(storage, sizeof(*storage));
        free(storage);
    }
}

int32_t NSDAuthorizationMoveItem(
    NSDAuthorizationSession session,
    const char *sourcePath,
    const char *destinationPath,
    const char *prompt
) {
    if (
        session == NULL || sourcePath == NULL || destinationPath == NULL
            || prompt == NULL
    ) {
        return NSDAuthorizationResultFailed;
    }

    NSDAuthorizationSessionStorage *storage =
        (NSDAuthorizationSessionStorage *)session;
    if (
        !NSDValidateRecoveryRoot(storage)
            || !NSDMovePathsAreAllowed(
                storage->recoveryRoot,
                sourcePath,
                destinationPath
            )
    ) {
        return NSDAuthorizationResultFailed;
    }

    bool staging = NSDPathIsApprovedSystemEntry(sourcePath);
    const char *recoveryEntryPath = staging ? destinationPath : sourcePath;
    if (!NSDValidateRecoveryEntryParent(storage, recoveryEntryPath)) {
        return NSDAuthorizationResultFailed;
    }

    struct stat sourceInformation;
    if (
        !NSDValidateExistingPath(
            sourcePath,
            storage->recoveryDevice,
            &sourceInformation
        )
            || !NSDValidateMissingDestination(
                destinationPath,
                storage->recoveryDevice
            )
    ) {
        return NSDAuthorizationResultFailed;
    }

    char sourceBuffer[PATH_MAX];
    char destinationBuffer[PATH_MAX];
    if (
        !NSDCopyCanonicalPath(sourcePath, sourceBuffer)
            || !NSDCopyCanonicalPath(destinationPath, destinationBuffer)
    ) {
        return NSDAuthorizationResultFailed;
    }

    char *arguments[] = {
        "-n",
        "-h",
        "--",
        sourceBuffer,
        destinationBuffer,
        NULL
    };
    int32_t result = NSDExecute(
        storage->authorization,
        NSDMoveToolPath,
        arguments,
        prompt
    );
    if (result != NSDAuthorizationResultSucceeded) {
        return result;
    }

    struct stat destinationInformation;
    struct stat remainingSourceInformation;
    bool sourceIsGone = lstat(sourceBuffer, &remainingSourceInformation) != 0
        && errno == ENOENT;
    bool destinationIsSameObject = lstat(
        destinationBuffer,
        &destinationInformation
    ) == 0
        && destinationInformation.st_dev == sourceInformation.st_dev
        && destinationInformation.st_ino == sourceInformation.st_ino
        && (destinationInformation.st_mode & S_IFMT)
            == (sourceInformation.st_mode & S_IFMT);
    return sourceIsGone && destinationIsSameObject
        ? NSDAuthorizationResultSucceeded
        : NSDAuthorizationResultFailed;
}

int32_t NSDAuthorizationRemoveItem(
    NSDAuthorizationSession session,
    const char *path,
    const char *prompt
) {
    if (session == NULL || path == NULL || prompt == NULL) {
        return NSDAuthorizationResultFailed;
    }

    NSDAuthorizationSessionStorage *storage =
        (NSDAuthorizationSessionStorage *)session;
    if (
        !NSDValidateRecoveryRoot(storage)
            || !NSDPathIsRecoveryEntry(storage->recoveryRoot, path)
            || !NSDValidateRecoveryEntryParent(storage, path)
    ) {
        return NSDAuthorizationResultFailed;
    }

    struct stat sourceInformation;
    if (
        !NSDValidateExistingPath(
            path,
            storage->recoveryDevice,
            &sourceInformation
        )
    ) {
        return NSDAuthorizationResultFailed;
    }

    char pathBuffer[PATH_MAX];
    if (!NSDCopyCanonicalPath(path, pathBuffer)) {
        return NSDAuthorizationResultFailed;
    }

    char *arguments[] = {"-rf", "-x", "--", pathBuffer, NULL};
    int32_t result = NSDExecute(
        storage->authorization,
        NSDRemoveToolPath,
        arguments,
        prompt
    );
    if (result != NSDAuthorizationResultSucceeded) {
        return result;
    }

    struct stat remainingInformation;
    return lstat(pathBuffer, &remainingInformation) != 0 && errno == ENOENT
        ? NSDAuthorizationResultSucceeded
        : NSDAuthorizationResultFailed;
}
