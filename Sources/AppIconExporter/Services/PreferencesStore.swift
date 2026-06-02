import Foundation

public protocol PreferencesStoreing: AnyObject {
    func loadDefaultDirectory() -> URL?
    func saveDefaultDirectory(_ url: URL?)
}

public final class UserDefaultsPreferencesStore: PreferencesStoreing {
    private let userDefaults: UserDefaults
    private let fallbackUserDefaults: UserDefaults?
    private let key: String

    public init(
        userDefaults: UserDefaults = .standard,
        fallbackUserDefaults: UserDefaults? = UserDefaults(suiteName: "com.shuai.app-icon-exporter"),
        key: String = "defaultExportDirectoryPath"
    ) {
        self.userDefaults = userDefaults
        self.fallbackUserDefaults = fallbackUserDefaults
        self.key = key
    }

    public func loadDefaultDirectory() -> URL? {
        let path = userDefaults.string(forKey: key) ?? fallbackUserDefaults?.string(forKey: key)
        guard let path, !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    public func saveDefaultDirectory(_ url: URL?) {
        if let url {
            userDefaults.set(url.path, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}
