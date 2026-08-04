import Foundation
@testable import StorageScopeCore
import XCTest

final class FullDiskAccessProbeTests: XCTestCase {
    func testPermissionDenialStopsBeforeOtherPrivateFolders() {
        let probe = FullDiskAccessProbe(homeURL: testHomeURL) { url in
            if url.pathExtension == "db" {
                throw NSError(
                    domain: NSCocoaErrorDomain,
                    code: CocoaError.fileReadNoPermission.rawValue
                )
            }
        }

        XCTAssertEqual(probe.status(), .denied)
    }

    func testReadableProtectedDatabaseReportsGranted() {
        let probe = FullDiskAccessProbe(
            homeURL: testHomeURL,
            accessProtectedLocation: { _ in }
        )

        XCTAssertEqual(probe.status(), .granted)
    }

    func testMissingProbeLocationsReportUnknown() {
        let probe = FullDiskAccessProbe(homeURL: testHomeURL) { _ in
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: CocoaError.fileNoSuchFile.rawValue
            )
        }

        XCTAssertEqual(probe.status(), .unknown)
    }

    private var testHomeURL: URL {
        URL(fileURLWithPath: "/tmp/full-disk-access-probe-tests")
    }
}
