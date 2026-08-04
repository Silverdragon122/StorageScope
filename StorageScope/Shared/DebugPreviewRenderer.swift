#if DEBUG
import AppKit
import SwiftUI

@MainActor
enum DebugPreviewRenderer {
    private static var renderTask: Task<Void, Never>?
    private static var previewWindow: NSWindow?

    static func preparePreviewWindowIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard
            arguments.contains("--render-storage-map"),
            let preview = previewContent(arguments: arguments)
        else {
            return
        }

        Task { @MainActor in
            await Task.yield()
            let window = NSWindow(
                contentRect: CGRect(origin: .zero, size: preview.size),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.appearance = NSAppearance(named: .darkAqua)
            window.backgroundColor = .windowBackgroundColor
            window.contentViewController = NSHostingController(
                rootView: preview.content
                    .frame(
                        width: preview.size.width,
                        height: preview.size.height
                    )
            )
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            previewWindow = window
        }
    }

    static func renderIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard
            renderTask == nil,
            let flagIndex = arguments.firstIndex(of: "--render-storage-map"),
            arguments.indices.contains(flagIndex + 1)
        else {
            return
        }

        let outputURL = URL(fileURLWithPath: arguments[flagIndex + 1])
        renderTask = Task { @MainActor in
            await renderWhenReady(to: outputURL)
            NSApp.terminate(nil)
        }
    }

    private static func renderWhenReady(to outputURL: URL) async {
        var previousSize: CGSize?
        var stableLayoutPasses = 0

        for _ in 0..<120 {
            guard !Task.isCancelled else { return }

            if let hostingView = renderableView() {
                hostingView.layoutSubtreeIfNeeded()
                hostingView.displayIfNeeded()

                let size = hostingView.bounds.size
                if size.width > 0, size.height > 0, size == previousSize {
                    stableLayoutPasses += 1
                } else {
                    previousSize = size
                    stableLayoutPasses = 0
                }

                if stableLayoutPasses >= 2, render(hostingView, to: outputURL) {
                    return
                }
            }

            try? await Task.sleep(for: .milliseconds(16))
        }
    }

    private static func renderableView() -> NSView? {
        let window = previewWindow
            ?? NSApp.keyWindow
            ?? NSApp.windows.first(where: { $0.isVisible })
        return window?.contentView
    }

    private static func render(_ hostingView: NSView, to outputURL: URL) -> Bool {
        guard
            let bitmap = hostingView.bitmapImageRepForCachingDisplay(
                in: hostingView.bounds
            )
        else {
            return false
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }
        do {
            try pngData.write(to: outputURL, options: [.atomic])
            return true
        } catch {
            return false
        }
    }

    private static func previewContent(
        arguments: [String]
    ) -> (content: AnyView, size: CGSize)? {
        if arguments.contains("--preview-cleanup-review") {
            return (
                AnyView(
                    CleanupReviewSheet(
                        model: CleanupPreviewData.cleanupReviewModel()
                    )
                ),
                CGSize(width: 680, height: 220)
            )
        }
        if arguments.contains("--preview-cleanup-completion") {
            return (
                AnyView(
                    CleanupCompletionView(
                        report: CleanupPreviewData.completionReport,
                        done: {}
                    )
                ),
                CGSize(width: 680, height: 230)
            )
        }
        if arguments.contains("--preview-settings") {
            return (
                AnyView(CleanupSettingsView()),
                CGSize(width: 500, height: 540)
            )
        }
        if arguments.contains("--preview-details"),
           let item = CleanupPreviewData.loadedReport.items.first
        {
            return (
                AnyView(
                    StorageItemDetailsView(
                        item: item,
                        showsFileCount: true,
                        reveal: {},
                        close: {}
                    )
                ),
                CGSize(width: 340, height: 640)
            )
        }
        if arguments.contains("--preview-limited-access") {
            return (
                AnyView(
                    ContentView(
                        model: CleanupPreviewData.model(
                            report: CleanupPreviewData.limitedReport
                        )
                    )
                ),
                CGSize(width: 1120, height: 720)
            )
        }
        return (
            AnyView(
                ContentView(
                    model: CleanupPreviewData.model(
                        report: CleanupPreviewData.loadedReport
                    )
                )
            ),
            CGSize(width: 1120, height: 720)
        )
    }
}
#endif
