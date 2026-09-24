import Foundation
import SwiftUI
import UIKit
import Combine

enum GameMode {
    case menu
    case pvp
    case pve
}

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy = "Leicht"
    case medium = "Mittel"
    case hard = "Schwer"
    
    var id: String { self.rawValue }
    
    var depth: Int {
        switch self {
        case .easy: return 2
        case .medium: return 4
        case .hard: return 5
        }
    }
}

enum GameTheme: String, CaseIterable, Identifiable {
    case classic = "Classic White"
    case cyberpunk = "Cyberpunk Blue"
    case matrix = "Matrix Green"
    
    var id: String { self.rawValue }
    
    var accentColor: Color {
        switch self {
        case .classic: return .white
        case .cyberpunk: return .cyan
        case .matrix: return .green
        }
    }
    
    var jumpColor: Color {
        switch self {
        case .classic: return .red
        case .cyberpunk: return .pink
        case .matrix: return .orange
        }
    }
    
    var stepColor: Color {
        switch self {
        case .classic: return .cyan
        case .cyberpunk: return .blue
        case .matrix: return .green.opacity(0.8)
        }
    }
}

class Board: ObservableObject {
    @Published var pieces: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @Published var selectedRow: Int? = nil
    @Published var selectedCol: Int? = nil
    @Published var currentPlayer: PieceColor = .white
    
    @Published var gameMode: GameMode = .menu
    @Published var winner: PieceColor? {
        didSet {
            if let w = winner, oldValue == nil, gameMode == .pve {
                let isHumanWinner = (w == .white)
                switch aiDifficulty {
                case .easy:
                    if isHumanWinner { winsEasy += 1 } else { lossesEasy += 1 }
                case .medium:
                    if isHumanWinner { winsMedium += 1 } else { lossesMedium += 1 }
                case .hard:
                    if isHumanWinner { winsHard += 1 } else { lossesHard += 1 }
                }
            }
        }
    }
    @Published var aiDifficulty: AIDifficulty = .medium
    @Published var currentTheme: GameTheme = .classic
    
