//
//  ContentView.swift
//  StorageScope
//
import AppKit
import SwiftUI

struct ContentView: View {
    @State private var model: CleanupScreenModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(CleanupPreferences.showProtectedItemsKey)
    private var showsProtectedItems = true
    @AppStorage(CleanupPreferences.showFileCountsKey)
    private var showsFileCounts = true
    @AppStorage(CleanupPreferences.itemSortOrderKey)
    private var sortOrderRawValue = CleanupItemSortOrder.largestFirst.rawValue

    init(model: CleanupScreenModel = CleanupScreenModel()) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            CleanupSidebar(model: model)
                .navigationSplitViewColumnWidth(min: 210, ideal: 236, max: 280)
        } detail: {
            CleanupResultsView(
                model: model,
                sortOrderRawValue: $sortOrderRawValue
            )
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $model.isReviewPresented) {
            CleanupReviewSheet(model: model)
        }
        .inspector(isPresented: inspectorBinding) {
            if let item = model.inspectedItem {
                StorageItemDetailsView(
                    item: item,
                    showsFileCount: model.showsFileCounts,
                    reveal: { model.reveal(item) },
                    close: model.closeInspector
                )
                .frame(minWidth: 300, idealWidth: 340, maxWidth: 420)
            }
        }
        .frame(minWidth: 860, minHeight: 580)
        .tint(UtilityTheme.accent)
        .background(UtilityTheme.canvas)
        .animation(
            reduceMotion ? nil : .snappy(duration: 0.24),
            value: model.inspectedItemID
        )
        .onAppear {
            syncDisplayPreferences()
            model.prepare()
        }
        .onChange(of: showsProtectedItems) {
            syncDisplayPreferences()
        }
        .onChange(of: showsFileCounts) {
            syncDisplayPreferences()
        }
        .onChange(of: sortOrderRawValue) {
            syncDisplayPreferences()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            guard model.isWaitingForFullDiskAccessSettings else {
                return
            }
            model.refreshFullDiskAccess()
        }
        .onDisappear {
            model.cancelScan()
        }
    }

    private func syncDisplayPreferences() {
        model.applyDisplayPreferences(
            showsProtectedItems: showsProtectedItems,
            showsFileCounts: showsFileCounts,
            sortOrderRawValue: sortOrderRawValue
        )
    }

    private var inspectorBinding: Binding<Bool> {
        Binding(
            get: { model.inspectedItem != nil },
            set: { isPresented in
                if !isPresented {
                    model.closeInspector()
                }
            }
        )
    }
}

#Preview("Results") {
    ContentView(
        model: CleanupPreviewData.model(report: CleanupPreviewData.loadedReport)
    )
        .frame(width: 1120, height: 720)
}

#Preview("Limited Access") {
    ContentView(
        model: CleanupPreviewData.model(report: CleanupPreviewData.limitedReport)
    )
        .frame(width: 1120, height: 720)
}

#Preview("Scanning") {
    ContentView(
        model: CleanupPreviewData.model(
            report: nil,
            progress: CleanupPreviewData.scanningProgress
        )
    )
    .frame(width: 900, height: 600)
}

#Preview("Empty") {
    ContentView(
        model: CleanupPreviewData.model(report: CleanupPreviewData.emptyReport)
    )
        .frame(width: 900, height: 600)
}

#Preview("Dark") {
    ContentView(
        model: CleanupPreviewData.model(report: CleanupPreviewData.loadedReport)
    )
        .frame(width: 1120, height: 720)
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    ContentView(
        model: CleanupPreviewData.model(report: CleanupPreviewData.limitedReport)
    )
        .frame(width: 1120, height: 720)
        .environment(\.dynamicTypeSize, .accessibility2)
}
