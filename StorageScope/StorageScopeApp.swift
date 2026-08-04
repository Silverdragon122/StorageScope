//
//  StorageScopeApp.swift
//  StorageScope
//
import SwiftUI

@main
struct StorageScopeApp: App {
    init() {
#if DEBUG
        DebugPreviewRenderer.preparePreviewWindowIfRequested()
        DebugPreviewRenderer.renderIfRequested()
#endif
    }

    var body: some Scene {
        WindowGroup {
            appContent
#if DEBUG
                .onAppear {
                    DebugPreviewRenderer.renderIfRequested()
                }
#endif
        }
        .defaultSize(width: 1120, height: 720)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
        }

        Settings {
            CleanupSettingsView()
        }
    }

    @ViewBuilder
    private var appContent: some View {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--preview-cleanup-review") {
            CleanupReviewSheet(model: CleanupPreviewData.cleanupReviewModel())
        } else if arguments.contains("--preview-cleanup-completion") {
            CleanupCompletionView(
                report: CleanupPreviewData.completionReport,
                done: {}
            )
        } else if arguments.contains("--preview-settings") {
            CleanupSettingsView()
        } else if arguments.contains("--preview-limited-access") {
            ContentView(
                model: CleanupPreviewData.model(
                    report: CleanupPreviewData.limitedReport
                )
            )
        } else if arguments.contains("--preview-details") {
            ContentView(model: CleanupPreviewData.detailsModel())
        } else if arguments.contains("--preview-storage-map")
            || arguments.contains("--render-storage-map")
        {
            ContentView(
                model: CleanupPreviewData.model(
                    report: CleanupPreviewData.loadedReport
                )
            )
        } else {
            ContentView()
        }
#else
        ContentView()
#endif
    }
}
