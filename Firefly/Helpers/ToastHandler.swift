//
//  ToastHandler.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/14.
//

import AlertToast
import Foundation

class AlertViewModel: ObservableObject {
    @Published var show: Bool = false
    @Published var alertToast = AlertToast(type: .regular, title: "SOME TITLE") {
        didSet {
            show.toggle()
        }
    }
}
