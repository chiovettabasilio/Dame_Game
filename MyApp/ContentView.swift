import SwiftUI

struct ContentView: View {
    @StateObject private var board = Board()
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color.black, Color(white: 0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            if board.gameMode == .menu {
                startMenu
            } else {
                gameBoard
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(board: board)
        }
    }
    
    //Startmenü
    var startMenu: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Oberer Header mit Titel und Zahnrad-Button
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CHECKERS")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .tracking(6)
                            .foregroundColor(board.currentTheme.accentColor)
                        Text("TACTICAL EDITION")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(4)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(board.currentTheme.accentColor.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 30)
                .shadow(color: board.currentTheme.accentColor.opacity(0.3), radius: 10, x: 0, y: 0)
                
                // KI - Statistik (Leaderboard)
                statsView
                
                // Spielmodi-Buttons
                VStack(spacing: 12) {
                    MonochromeMenuButton(title: "Spieler vs Spieler", icon: "person.2.fill", accent: board.currentTheme.accentColor) {
                        board.startGame(mode: .pvp)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 2)
                    
                    Text("GEGEN KI")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(3)
                        .foregroundColor(.gray)
                    
                    MonochromeMenuButton(title: "KI: Leicht", icon: "tortoise.fill", accent: board.currentTheme.accentColor) {
                        board.startGame(mode: .pve, difficulty: .easy)
                    }
                    
                    MonochromeMenuButton(title: "KI: Mittel", icon: "hare.fill", accent: board.currentTheme.accentColor) {
                        board.startGame(mode: .pve, difficulty: .medium)
                    }
                    
                    MonochromeMenuButton(title: "KI: Schwer", icon: "flame.fill", accent: board.currentTheme.accentColor) {
                        board.startGame(mode: .pve, difficulty: .hard)
                    }
                    
                    //BLITZ-MODUS
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 2)
                    
                    Text("BLITZ-MODUS (3 MIN + 3S)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(3)
                        .foregroundColor(.gray)
                    
                    MonochromeMenuButton(title: "Blitz: PvP", icon: "bolt.fill", accent: board.currentTheme.accentColor) {
                        board.startTimedGame(mode: .pvp)
                    }
                    
                    MonochromeMenuButton(title: "Blitz: KI (Mittel)", icon: "bolt.circle.fill", accent: board.currentTheme.accentColor) {
                        board.startTimedGame(mode: .pve, difficulty: .medium)
                    }
                }
                .padding(.horizontal, 30)
                
