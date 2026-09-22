//
//  WeakBox.swift
//  Simplification
//
//  Created by 007 on 2026/9/22.
//

import Foundation

final class WeakBox {
    weak var value : AnyObject?
    
    init(value: AnyObject? = nil) {
        self.value = value
    }
    
}
