//
//  PieceView.swift
//  MyApp
//
//  Created by Daniel on 23.09.26.
//

import SwiftUI

struct PieceView: View {
    let piece: Piece
    let squareSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    piece.color == .white
                    ? LinearGradient(colors: [.white, Color(white: 0.85)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color(white: 0.3), Color.black], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
            
            Circle()
                .stroke(
                    piece.color == .white ? Color.gray.opacity(0.4) : Color.white.opacity(0.2),
                    lineWidth: 3
                )
                .padding(4)
            
            if piece.isKing {
                Image(systemName: "crown.fill")
                    .foregroundColor(piece.color == .white ? .orange : .yellow)
                    .font(.system(size: squareSize * 0.35))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            }
        }
        .frame(width: squareSize - 12, height: squareSize - 12)
    }
}
