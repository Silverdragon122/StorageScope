import Testing
@testable import StorageScopeCore

@Suite("Localization")
struct LocalizationTests {
    @Test
    func productNameAndPluralCopyResolveFromTheCatalog() {
        #expect(AppCopy.name == "StorageScope")
        #expect(AppCopy.Count.items(1) == "1 item")
        #expect(AppCopy.Count.items(2) == "2 items")
        #expect(AppCopy.Count.files(1) == "1 file")
        #expect(AppCopy.Count.files(2) == "2 files")
    }

    @Test
    func formattedCleanupCopyKeepsArgumentsInTheLocalizedSentence() {
        #expect(
            AppCopy.Results.selectedEstimated(count: 2, size: "4 GB")
                == "2 items · 4 GB estimated"
        )
        #expect(
            AppCopy.Review.quitMessage(
                applicationCount: 2,
                applicationList: "Mail and Safari"
            ).contains("Mail and Safari are using selected files")
        )
    }

    @Test
    func standardCatalogUsesLocalizedRuleCopy() throws {
        let rule = try #require(
            CleanupCatalog.standard.rule(id: "xcode-derived-data")
        )

        #expect(rule.locationName == "Xcode build files")
        #expect(rule.itemDetail == "Files Xcode creates while compiling projects.")
    }
}
