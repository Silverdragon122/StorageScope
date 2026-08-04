# Rule source notes

The catalog intentionally favors exact, vendor-documented cache and package locations. A location that can contain projects, credentials, offline media, sync state, user content, or unsaved work is protected or review-only even when the owning tool offers a reset command.

The expanded rules in `StorageScope/Core/Catalog/CleanupCatalog+ExpandedRules.swift` were checked against these sources on 2026-07-30:

| Rule family | Source | Safety decision |
| --- | --- | --- |
| Zoom | [Zoom: Clearing Zoom cache and cookies](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0058835) | The documented `data` directory is review-only because the app can require sign-in again. |
| Epic Games Launcher | [Epic Games Store: Clear the Launcher cache](https://www.epicgames.com/help/c-202300000001736/a202300000013316?lang=en-US) | Only named `webcache` directories are reclaimable. |
| Godot | [Godot: Data paths](https://docs.godotengine.org/en/3.3/tutorials/io/data_paths.html) | Godot's macOS cache directory is reclaimable while the editor is closed. |
| Microsoft Teams | [Microsoft Learn: Clear the Teams client cache](https://learn.microsoft.com/en-us/microsoftteams/troubleshoot/teams-administration/clear-teams-cache) | Only the new client's `Caches` subdirectory is reclaimable; the wider app and group containers remain out of scope. |
| Dropbox | [Dropbox Help: Clear the Dropbox cache folder](https://help.dropbox.com/delete-restore/cache-folder) | Exact `.dropbox.cache` folders are review-only because they can stage active transfers and their File Provider location is OS-managed. |
| Ableton Live | [Ableton: The Live Browser](https://help.ableton.com/hc/en-us/articles/209774665-The-Live-Browser) | Pack installer downloads are reclaimable; the User Library and Packs stay protected. |
| OBS Studio | [OBS Forum: crash logs on macOS](https://obsproject.com/forum/threads/crashes-before-opening.109256/post-422256) | Logs and crash reports are reclaimable, with the expected loss of troubleshooting history. |
| Audacity | [Audacity: Directories Preferences](https://manual.audacityteam.org/man/directories_preferences.html) | Session data is protected because it can contain audio that has not been saved as a project. |
| Krita | [Krita: Resource Management](https://docs.krita.org/en/reference_manual/resource_management.html) | The resource folder and SQLite index are protected because they include custom resources and metadata. |
| Terraform | [HashiCorp: CLI configuration and provider plugin cache](https://developer.hashicorp.com/terraform/cli/config/config-file) | Provider binaries are review-only; the cache can be shared by concurrent `terraform init` runs and is configurable. |
| Pulumi | [Pulumi: How Pulumi works](https://www.pulumi.com/docs/intro/concepts/how-pulumi-works/) | Provider plugins are review-only and can be removed with Pulumi-aware commands. |
| Dart and Flutter | [Dart: `dart pub cache`](https://dart.dev/tools/pub/cmd/pub-cache) | The shared package cache is review-only because globally activated tools also use it. |
| Julia | [Julia: Modules and precompiled caches](https://docs.julialang.org/en/v1/manual/modules/) | Only compiled package images are reclaimable; the broader Julia depot is not scanned as disposable data. |
| Elixir build tooling | [HexDocs: `mix mob.cache`](https://hexdocs.pm/mob_dev/Mix.Tasks.Mob.Cache.html) | Only the `elixir_make` native-artifact cache is reclaimable; Hex and Mix state remain out of scope. |
| Safari Technology Preview | [WebKit bug 260001: website-data path](https://bugs.webkit.org/show_bug.cgi?id=260001) | Website data is protected because it includes cookies, local storage, and service-worker state. |
| Google Drive for desktop | [Google Drive Help: local cached files](https://support.google.com/drive/answer/2565956?co=GENIE.Platform%3DDesktop&hl=en) | DriveFS is protected because offline content and account metadata are managed by the sync client. |

Vendor settings can move several of these locations to another volume or custom directory. The current catalog only claims the documented macOS defaults; it does not guess at arbitrary user-selected cache paths.
