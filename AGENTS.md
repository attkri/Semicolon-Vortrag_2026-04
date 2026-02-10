# Leitplanken

## Kontext

Dieses Repository ist Teil eines Live-Vortrags. Es enthält ein Testszenario mit einer Ordnerstruktur unter `Demo\Archiv`, in der sich bewusst doppelte Dateien an verschiedenen Orten befinden.

## Arbeitsbereich

- Quellordner: `Demo\Archiv` (rekursiv, enthält Unterordner mit bewusst platzierten Duplikaten)
- Zielordner: `Demo\Originale` (wird bei Bedarf erstellt)
- Skripte ablegen im Repo-Root

## Regeln

- PowerShell Core 7.x, Windows
- Keine externen Module verwenden.
- Nur im Ordner `Demo\` arbeiten – keine Dateien außerhalb dieses Ordners verändern.
- Robuste Fehlerbehandlung und Logging.
- Idempotent: Mehrfaches Ausführen darf keinen Schaden anrichten (bestehende Symlinks erkennen und überspringen).
- Ergebnisse nicht stillschweigend überschreiben.
