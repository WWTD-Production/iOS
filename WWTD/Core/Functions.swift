//
//  Functions.swift
//  Diddly
//
//  Created by Adrian Martushev on 6/20/24.
//

import Foundation
import UIKit
import Firebase

let database = Firestore.firestore()

func generateHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred()
}

// Function to generate a random 8-character alphanumeric ID
func generateRandomID(length: Int = 8) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).compactMap{ _ in letters.randomElement() })
}


extension Int {
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

func formatDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let day = calendar.component(.day, from: date).ordinal
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM yyyy"
    return "\(dateFormatter.string(from: date)) \(day)"
}


func formatTravelDates(start: Date, end: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM d"
    
    let startString = dateFormatter.string(from: start)
    let endString: String
    
    // Check if the start and end dates are in the same month
    if Calendar.current.isDate(start, equalTo: end, toGranularity: .month) {
        dateFormatter.dateFormat = "d"
        endString = dateFormatter.string(from: end)
    } else {
        endString = dateFormatter.string(from: end)
    }
    
    dateFormatter.dateFormat = "yyyy"
    let yearString = dateFormatter.string(from: end)
    
    return "\(ordinalSuffix(for: startString))-\(ordinalSuffix(for: endString)), \(yearString)"
}

private func ordinalSuffix(for dayString: String) -> String {
    guard let dayInt = Int(dayString) else { return dayString }
    
    let suffixes = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
    let index = dayInt % 10
    let century = dayInt % 100
    if century >= 11 && century <= 13 {
        return "\(dayInt)th"
    }
    
    return "\(dayInt)\(suffixes[index])"
}