    //Haptik-Schalter (aus den Einstellungen)
    @Published var isHapticsEnabled: Bool = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: "isHapticsEnabled") }
    }
    
    //Leaderboard
    @Published var winsEasy: Int = UserDefaults.standard.integer(forKey: "winsEasy") {
        didSet { UserDefaults.standard.set(winsEasy, forKey: "winsEasy") }
    }
    @Published var lossesEasy: Int = UserDefaults.standard.integer(forKey: "lossesEasy") {
        didSet { UserDefaults.standard.set(lossesEasy, forKey: "lossesEasy") }
    }

    @Published var winsMedium: Int = UserDefaults.standard.integer(forKey: "winsMedium") {
        didSet { UserDefaults.standard.set(winsMedium, forKey: "winsMedium") }
    }
    @Published var lossesMedium: Int = UserDefaults.standard.integer(forKey: "lossesMedium") {
        didSet { UserDefaults.standard.set(lossesMedium, forKey: "lossesMedium") }
    }

    @Published var winsHard: Int = UserDefaults.standard.integer(forKey: "winsHard") {
        didSet { UserDefaults.standard.set(winsHard, forKey: "winsHard") }
    }
    @Published var lossesHard: Int = UserDefaults.standard.integer(forKey: "lossesHard") {
        didSet { UserDefaults.standard.set(lossesHard, forKey: "lossesHard") }
    }
    
    // Methode zum Zurücksetzen der Statistiken
    func resetStats() {
        winsEasy = 0; lossesEasy = 0
        winsMedium = 0; lossesMedium = 0
        winsHard = 0; lossesHard = 0
    }
    
    //BLITZ-MODUS TIMER
    @Published var isTimedMode: Bool = false
    @Published var whiteTime: Double = 180.0 // 3 Minuten in Sekunden
    @Published var blackTime: Double = 180.0
    private var timerCancellable: AnyCancellable?

    // Startet ein zeitbasiertes Spiel
    func startTimedGame(mode: GameMode, difficulty: AIDifficulty = .medium) {
        isTimedMode = true
        whiteTime = 180.0
        blackTime = 180.0
        startGame(mode: mode, difficulty: difficulty)
        startClock()
    }

    // Startet den Countdown-Taktgeber
    func startClock() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateClock()
            }
    }

    // Läuft im Hintergrund und zieht Zeit ab
    func updateClock() {
        guard isTimedMode, winner == nil, gameMode != .menu else { return }
        
        if currentPlayer == .white {
            whiteTime -= 0.1
            if whiteTime <= 0 {
                whiteTime = 0
                winner = .black
                triggerNotification(type: .error)
            }
        } else {
            blackTime -= 0.1
            if blackTime <= 0 {
                blackTime = 0
                winner = .white
                triggerNotification(type: .error)
            }
        }
    }

    // Inkrement-Logik (+3 Sekunden nach dem Zug, wenn unter 60 Sek)
    func applyTimeIncrement(for color: PieceColor) {
        guard isTimedMode else { return }
        if color == .white {
            if whiteTime < 60.0 {
                whiteTime += 3.0
            }
        } else {
            if blackTime < 60.0 {
                blackTime += 3.0
            }
        }
    }

    // Hilfsfunktion zur Formatierung der Zeit
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        
        if time < 20.0 {
            return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var activeJumpingPiece: (row: Int, col: Int)? = nil
    
    init() {
        createBoard()
    }
    
    func createBoard() {
        pieces = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        currentPlayer = .white
        winner = nil
        selectedRow = nil
        selectedCol = nil
        activeJumpingPiece = nil
        
        for row in 0..<8 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    if row < 3 {
                        pieces[row][col] = Piece(row: row, col: col, color: .black)
                    } else if row > 4 {
                        pieces[row][col] = Piece(row: row, col: col, color: .white)
                    }
                }
            }
        }
    }
    
    func startGame(mode: GameMode, difficulty: AIDifficulty = .medium) {
        self.gameMode = mode
        self.aiDifficulty = difficulty
        if !isTimedMode {
            self.isTimedMode = false
            timerCancellable?.cancel()
        }
        createBoard()
        triggerNotification(type: .success)
    }
    
    func getPiece(row: Int, col: Int) -> Piece? {
        return pieces[row][col]
    }
    
    func getValidMoves(forRow row: Int, col: Int) -> [(row: Int, col: Int, isJump: Bool)] {
        if let active = activeJumpingPiece, (active.row != row || active.col != col) {
            return []
        }
        
        var moves: [(Int, Int, Bool)] = []
        for tr in 0..<8 {
            for tc in 0..<8 {
                if pieces[tr][tc] == nil {
                    if isValidMove(fromRow: row, fromCol: col, toRow: tr, toCol: tc, boardState: pieces) {
                        let isJump = checkIfJump(fromRow: row, fromCol: col, toRow: tr, toCol: tc, boardState: pieces)
                        if activeJumpingPiece == nil || isJump {
                            moves.append((tr, tc, isJump))
                        }
                    }
                }
            }
        }
        return moves
    }
    
    func handleSquareTap(row: Int, col: Int) {
        guard winner == nil else { return }
        if gameMode == .pve && currentPlayer == .black { return }
        
        if let sRow = selectedRow, let sCol = selectedCol {
            if sRow == row && sCol == col {
                if activeJumpingPiece == nil {
                    selectedRow = nil
                    selectedCol = nil
                    triggerHaptic(style: .light)
                }
                return
            }
            
            if activeJumpingPiece == nil, let tappedPiece = pieces[row][col], tappedPiece.color == currentPlayer {
                selectedRow = row
                selectedCol = col
                triggerHaptic(style: .light)
                return
            }
            
            if pieces[row][col] == nil {
                if isValidMove(fromRow: sRow, fromCol: sCol, toRow: row, toCol: col, boardState: pieces) {
                    let isJump = checkIfJump(fromRow: sRow, fromCol: sCol, toRow: row, toCol: col, boardState: pieces)
                    
                    if isJump {
                        triggerHaptic(style: .heavy)
                    } else {
                        triggerHaptic(style: .medium)
                    }
                    
                    executeMove(fromRow: sRow, fromCol: sCol, toRow: row, toCol: col, boardRef: &pieces)
                    checkWinCondition()
                    
                    if winner == nil {
                        if isJump, hasAnyValidJumps(row: row, col: col, boardState: pieces) {
                            activeJumpingPiece = (row, col)
                            selectedRow = row
                            selectedCol = col
                        } else {
                            activeJumpingPiece = nil
                            selectedRow = nil
                            selectedCol = nil
                            
                            // --- ZEIT-GUTSCHRIFT & SPIELERWECHSEL ---
                            applyTimeIncrement(for: currentPlayer)
                            currentPlayer = (currentPlayer == .white) ? .black : .white
                            
                            if gameMode == .pve && currentPlayer == .black {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    self.makeAIMove()
                                }
                            }
                        }
                    } else {
                        selectedRow = nil
                        selectedCol = nil
                    }
                }
            }
        } else {
            if let piece = pieces[row][col], piece.color == currentPlayer {
                if let active = activeJumpingPiece {
                    if active.row == row && active.col == col {
                        selectedRow = row
                        selectedCol = col
                        triggerHaptic(style: .light)
                    }
                } else {
                    selectedRow = row
                    selectedCol = col
                    triggerHaptic(style: .light)
                }
            }
        }
    }
    
    private func isValidMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, boardState: [[Piece?]]) -> Bool {
        guard fromRow >= 0, fromRow < 8, fromCol >= 0, fromCol < 8,
              toRow >= 0, toRow < 8, toCol >= 0, toCol < 8 else {
            return false
        }
        
        guard let piece = boardState[fromRow][fromCol] else { return false }
        let rowDiff = toRow - fromRow
        let colDiff = toCol - fromCol
        
        guard abs(rowDiff) == abs(colDiff) else { return false }
        let distance = abs(rowDiff)
        guard distance > 0 else { return false }
        
        if let active = activeJumpingPiece, (active.row != fromRow || active.col != fromCol) {
            return false
        }
        
        let rowStep = rowDiff > 0 ? 1 : -1
        let colStep = colDiff > 0 ? 1 : -1
        
        if !piece.isKing {
            if distance == 1 {
                if activeJumpingPiece != nil { return false }
                if piece.color == .white && rowDiff != -1 { return false }
                if piece.color == .black && rowDiff != 1 { return false }
                return boardState[toRow][toCol] == nil
            } else if distance == 2 {
                let midRow = fromRow + rowStep
                let midCol = fromCol + colStep
                guard midRow >= 0, midRow < 8, midCol >= 0, midCol < 8 else { return false }
                
                if let midPiece = boardState[midRow][midCol], midPiece.color != piece.color {
                    return boardState[toRow][toCol] == nil
                }
            }
            return false
        } else {
            var enemyFound: (row: Int, col: Int)? = nil
            var currRow = fromRow + rowStep
            var currCol = fromCol + colStep
            
            while currRow != toRow {
                guard currRow >= 0, currRow < 8, currCol >= 0, currCol < 8 else { return false }
                if let p = boardState[currRow][currCol] {
                    if p.color == piece.color {
                        return false
                    } else {
                        if enemyFound != nil { return false }
                        enemyFound = (currRow, currCol)
                    }
                }
                currRow += rowStep
                currCol += colStep
            }
            
            guard boardState[toRow][toCol] == nil else { return false }
            
            if enemyFound != nil {
                return true
            } else {
                if activeJumpingPiece != nil { return false }
                return true
            }
        }
    }
    
    private func checkIfJump(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, boardState: [[Piece?]]) -> Bool {
        guard let piece = boardState[fromRow][fromCol] else { return false }
        let rowDiff = toRow - fromRow
        let colDiff = toCol - fromCol
        guard abs(rowDiff) == abs(colDiff) else { return false }
        let rowStep = rowDiff > 0 ? 1 : -1
        let colStep = colDiff > 0 ? 1 : -1
        
        var currRow = fromRow + rowStep
        var currCol = fromCol + colStep
        while currRow != toRow {
            if let p = boardState[currRow][currCol], p.color != piece.color {
                return true
            }
            currRow += rowStep
            currCol += colStep
        }
        return false
    }
    
    private func hasAnyValidJumps(row: Int, col: Int, boardState: [[Piece?]]) -> Bool {
        for tr in 0..<8 {
            for tc in 0..<8 {
                if boardState[tr][tc] == nil {
                    if isValidMove(fromRow: row, fromCol: col, toRow: tr, toCol: tc, boardState: boardState) &&
                       checkIfJump(fromRow: row, fromCol: col, toRow: tr, toCol: tc, boardState: boardState) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func executeMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, boardRef: inout [[Piece?]]) {
        var piece = boardRef[fromRow][fromCol]!
        piece.row = toRow
        piece.col = toCol
        
        boardRef[toRow][toCol] = piece
        boardRef[fromRow][fromCol] = nil
        
        let rowDiff = toRow - fromRow
        let colDiff = toCol - fromCol
        let rowStep = rowDiff > 0 ? 1 : -1
        let colStep = colDiff > 0 ? 1 : -1
        
        var currRow = fromRow + rowStep
        var currCol = fromCol + colStep
        while currRow != toRow {
            if let p = boardRef[currRow][currCol], p.color != piece.color {
                boardRef[currRow][currCol] = nil
                break
            }
            currRow += rowStep
            currCol += colStep
        }
        
        if piece.color == .white && toRow == 0 {
            boardRef[toRow][toCol]?.makeKing()
        } else if piece.color == .black && toRow == 7 {
            boardRef[toRow][toCol]?.makeKing()
        }
    }
    
    private func checkWinCondition() {
        var whiteCount = 0
        var blackCount = 0
        
        for r in 0..<8 {
            for c in 0..<8 {
                if let p = pieces[r][c] {
                    if p.color == .white { whiteCount += 1 }
                    else { blackCount += 1 }
                }
            }
        }
        
        if whiteCount == 0 {
            winner = .black
            triggerNotification(type: .error)
        } else if blackCount == 0 {
            winner = .white
            triggerNotification(type: .success)
        }
    }
    
    // --- SICHHERE HAPTIK (prüft den Schalter in den Einstellungen) ---
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // KI & Minimax
    struct MoveInfo {
        let fromRow: Int
        let fromCol: Int
        let toRow: Int
        let toCol: Int
        let isJump: Bool
    }
    
    private func makeAIMove() {
        let moves: [MoveInfo]
        
        if let active = activeJumpingPiece {
            let rawMoves = getValidMovesForPiece(row: active.row, col: active.col, boardState: pieces)
            moves = rawMoves.filter { $0.isJump }
        } else {
            let allMoves = getAllPossibleMoves(for: .black, boardState: pieces)
            let jumps = allMoves.filter { $0.isJump }
            moves = jumps.isEmpty ? allMoves : jumps
        }
        
        let bestMove = findBestMoveForMoves(moves, boardState: pieces, depth: aiDifficulty.depth)
        
        if let move = bestMove {
            let isJump = checkIfJump(fromRow: move.fromRow, fromCol: move.fromCol, toRow: move.toRow, toCol: move.toCol, boardState: pieces)
            
            if isJump {
                triggerHaptic(style: .heavy)
            } else {
                triggerHaptic(style: .medium)
            }
            
            executeMove(fromRow: move.fromRow, fromCol: move.fromCol, toRow: move.toRow, toCol: move.toRow, boardRef: &pieces)
            checkWinCondition()
            
            if winner == nil {
                if isJump, hasAnyValidJumps(row: move.toRow, col: move.toCol, boardState: pieces) {
                    activeJumpingPiece = (move.toRow, move.toCol)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        self.makeAIMove()
                    }
                } else {
                    activeJumpingPiece = nil
                    
                    // --- ZEIT-GUTSCHRIFT FÜR KI ---
                    applyTimeIncrement(for: currentPlayer)
                    currentPlayer = .white
                }
            }
        } else {
            activeJumpingPiece = nil
            winner = .white
            triggerNotification(type: .success)
        }
    }
    
    private func getValidMovesForPiece(row: Int, col: Int, boardState: [[Piece?]]) -> [MoveInfo] {
        var moves: [MoveInfo] = []
        for tr in 0..<8 {
            for tc in 0..<8 {
                if boardState[tr][tc] == nil {
                    if isValidMove(fromRow: row, fromCol: col, toRow: tr, toCol: tc, boardState: boardState) {
                        let isJump = checkIfJump(fromRow: row, fromCol: col, toRow: tr, toCol: tc, boardState: boardState)
                        moves.append(MoveInfo(fromRow: row, fromCol: col, toRow: tr, toCol: tc, isJump: isJump))
                    }
                }
            }
        }
        return moves
    }
    
    private func findBestMoveForMoves(_ moves: [MoveInfo], boardState: [[Piece?]], depth: Int) -> MoveInfo? {
        if moves.isEmpty { return nil }
        var bestScore = -999999
        var bestMove: MoveInfo? = nil
        
        for move in moves {
            var tempBoard = boardState
            executeMove(fromRow: move.fromRow, fromCol: move.fromCol, toRow: move.toRow, toCol: move.toCol, boardRef: &tempBoard)
            let score = minimax(boardState: tempBoard, depth: depth - 1, alpha: -999999, beta: 999999, maximizingPlayer: false)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove ?? moves.randomElement()
    }
    
    private func minimax(boardState: [[Piece?]], depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool) -> Int {
        if depth == 0 {
            return evaluateBoard(boardState)
        }
        
        let color: PieceColor = maximizingPlayer ? .black : .white
        let allMoves = getAllPossibleMoves(for: color, boardState: boardState)
        
        if allMoves.isEmpty {
            return maximizingPlayer ? -10000 : 10000
        }
        
        var currentAlpha = alpha
        var currentBeta = beta
        
        if maximizingPlayer {
            var maxEval = -999999
            for move in allMoves {
                var tempBoard = boardState
                executeMove(fromRow: move.fromRow, fromCol: move.fromCol, toRow: move.toRow, toCol: move.toCol, boardRef: &tempBoard)
                let eval = minimax(boardState: tempBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, maximizingPlayer: false)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                if currentBeta <= currentAlpha { break }
            }
            return maxEval
        } else {
            var minEval = 999999
            for move in allMoves {
                var tempBoard = boardState
                executeMove(fromRow: move.fromRow, fromCol: move.fromCol, toRow: move.toRow, toCol: move.toRow, boardRef: &tempBoard)
                let eval = minimax(boardState: tempBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, maximizingPlayer: true)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                if currentBeta <= currentAlpha { break }
            }
            return minEval
        }
    }
    
    private func getAllPossibleMoves(for color: PieceColor, boardState: [[Piece?]]) -> [MoveInfo] {
        var moves: [MoveInfo] = []
        for r in 0..<8 {
            for c in 0..<8 {
                if let piece = boardState[r][c], piece.color == color {
                    let pieceMoves = getValidMovesForPiece(row: r, col: c, boardState: boardState)
                    moves.append(contentsOf: pieceMoves)
                }
            }
        }
        return moves
    }
    
    private func evaluateBoard(_ boardState: [[Piece?]]) -> Int {
        var score = 0
        for r in 0..<8 {
            for c in 0..<8 {
                if let piece = boardState[r][c] {
                    if piece.color == .black {
                        let value = piece.isKing ? 15 : 1
                        score += value + (r * 2)
                    } else {
                        let value = piece.isKing ? 15 : 1
                        score -= value + ((7 - r) * 2)
                    }
                }
            }
        }
        return score
    }
    
    func getEvaluationProgress() -> Double {
        let score = Double(evaluateBoard(pieces))
        let clamped = max(-40.0, min(40.0, score))
        let ratio = 0.5 - (clamped / 80.0)
        return max(0.05, min(0.95, ratio))
    }
}
