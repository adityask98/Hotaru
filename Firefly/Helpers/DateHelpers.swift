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

