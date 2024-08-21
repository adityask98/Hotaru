//
//  DateHelpers.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/02.
//

import Foundation

// Converts Date Object to YYYY-MM-DD. If no argument is provided, it assumes today's date.
func formatDateToYYYYMMDD(_ date: Date = Date()) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: date)
}

//2024-07-23T09:53:00+09:00"
func formatDateFromJSON(_ date: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormatter.date(from: date) ?? Date.now
}

func formatJSONToPrettyStringDate(
    _ dateString: String, dateStyle: DateFormatter.Style = .medium,
    timeStyle: DateFormatter.Style = .short
) -> String? {
    guard let date = ISO8601DateFormatter().date(from: dateString)
    else {
        return "Unknown Date"
    }
    let formatter = DateFormatter()
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: date)
}
