# Leitplanken

## Kontext

Dieses Verzeichnis ist ein Testszenario für einen Live-Vortrag. Unter `Archiv` befinden sich mehrere Unterordner mit bewusst platzierten, identischen Dateien an verschiedenen Orten.

## Arbeitsbereich

- Quellordner: `Archiv` (rekursiv durchsuchen)
- Zielordner: `Originale` (wird bei Bedarf erstellt)
- Skripte in diesem Verzeichnis ablegen

## Regeln

- PowerShell Core 7.x, Windows.
- Keine externen Module verwenden.
- Nur innerhalb dieses Verzeichnisses arbeiten – keine Dateien außerhalb verändern.
- Robuste Fehlerbehandlung und Logging.
- Idempotent: Mehrfaches Ausführen darf keinen Schaden anrichten (bestehende Symlinks erkennen und überspringen).
- Ergebnisse nicht stillschweigend überschreiben.

## Anhang

**Dokumenten-Schema:** [OpenCode AGENTS.md](https://opencode.ai/docs/rules/#manual-instructions-in-agentsmd)
**Autor:** [Attila Krick](https://attilakrick.com/)
**Stand:** 2026-02-20
