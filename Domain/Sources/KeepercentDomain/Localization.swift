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
//
// `es-419` is sparse: it only overrides the words Latin America says
// differently, and every other key must come from `es`. Foundation does not
// do that per key — once it picks the `es-419` table, a key that table does
// not translate falls back to English — so `DomainCatalog` picks the table
// for each key explicitly.

extension String {
    /// `key` translated into `locale`'s language. Used for whole sentences,
    /// whose interpolations become the catalog's format arguments (and so
    /// may be reordered or pluralized by a translation).
    init(domain key: String.LocalizationValue, locale: Locale) {
        var resource = LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
        resource.locale = DomainCatalog.locale(translating: resource.key, for: locale)
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
            locale: DomainCatalog.locale(translating: key.description, for: locale),
            bundle: .atURL(Bundle.module.bundleURL)
        )
        self.init(localized: resource)
    }
}

enum DomainCatalog {
    /// The locale whose table should translate `key`: `locale` itself when its
    /// own table translates the key, otherwise the next localization Foundation
    /// would match for it (`es-419`, then `es`). A locale with a single match,
    /// such as English or Spain's Spanish, is returned unchanged.
    static func locale(translating key: String, for locale: Locale, in bundle: Bundle = .module) -> Locale {
        let candidates = Bundle.preferredLocalizations(
            from: bundle.localizations,
            forPreferences: [locale.identifier(.bcp47)]
        )
        guard candidates.count > 1,
              let index = candidates.firstIndex(where: { translates(key, in: $0, of: bundle) })
        else { return locale }
        // The first candidate keeps the caller's locale, so its region still
        // formats numbers; a fallback names the localization it borrows from.
        return index == 0 ? locale : Locale(identifier: candidates[index])
    }

    /// Whether `localization`'s compiled table has its own text for `key`.
    /// The catalog compiler copies the key itself into a table for a string it
    /// does not translate, so a value equal to the key counts as missing.
    private static func translates(_ key: String, in localization: String, of bundle: Bundle) -> Bool {
        guard let url = bundle.url(forResource: localization, withExtension: "lproj"),
              let table = Bundle(url: url)
        else { return false }
        let missing = "\u{0}"
        let value = table.localizedString(forKey: key, value: missing, table: nil)
        return value != missing && value != key
    }
}
