//
//  Piece.swift
//  MyApp
//
//  Created by Daniel on 23.09.26.
//

import Foundation
import SwiftUI

enum PieceColor {
    case white
    case black
}

struct Piece: Identifiable, Equatable {
    let id = UUID()
    var row: Int
    var col: Int
    var color: PieceColor
    var isKing: Bool = false
    
    mutating func makeKing() {
        self.isKing = true
    }
}
