# Security Policy

## Supported versions

Security fixes are made for the latest published version of StorageScope. Please check the latest release before reporting a problem found in an older build.

## Report a vulnerability

Use [GitHub's private vulnerability report](https://github.com/Silverdragon122/StorageScope/security/advisories/new) for security problems. Do not open a public issue or include exploit details in screenshots, discussions, or crash reports.

Include:

- The affected StorageScope and macOS versions
- The security impact
- The smallest reliable set of reproduction steps
- Whether cleanup changed, moved, or removed an unexpected file
- Any relevant path with usernames and private file names replaced
- Logs or proof-of-concept material needed to confirm the problem

Security reports are appropriate for problems such as:

- Cleanup reaching a location outside the item selected by the user
- Authorization or privilege-boundary bypasses
- Symbolic-link, path-replacement, or filesystem-identity issues
- Exposure of private file information
- Unsafe handling of cleanup journals or recovery data

Use the regular [bug report](https://github.com/Silverdragon122/StorageScope/issues/new?template=bug_report.yml) for crashes, incorrect sizes, interface problems, and other issues without a security impact.

Please allow time to investigate and publish a fix before sharing vulnerability details publicly.
