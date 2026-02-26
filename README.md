# Semicolon-Vortrag 2026-04 – PowerShell & KI

## Überblick

Repository für den GFU-Semicolon-Vortrag **"PowerShell & KI – Assistenz und Agenten im Admin-Alltag"** am 21. April 2026 (online, 60 Minuten).

Der Vortrag zeigt live, wie ein PowerShell-Duplikat-Finder mit drei verschiedenen KI-Werkzeugen entsteht – VSCode + Copilot, OpenCode (Terminal-Agent) und OpenAI Codex (Cloud-Agent). Dabei werden Ergebnis, Aufwand, Kosten und Datenschutz direkt verglichen.

Das Repo enthält die Demo-Ordnerstruktur, das Init-Skript zum Aufbau des Testszenarios und die vorbereiteten Prompts.

## Voraussetzungen

- PowerShell 7.x (Core)
- Git
- VSCode mit GitHub Copilot Extension
- OpenCode CLI ([opencode.ai](https://opencode.ai))
- OpenAI-Konto mit Codex-Zugang

## Repo-Struktur

```text
├── Demo/
│   ├── Archiv/          # wird durch Init-Demo.ps1 erzeugt/resettet
│   ├── Originale/       # wird vom generierten Skript erstellt
│   └── Test-Daten/      # Quelldateien für das Testszenario
│   └── Init-Demo.ps1    # Setzt die Demo-Ordnerstruktur auf/zurück
├── AGENTS.md            # Projektbeschreibung für KI-Agenten
├── Vortrag.md           # Inhaltliche Ausarbeitung des Vortrags
└── README.md            # Diese Datei
```

## Demo starten

```powershell
# Testszenario aufbauen / zurücksetzen
.\Demo\Init-Demo.ps1
```

Anschließend den gewünschten KI-Agenten auf den Ordner `Demo\Archiv` loslassen – die Prompts stehen in `Vortrag.md` (Abschnitt "Prompts (Copy & Paste je Tool)").

