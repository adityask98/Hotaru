//
//  TokenAccess.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/05.
//

import Foundation
import Security

class TokenAccess {
    func saveToken(token: String) {
        let accessGroup = Bundle.main.object(forInfoDictionaryKey: "FireflyApp") as? String
        
        let keychainItem = [
            kSecClass: kSecClassGenericPassword,
            
            
        ]
    }
    
}
