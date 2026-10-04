import Foundation

// Every user-visible phrase Domain builds comes from this package's own
// string catalog (Resources/Localizable.xcstrings): English, Spain's
// Spanish (`es`) and Latin American Spanish (`es-419`).
//
// The language is chosen by an explicit `Locale` instead of the process's
// preferred languages: the app passes `.current`, and tests pin `en`,
// `es_ES` or `es_AR` so their expectations never depend on the machine.
// `LocalizedStringResource` is the Foundation type that honors a locale
// when it looks a string up; the plain `String(localized:)` initializer
// only uses its locale to format numbers.

extension String {
    /// `key` translated into `locale`'s language. Used for whole sentences,
    /// whose interpolations become the catalog's format arguments (and so
    /// may be reordered or pluralized by a translation).
    init(domain key: String.LocalizationValue, locale: Locale) {
        var resource = LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
        resource.locale = locale
        self.init(localized: resource)
    }

    /// The value stored under a stable `key` in `locale`'s language, falling
    /// back to `defaultValue`. Used for short names ("center", "top") whose
    /// English text alone is ambiguous: a court sector and a goal column
    /// are both "center" in English but not in Spanish.
    init(domainKey key: StaticString, defaultValue: String.LocalizationValue, locale: Locale) {
        let resource = LocalizedStringResource(
            key,
            defaultValue: defaultValue,
            locale: locale,
            bundle: .atURL(Bundle.module.bundleURL)
        )
        self.init(localized: resource)
    }
}
