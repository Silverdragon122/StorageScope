# StorageScope — implementation checklist

This checklist is the release ledger for the first complete product slice. A checked item must have code or command output that proves it.

## Safety contract

- [ ] Only an item returned by the current scan can enter a cleanup request.
- [ ] Every cleanup request is matched back to a fixed catalog rule.
- [ ] Protected and ambiguous storage is never selectable.
- [ ] Paths are revalidated immediately before cleanup.
- [ ] Symbolic links are never followed.
- [ ] Mounted volumes and device filesystem nodes stop cleanup; named pipes and Unix sockets are unlinked as leaf entries.
- [ ] A selected item must still have the same filesystem identity found during scanning.
- [ ] Cleanup is blocked while an affected application is open.
- [ ] Catalog-approved system locations request administrator approval only when cleanup begins.
- [ ] File cleanup uses an isolated staging location on the same volume before permanent removal.
- [ ] An interrupted cleanup restores staged items instead of deleting them later without consent.
- [ ] Partial failures report each item accurately and never broaden the request.
- [ ] No shell command accepts user-controlled text.

## Analysis coverage

- [ ] Xcode build, preview, archive, device-support, test-device, and simulator storage.
- [ ] Swift, Homebrew, Node, Python, Rust, Java, Android, and IDE caches.
- [ ] Final Cut Pro, iMovie, Adobe, and DaVinci generated media and caches.
- [ ] Browser, communication-app, container, and general application caches.
- [ ] Logs, diagnostic reports, saved state, Trash, and software-update downloads.
- [ ] iPhone and iPad backups.
- [ ] Local model stores.
- [ ] Virtual machines, cloud data, mail, messages, and general application data as protected information.
- [ ] Apple-managed update assets, Preboot data, swap, snapshots, and other protected system storage as read-only information.
- [ ] Permission failures and unavailable locations are visible without aborting the rest of the scan.
- [ ] Allocated-size estimates avoid following links, crossing volumes, and double-counting files already attributed to a more specific result.

## Product flow

- [ ] First launch begins with a useful scan state.
- [ ] Results are grouped in plain language and show estimated size.
- [ ] The user can filter, search, inspect, and select eligible items.
- [ ] Reclaimable, review-required, and protected items are distinguishable without relying on color.
- [ ] Review names every selected item and its consequence.
- [ ] Permanent deletion requires a deliberate final action.
- [ ] Progress, cancellation, empty, limited-access, partial-failure, and success states are complete.
- [ ] The interface works with window resizing, keyboard navigation, VoiceOver, increased contrast, and Reduce Motion.
- [ ] Visible copy is short, literal, and free of implementation language.

## Verification

- [ ] Core tests cover catalog boundaries, scanning, links, identity changes, authorization, staging, recovery, active-app blocking, and partial failures.
- [ ] Swift 6 build passes without concurrency warnings.
- [ ] Debug app build passes.
- [ ] Release app build passes.
- [ ] Static Apple-platform and SwiftUI audits are reviewed.
- [ ] The live macOS app is exercised with representative normal, empty, limited-access, and review states.
- [ ] Final screenshots are inspected at narrow and wide window sizes.
