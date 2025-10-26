import Foundation

func printResponse(_ data: Data) {
    if let responseString = String(data: data, encoding: .utf8) {
        print(responseString)
    } else {
        print("Unable to convert data")
    }
}
