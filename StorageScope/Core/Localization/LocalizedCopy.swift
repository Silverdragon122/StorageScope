import Foundation

enum LocalizedCopy {
    #if SWIFT_PACKAGE
    private static let bundle = Bundle.module
    #else
    private static let bundle = Bundle.main
    #endif

    static func text(_ key: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: bundle,
            value: key,
            comment: ""
        )
    }

    static func text(_ key: String, fallback: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: bundle,
            value: fallback,
            comment: ""
        )
    }

    static func format(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: bundle)
    }

    static func catalogField(
        ruleID: String,
        field: String,
        fallback: String
    ) -> String {
        text("catalog.\(ruleID).\(field)", fallback: fallback)
    }

    static func catalogDynamicTitle(
        ruleID: String,
        value: String,
        fallbackFormat: String
    ) -> String {
        let format = text(
            "catalog.\(ruleID).dynamic-title %@",
            fallback: fallbackFormat
        )
        return String(
            format: format,
            locale: Locale.current,
            arguments: [value]
        )
    }
}

enum AppCopy {
    static var name: String { LocalizedCopy.text("app.name") }
}