                // Signatur
                Text("Created by Daniel Chiovetta")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .tracking(2)
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.top, 4)
            }
            .padding(.vertical, 20)
        }
    }
    
    // Leaderboard Widget
    var statsView: some View {
        VStack(spacing: 8) {
            Text("KI - STATISTIK (SIEGE - NIEDERLAGEN)")
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                statBadge(difficulty: "Leicht", wins: board.winsEasy, losses: board.lossesEasy)
                statBadge(difficulty: "Mittel", wins: board.winsMedium, losses: board.lossesMedium)
                statBadge(difficulty: "Schwer", wins: board.winsHard, losses: board.lossesHard)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func statBadge(difficulty: String, wins: Int, losses: Int) -> some View {
        VStack(spacing: 4) {
            Text(difficulty)
                .font(.caption2.bold())
                .foregroundColor(board.currentTheme.accentColor)
            
            Text("\(wins) - \(losses)")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    // Spielfeld & HUD
    var gameBoard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation {
                        board.gameMode = .menu
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                
                VStack(spacing: 4) {
                    //TIMER ODER NORMALER TEXT
                    if board.isTimedMode {
                        HStack {
                            Text("W: \(board.formatTime(board.whiteTime))")
                                .font(.caption2.bold())
                                .foregroundColor(board.whiteTime < 20 ? .red : .white)
                            Spacer()
                            Text(board.currentPlayer == .white ? "Weiß am Zug" : "Schwarz am Zug")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("S: \(board.formatTime(board.blackTime))")
                                .font(.caption2.bold())
                                .foregroundColor(board.blackTime < 20 ? .red : .gray)
                        }
                    } else {
                        HStack {
                            Text("Weiß")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Text(board.gameMode == .pve && board.currentPlayer == .black ? "KI denkt..." : (board.currentPlayer == .white ? "Weiß am Zug" : "Schwarz am Zug"))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Schwarz")
                                .font(.caption2.bold())
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Virteilsbalken
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(white: 0.2))
                            
                            Rectangle()
                                .fill(board.currentTheme.accentColor)
                                .frame(width: geometry.size.width * CGFloat(board.getEvaluationProgress()))
                        }
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.white).frame(width: 7, height: 7)
                        Text("\(whitePieceCount())")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.gray).frame(width: 7, height: 7)
                        Text("\(blackPieceCount())")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { col in
                            squareView(row: row, col: col)
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(board.currentTheme.accentColor.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: board.pieces)
            
            Spacer()
        }
        .padding(.vertical)
        .overlay(
            Group {
                if let winner = board.winner {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 44))
                                .foregroundColor(board.currentTheme.accentColor)
                                .shadow(color: board.currentTheme.accentColor.opacity(0.6), radius: 10, x: 0, y: 0)
                            
                            VStack(spacing: 6) {
                                Text(winner == .white ? "WEISS GEWINNT" : "SCHWARZ GEWINNT")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .tracking(3)
                                    .foregroundColor(.white)
                                
                                Text("Taktische Meisterleistung")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            VStack(spacing: 12) {
                                // 1. Nochmal spielen Button
                                Button(action: {
                                    withAnimation {
                                        board.startGame(mode: board.gameMode, difficulty: board.aiDifficulty)
                                    }
                                }) {
                                    Text("Nochmal spielen")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(board.currentTheme.accentColor)
                                        .foregroundColor(.black)
                                        .cornerRadius(14)
                                }
                                                        
                                // 2. NEU: Hauptmenü Button
                                Button(action: {
                                    withAnimation {
                                        board.winner = nil
                                        board.gameMode = .menu
                                    }
                                }) {
                                    Text("Hauptmenü")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(.ultraThinMaterial)
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                    .stroke(board.currentTheme.accentColor.opacity(0.4), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(32)
                        .frame(width: 310)
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(board.currentTheme.accentColor.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.7), radius: 25, x: 0, y: 12)
                    }
                }
            }
        )
    }
    
    private func squareView(row: Int, col: Int) -> some View {
        let isDark = (row + col) % 2 == 1
        let isSelected = board.selectedRow == row && board.selectedCol == col
        let validMoves = board.getValidMoves(forRow: board.selectedRow ?? -1, col: board.selectedCol ?? -1)
        let isValidTarget = validMoves.contains { $0.row == row && $0.col == col }
        let targetInfo = validMoves.first { $0.row == row && $0.col == col }
        
        return ZStack {
            Rectangle()
                .fill(isDark ? Color(white: 0.1) : Color(white: 0.22))
            
            if isValidTarget, let info = targetInfo {
                Circle()
                    .fill(info.isJump ? board.currentTheme.jumpColor : board.currentTheme.stepColor)
                    .frame(width: 16, height: 16)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isSelected)
            }
            
            if let piece = board.getPiece(row: row, col: col) {
                PieceView(piece: piece)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .shadow(color: .black.opacity(isSelected ? 0.6 : 0.3), radius: isSelected ? 8 : 3, x: 0, y: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            board.handleSquareTap(row: row, col: col)
        }
    }
    
    private func whitePieceCount() -> Int {
        board.pieces.joined().compactMap { $0 }.filter { $0.color == .white }.count
    }
    
    private func blackPieceCount() -> Int {
        board.pieces.joined().compactMap { $0 }.filter { $0.color == .black }.count
    }
}

//Einstellungs-Ansicht
struct SettingsView: View {
    @ObservedObject var board: Board
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(white: 0.1).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("EINSTELLUNGEN")
                        .font(.headline.bold())
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Design-Theme Auswahl
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DESIGN THEME")
                                .font(.caption2.bold())
                                .tracking(2)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 10) {
                                ForEach(GameTheme.allCases) { theme in
                                    Button(action: {
                                        board.currentTheme = theme
                                    }) {
                                        Text(theme.rawValue.components(separatedBy: " ")[0])
                                            .font(.caption.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(board.currentTheme == theme ? board.currentTheme.accentColor.opacity(0.25) : Color.white.opacity(0.05))
                                            .foregroundColor(board.currentTheme == theme ? .white : .gray)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(board.currentTheme == theme ? board.currentTheme.accentColor : Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // 2. Haptik / Vibration Schalter
                        Toggle(isOn: $board.isHapticsEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptisches Feedback")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text("Vibration bei Zügen und Sprüngen")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .tint(board.currentTheme == .classic ? Color.gray : board.currentTheme.accentColor)
                        .padding(.vertical, 4)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // 3. Statistik / Leaderboard zurücksetzen
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DATEN & STATISTIK")
                                .font(.caption2.bold())
                                .tracking(2)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                board.resetStats()
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                    Text("Statistiken zurücksetzen")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

//Menü-Button
struct MonochromeMenuButton: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(accent)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 3)
        }
    }
}
