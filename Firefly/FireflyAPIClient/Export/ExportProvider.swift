import Foundation

enum ExportError: Error {
    case invalidResponse(statusCode: Int?)
}

/// Downloads every transaction as Firefly III's own CSV export. This is the API version of the
/// web UI's "Export all transactions" button.
///
/// The web button exports from the first transaction on record up to today, across all accounts.
/// The API endpoint needs an explicit range, so `start` is a date earlier than any real
/// transaction (the server only filters on it) and `end` is today, as on the web. Leaving out
/// `accounts` exports every account, as on the web.
///
/// Returns a file in the temporary directory, named like the web UI's download.
func downloadAllTransactionsExport() async throws -> URL {
    var request = try RequestBuilder(apiURL: DataExportApiPaths.transactions)
    request.url?.append(queryItems: [
        URLQueryItem(name: "start", value: "1900-01-01"),
        URLQueryItem(name: "end", value: formatDateToYYYYMMDD()),
        URLQueryItem(name: "type", value: "csv"),
    ])
    // The server builds the whole file before sending any of it, which can take longer than the
    // default 60 seconds on a large ledger.
    request.timeoutInterval = 300

    let (downloadedURL, response) = try await AppNetworking.session.download(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw ExportError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode)
    }

    let fileName = formatDateToYYYYMMDD().replacingOccurrences(of: "-", with: "_") + "_transaction_export.csv"
    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try? FileManager.default.removeItem(at: destination)
    try FileManager.default.moveItem(at: downloadedURL, to: destination)
    return destination
}
