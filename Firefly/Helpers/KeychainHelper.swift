import Foundation

enum KeychainError: Error {
    case encodingFailed(Error)
    case unhandledStatus(OSStatus)
}

final class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    func save<T: Codable>(_ item: T, service: String, account: String) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(item)
        } catch {
            throw KeychainError.encodingFailed(error)
        }
        try save(data, service: service, account: account)
    }

    func save(_ data: Data, service: String, account: String) throws {
        let query =
            [
                kSecValueData: data,
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                // Readable after first unlock; never synced or restored to another device
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ] as CFDictionary

        let status = SecItemAdd(query, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let query =
                [
                    kSecAttrService: service,
                    kSecAttrAccount: account,
                    kSecClass: kSecClassGenericPassword,
                ] as CFDictionary

            // Including accessibility here migrates items saved before it was set explicitly
            let attributesToUpdate =
                [
                    kSecValueData: data,
                    kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                ] as CFDictionary

            let updateStatus = SecItemUpdate(query, attributesToUpdate)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledStatus(updateStatus)
            }
        default:
            throw KeychainError.unhandledStatus(status)
        }
    }

    func read<T: Codable>(service: String, account: String, type: T.Type) -> T? {
        guard let data = read(service: service, account: account) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLog.appError("Failed to decode keychain item", error)
            return nil
        }
    }

    func read(service: String, account: String) -> Data? {
        let query =
            [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
                kSecReturnData: true,
            ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                AppLog.app.error("Keychain read failed with status \(status)")
            }
            return nil
        }

        return result as? Data
    }

    func delete(service: String, account: String) {
        let query =
            [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary

        let status = SecItemDelete(query)
        if status != errSecSuccess, status != errSecItemNotFound {
            AppLog.app.error("Keychain delete failed with status \(status)")
        }
    }
}
