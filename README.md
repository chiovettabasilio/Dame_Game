#  # 👑 Tactical Checkers (iOS App)

Eine moderne, native iOS-Dame-App (Checkers) entwickelt in **Swift & SwiftUI**. Das Projekt verbindet klassische internationale Dame-Regeln mit einem futuristischen **Glassmorphic UI**, einer **Minimax-KI**, einem **Blitz-Modus** und anpassbaren Design-Themes.

---

## ✨ Features

* **Erweiterte Spielregeln:** Internationale Regeln mit langreichweitigen "fliegenden" Königen (*Flying Kings*) und automatischer Erfassung von Pflicht-Kettensprüngen (*Multi-Jumps*).
* **Intelligente KI (Minimax):** 
  * **Leicht** (Tiefe 2)
  * **Mittel** (Tiefe 4)
  * **Schwer** (Tiefe 5/6 mit Alpha-Beta-Pruning)
* **Blitz-Modus:** 3 Minuten Startzeit pro Spieler; ab unter 60 Sekunden greift ein automatisches +3-Sekunden-Inkrement nach jedem Zug. Inklusive Panik-Anzeige mit Zehntelsekunden unter 20 Sekunden!
* **Chess.com-Vorteilsleiste:** Dynamischer, farblich angepasster Live-Balken, der die aktuelle Brett-Evaluation in Echtzeit anzeigt.
* **Glassmorphic UI & Theme-Switcher:** Modernes Design im Glas-Look mit drei auswählbaren Themes:
  * 🤍 *Classic White*
  * 💙 *Cyberpunk Blue*
  * 💚 *Matrix Green*
* **Lokales Leaderboard & Stats:** Speichert Siege und Niederlagen gegen alle drei KI-Schwierigkeitsgrade permanent via `UserDefaults`.
* **Haptisches Feedback:** Feinfühliges, über die Einstellungen umschaltbares haptisches Feedback für Züge, Sprünge und Königskrönungen.

---

## 🛠️ Tech Stack

* **Language:** Swift
* **UI Framework:** SwiftUI
* **Architecture:** ObservableObject / MVVM-Pattern
* **Reactive & System APIs:** Combine, UIKit (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`)
* **Persistence:** `UserDefaults`

---

## 🚀 Installation & Start

1. Klone das Repository oder lade das Projekt herunter:
   ```bash
   git clone [https://github.com/chiovettabasilio/Dame-Game.git](https://github.com/chiovettabasilio/Dame-Game.git)

