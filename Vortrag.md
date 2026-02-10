# Semicolon-Vortrag 2026 – PowerShell & KI

## Agenda (60 Minuten)

| Anteil | Block                         | Inhalt                                                                                  |
| ------ | ----------------------------- | --------------------------------------------------------------------------------------- |
| 5 %    | **1. Begrüßung**              | Vorstellung, Erwartungen kurz abholen                                                   |
| 12 %   | **2. Einordnung**             | KI-Assistenz vs. KI-Agent – was bedeutet das für Admins?                                |
| 17 %   | **3. Tooling & Kosten**       | Überblick: VSCode+Copilot, OpenCode, Codex · Abo- vs. Token-Preise · Sicherheitsaspekte |
| 46 %   | **4. Live-Beispiel**          | Duplikat-Finder – ein Szenario, drei KI-Wege (siehe unten)                              |
| 12 %   | **5. Gefahren & Absicherung** | Datenschutz, Agent-Autonomie, Absicherungsstrategien                                    |
| 8 %    | **6. Wrap-up**                | Kernbotschaften, Fragen, Seminar-Hinweis (S2241/S2242)                                  |

## Inhaltliche Ausarbeitung

### 1. Begrüßung

**Referent:**

[Attila Krick](https://attilakrick.com/), freiberuflicher Entwickler, Berater und Trainer – seit 2023 KI-Tools im produktiven Einsatz.

**Erwartungen:**

> Wer von Ihnen hat schon mal einen KI-Assistenten zum Coden genutzt? **(Handzeichen / Zoom-Reaktion)**

**Fahrplan:**

1. Erst einordnen...
2. ... dann drei Tools live vergleichen, ...
3. ... am Ende Gefahren und Schutzmaßnahmen.

### 2. Einordnung

**Kernunterscheidung - Assistenz vs. Agent:**

- **KI-Assistenz** = Ich frage -> KI antwortet -> Ich entscheide -> ich tippe.
  - Beispiel: Copilot schlägt eine Zeile Code vor, ich drücke Tab.
- **KI-Agent** = Ich gebe ein Ziel, der Agent arbeitet eigenständig – liest Dateien, schreibt Code, führt aus, korrigiert sich.
  - Beispiel: OpenCode erhält ein Prompt, erstellt das Skript, testet es, behebt Fehler – alles ohne mein Zutun.

**Warum das für Admins relevant ist:**

Agenten versprechen „Hands-off-Automatisierung" – aber wer kontrolliert, was der Agent tut?

---

**TIPP:** KI-Agenten sind nicht auf Software-Entwicklung beschränkt. Admins können sie für Infrastruktur-Automatisierung, Log-Analyse, Konfigurationsmanagement oder das Erstellen von Dokumentation einsetzen – überall dort, wo (wiederkehrende) Aufgaben (in Skripte) gegossen werden können.

### 3. Tooling, Kosten & Sicherheit

#### Tool-Vergleich

| Eigenschaft              | VSCode + Copilot              | Codex (Cloud, Web-UI)           | OpenCode                       |
| ------------------------ | ----------------------------- | ------------------------------- | ------------------------------ |
| **Typ**                  | Editor-Assistent + Agent-Mode | Cloud-Agent (Sandbox)           | Terminal-Agent (lokal)         |
| **Bedienung**            | GUI, Inline-Vorschläge, Chat  | Web-UI, Prompt → Agent arbeitet | CLI, Prompt → Agent arbeitet   |
| **Codeausführung**       | Lokal auf deinem Rechner      | In isolierter Cloud-Sandbox     | Lokal auf deinem Rechner       |
| **Dateizugriff**         | Dein Workspace                | Nur das GitHub-Repo             | Dein Dateisystem (!)           |
| **Autonomie**            | Mittel (Agent-Mode: hoch)     | Hoch                            | Hoch                           |
| **Offline möglich**      | Nein                          | Nein                            | Nein  (Ja, z.B. Ollama)        |
| **Einarbeitungsaufwand** | Niedrig                       | Mittel                          | Mittel    bis Hoch             |
| **Kostenmodell**         | 0€ + Abo                      | Abo + Pay-as-you-go (Token)     | 0€, Abo, Pay-as-you-go (Token) |

#### Kosten-Struktur

| Anbieter / Produkt             | Modell    | Preis          | Anmerkung                                                           |
| ------------------------------ | --------- | -------------- | ------------------------------------------------------------------- |
| **GitHub Copilot Free**        | Limitiert | $0             | 2.000 Completions/Monat                                             |
| **GitHub Copilot Pro**         | Abo       | $10/Monat      | Einzelpersonen, 500 Antworten/Monat inkl.                           |
| **GitHub Copilot Pro+**        | Abo       | $39/Monat      | Einzelpersonen, 1.500 Antworten/Monat inkl.                         |
| **GitHub Copilot Business**    | Abo       | $19/Monat/User | Unternehmen, Policies, unbegrenzte Antworten                        |
| **GitHub Copilot Enterprise**  | Abo       | $39/Monat/User | Zusätzlich Knowledge Bases, Bing-Suche, unbegrenzte Antworten       |
| **OpenAI ChatGPT Plus**        | Abo       | $20/Monat      | inkl. GPT-4o, begrenzt Codex                                        |
| **OpenAI ChatGPT Pro**         | Abo       | $200/Monat     | unbegrenzt, inkl. Codex                                             |
| **OpenAI API (Pay-as-you-go)** | Token     | variabel       | z. B. GPT-4o: ~$2.50/$10 (in/out) pro 1M Token                      |
| **OpenCode Zen (API-Router)**  | Token     | variabel       | z. B. Claude Sonnet 4: $3/$15 pro 1M Token · Nano-Modelle kostenlos |

**Praxiseinordnung für Admins:** Bei intensiver KI-Nutzung (z. B. mehrstündige Agent-Sitzungen, komplexe Skript-Entwicklung) verbraucht man ca. 1 Million Token in 2–5 Tagen. Das entspricht bei API-Tarifen je nach Modell etwa $2–$15. Ein Abo lohnt sich bei täglicher Nutzung. Wer nur gelegentlich KI nutzt, fährt mit Pay-as-you-go günstiger – aber braucht ein Kostenlimit.

#### Sicherheit & Datenschutz

- **Werden meine Daten für Modell-Training genutzt?** Bei Business- und Enterprise-Tarifen grundsätzlich nein. Bei Free/Pro-Tarifen hängt es von den AGB ab – die meisten Anbieter bieten einen Opt-out-Schalter in den Einstellungen.
- **Wo laufen die Daten?** US-Cloud (Azure/OpenAI), teilweise EU-Optionen verfügbar.
- **Zero-Retention** bedeutet: Der Anbieter speichert keine Prompts und Antworten nach der Sitzung. In Enterprise-Tarifen ist das meist garantiert. OpenAI und Anthropic behalten API-Daten 30 Tage zur Missbrauchserkennung – danach Löschung. Anbieter wie Venice.ai setzen auf rein lokale Speicherung ohne Cloud-Retention.
- **Lokale Verarbeitung möglich?** Ja – z. B. mit Ollama lassen sich Open-Source-Modelle komplett lokal betreiben. Vorteil: Daten verlassen den Rechner nicht. Nachteil: Hardware-lastig, man braucht eine leistungsfähige GPU (min. 16 GB VRAM für brauchbare Modelle). Für die genannten Cloud-Tools (Copilot, Codex, OpenCode) ist eine Internet-Anbindung erforderlich. BYOK (Bring Your Own Key) ermöglicht bei API-Nutzung, den Datenfluss an einen Anbieter der Wahl zu binden.

### 4. Live-Beispiel: Duplikat-Finder

[GitHub Repository](https://github.com/attkri/Semicolon-Vortrag_2026-04)

#### Szenario

Ein Ordner `Demo\Archiv` enthält mehrere Unterordner mit Dateien – teilweise identische Dateien an verschiedenen Orten.

**Ziel:** Ein PowerShell-Skript, das:

1. Alle Dateien rekursiv scannt und per Hash (SHA256) Duplikate erkennt.
2. Einen Ordner `Demo\Originale` erstellt, wenn dieser nicht existiert.
3. Je Duplikat-Gruppe: eine Datei nach `Originale` verschiebt, an allen anderen Fundorten eine symbolische Verknüpfung zur Original-Datei anlegt.

**Ergebnis:** Jede Datei existiert nur noch einmal physisch (Keine Redundanzen + Einfach Änderungen), ist aber überall erreichbar.

#### Vorbereitung

- `Init-Demo.ps1` – baut die Testordner auf / setzt zurück (Archiv + Duplikate)
- `AGENTS.md` – Projektbeschreibung für KI-Agenten im Repo hinterlegt

Fünf Prompts vorbereiten (Copy & Paste): ChatGPT-Prompt, VSCode-Assistent, VSCode-Agent, Codex Online, OpenCode

#### Ablauf im Vortrag

| Schritt | Tool                   | Was passiert                                                    |
| :-----: | ---------------------- | --------------------------------------------------------------- |
|    0    | –                      | Szenario zeigen: Ordnerstruktur, Problem erklären               |
|    1    | ChatGPT                | Prompt einfügen → Ergebnis zeigen                               |
|    2    | VSCode + Copilot Chat  | Prompt einfügen → Copilot generiert Skript → Ergebnis zeigen    |
|    3    | VSCode + Copilot Agent | Prompt einfügen → Copilot generiert Skript → Ergebnis zeigen    |
|    4    | Codex (Web-UI)         | Prompt einfügen → Cloud-Agent arbeitet → Ergebnis zeigen        |
|    5    | OpenCode (Terminal)    | Prompt einfügen → Agent arbeitet autonom → Ergebnis zeigen      |
|    6    | –                      | Vergleich: Qualität, Autonomie, Kosten, was hat Zugriff worauf? |

**Gemessene Laufzeiten der Agenten:**

| Prompt | Tool             | Laufzeit | Anmerkung                                                          |
| ------ | ---------------- | -------- | ------------------------------------------------------------------ |
| P1     | ChatGPT          | ~1 min   | Sofort Code, kein Testen                                           |
| P2     | VSCode-Assistent | ~1 min   | Kürzeste – nur Code-Output, kein Testen                            |
| P3     | VSCode-Agent     | ~2 min   | Skript + Testversuch, Abbruch wegen pty.node-Fehler                |
| P4     | Codex            | ~3 min   | Cloud-Sandbox, PR erstellt, kein PowerShell zum Testen             |
| P5     | OpenCode         | ~9 min   | Längste – schreibt, testet, erkennt Bug, korrigiert, testet erneut |

**Erkenntnis:**

> Der schnellste Agent liefert in einer Minute – aber ungetesteten Code.
> Der gründlichste braucht neun Minuten – und liefert ein geprüftes Ergebnis.
>
> **Das ist kein Bug, das ist ein Trade-off: Geschwindigkeit vs. Gründlichkeit.**

#### Prompts

Copy & Paste je Tool

##### Prompt 1 – ChatGPT (kein Dateizugriff)

ChatGPT sieht weder Dateisystem noch Repo. Der Prompt muss deshalb die Ordnerstruktur und die Aufgabe vollständig beschreiben. Das Ergebnis ist reiner Code-Output, den man manuell als `.ps1` speichert und startet.

```text
Ich habe folgende Ordnerstruktur auf meinem Windows-Rechner:

Demo\Archiv\
├── Projekte\
│   ├── Projekt-Alpha\    ← enthält die Originaldateien
│   └── Projekt-Beta\     ← leer
├── Backup\
│   ├── 2025-Q4\          ← enthält Duplikate (identischer Inhalt, gleicher Dateiname)
│   └── 2026-Q1\          ← leer
└── Austausch\            ← enthält Duplikate (identischer Inhalt, anderer Dateiname mit Suffix "_Kopie")

In mehreren dieser Unterordner liegen identische Dateien (gleicher Inhalt, teilweise unterschiedliche Namen). Ich möchte die Redundanz auflösen.

Erstelle ein PowerShell-Skript (Core 7.x), das:

1. Den Ordner "Demo\Archiv" rekursiv nach Dateien durchsucht.
2. Per SHA256-Hash Duplikate identifiziert.
3. Einen Ordner "Demo\Originale" erstellt (falls nicht vorhanden).
4. Pro Duplikat-Gruppe: EINE Datei nach "Demo\Originale" verschiebt und an ALLEN bisherigen Fundorten symbolische Verknüpfungen (Symlinks) zur verschobenen Datei anlegt.
5. Eine Zusammenfassung ausgibt: Anzahl gescannter Dateien, gefundene Duplikat-Gruppen, erstellte Symlinks.

Anforderungen:

- Keine externen Module – nur Bordmittel von PowerShell 7.x.
- Robuste Fehlerbehandlung (try/catch) und aussagekräftiges Logging.
- Das Skript soll idempotent sein: mehrfaches Ausführen darf keinen Schaden anrichten.
- Symlinks erfordern erhöhte Rechte unter Windows – das Skript soll das prüfen
  und bei fehlenden Rechten mit einer klaren Meldung abbrechen.
```

##### Prompt 2 – VSCode-Assistent (Copilot Chat, kein Agent-Mode)

VSCode ist direkt im `Demo`-Ordner geöffnet. `@workspace` liefert die Ordnerstruktur, deshalb entfällt die manuelle Beschreibung. Ergebnis: Code im Chat – manuell speichern und testen wie bei ChatGPT.

```text
@workspace

Erstelle ein PowerShell-Skript (Core 7.x) für Windows, das:

1. Den Ordner Archiv rekursiv nach Dateien durchsucht.
2. Per SHA256-Hash Duplikate identifiziert.
3. Einen Ordner Originale erstellt (falls nicht vorhanden).
4. Pro Duplikat-Gruppe: die erste Datei nach Originale verschiebt und an den bisherigen Fundorten symbolische Verknüpfungen (Symlinks) zur verschobenen Datei anlegt.
5. Eine Zusammenfassung ausgibt: gescannte Dateien, Duplikat-Gruppen, erstellte Symlinks.

Anforderungen:

- Idempotent: bestehende Symlinks erkennen und überspringen.
- Keine externen Module.
- Fehlerbehandlung und Logging.
```

##### Prompt 3 – VSCode-Agent (Copilot Agent-Mode)

Der entscheidende Sprung: Agent-Mode schreibt Dateien, führt Terminal-Befehle aus, sieht Fehler und korrigiert sich selbst. Kein `@workspace` nötig – Agent-Mode hat automatisch Workspace-Zugriff. Wichtig: Alles läuft lokal mit deinen Rechten.

**Hinweis:** Copilot erkennt keine `AGENTS.md` – wer projektweite Regeln hinterlegen will, bräuchte eine `.github/copilot-instructions.md`. Jedes Tool hat seine eigene Konvention.

```text
Schau dir die Ordnerstruktur unter Archiv an. Dort liegen in mehreren Unterordnern teilweise identische Dateien.

Erstelle ein PowerShell-Skript (Core 7.x), das:

1. Archiv rekursiv nach Dateien durchsucht.
2. Per SHA256-Hash Duplikate identifiziert.
3. Einen Ordner Originale erstellt (falls nicht vorhanden).
4. Pro Duplikat-Gruppe: die erste Datei nach Originale verschiebt und an den bisherigen Fundorten Symlinks zur verschobenen Datei anlegt.
5. Eine Zusammenfassung ausgibt.

Anforderungen: Idempotent, keine externen Module, Fehlerbehandlung.

Speichere das Skript und führe es aus. Prüfe das Ergebnis.
```

**Ergebnis im Test:**

1. Der Agent hat das Skript erstellt und gespeichert, **scheiterte** aber beim Ausführen an einem Laufzeitfehler der Umgebung.
2. Das Skript selbst war **vielleicht** funktionsfähig – der Agent konnte es nur nicht selbst testen.
3. Agenten sind nicht **unfehlbar**. Umgebungsprobleme, fehlende Rechte oder Abhängigkeiten stoppen sie genauso wie einen Menschen.
4. Der Unterschied: Der Agent erkennt den Fehler, kann ihn aber nicht immer lösen.

> Der Agent wollte testen – und scheitert. Nicht am Skript, sondern an seiner eigenen Umgebung. Das passiert in der Praxis ständig. Ein Agent ist nur so gut wie die Umgebung, in der er läuft.

##### Prompt 4 – Codex (Cloud-Agent, nur Repo-Zugriff)

1. OpenAI Codex klont das GitHub-Repo in eine isolierte Cloud-Sandbox.
2. Er liest die `AGENTS.md` automatisch und kennt dadurch Leitplanken, Pfade und Regeln. Der Prompt beschreibt nur die reine Aufgabe.
3. Ergebnis: Pull-Request im Repo – Code muss gemerged werden, läuft nicht direkt auf deinem System.

```text
Erstelle ein PowerShell-Skript das den Quellordner rekursiv nach Dateien durchsucht und per SHA256-Hash Duplikate identifiziert.
Pro Duplikat-Gruppe: verschiebe die erste Datei in den Zielordner und ersetze alle weiteren Fundorte durch Symlinks.
Gib eine Zusammenfassung aus: gescannte Dateien, Duplikat-Gruppen, erstellte Symlinks.

Teste das Skript.
```

**Reales Ergebnis:**

1. Codex hat das Skript korrekt erstellt und als Pull-Request bereitgestellt. Beim Testen scheiterte er: Die Linux-Sandbox enthält kein PowerShell (`pwsh` und `powershell` beide `command not found`). Das Skript wurde geschrieben, aber nicht verifiziert.
2. **Workaround:** Codex unterstützt ein `setup.sh` im Repo-Root, das beim Sandbox-Start läuft und z. B. `pwsh` installieren könnte. Für den Vortrag bewusst weggelassen, um die Limitierung zu zeigen.

> Codex läuft in einer sicheren Cloud-Sandbox – super für den Datenschutz. Aber die Sandbox kennt kein PowerShell. Der Agent schreibt das Skript, kann es aber nicht testen. Sicherheit und Komfort stehen hier im Konflikt.

##### Prompt 5 – OpenCode (Terminal-Agent, volles Dateisystem)

1. OpenCode liest die `AGENTS.md` automatisch.
2. Der entscheidende Unterschied: OpenCode läuft lokal, hat PowerShell, hat das Dateisystem. Deshalb funktioniert "Teste das Skript" hier tatsächlich.

Der Prompt ist **identisch mit Codex** – gleiche Aufgabe, anderes Ergebnis:

```text
Erstelle ein PowerShell-Skript das den Quellordner rekursiv nach Dateien durchsucht und per SHA256-Hash Duplikate identifiziert.
Pro Duplikat-Gruppe: verschiebe die erste Datei in den Zielordner und ersetze alle weiteren Fundorte durch Symlinks.
Gib eine Zusammenfassung aus: gescannte Dateien, Duplikat-Gruppen, erstellte Symlinks.

Teste das Skript.
```

**Reales Ergebnis:**

1. Der Agent erstellte das Skript, führte es aus, erkannte dabei selbstständig einen Fehler (Einzeldateien wurden fälschlich verschoben), korrigierte den Code und lief beim zweiten Durchlauf sauber durch.
2. Das ist echtes Agent-Verhalten: iterieren, testen, korrigieren – ohne manuellen Eingriff.

> Exakt der gleiche Prompt wie bei Codex. Aber OpenCode läuft auf meinem Rechner – mit meinem PowerShell, meinem Dateisystem, meinen Rechten. Das Skript wird erstellt, ausgeführt und das Ergebnis geprüft. Vollautomatisch.
>
> Aber genau das ist auch das Risiko: **Dieser Agent hat Zugriff auf alles, was ich habe.**

#### Erkenntnis: „Teste das Skript" reicht nicht

1. Ein Agent braucht klare Testkriterien, sonst testet er irgendwas – oder gar nichts.
2. Codex konnte mangels PowerShell gar nicht testen, VSCode-Agent scheiterte an der Umgebung, und selbst OpenCode testete nur „läuft es durch?" statt „stimmt das Ergebnis?".

**Bessere Formulierung im Prompt:**

```text
Führe das Skript aus. Prüfe danach:

1. Existiert der Ordner Originale und enthält er Dateien?
2. Sind an den bisherigen Fundorten Symlinks statt Dateien?
3. Zeigen die Symlinks auf die korrekten Dateien in Originale?
4. Stimmt die Zusammenfassung mit der tatsächlichen Anzahl überein?
5. Läuft das Skript bei erneutem Ausführen ohne Änderungen durch (Idempotenz)?
```

> Genauso wie in der echten Arbeit:  
> Wenn ich einem Kollegen sage "teste das mal", bekomme ich "läuft".  
> Wenn ich sage "prüfe diese vier Punkte", bekomme ich ein Ergebnis, mit dem ich arbeiten kann.  
> Bei KI-Agenten ist das identisch – Leitplanken und Testkriterien sind der Unterschied zwischen brauchbar und gefährlich.

#### Vergleichspunkte nach der Demo

| Kriterium                           | VSCode + Copilot                      | Codex                            | OpenCode                         |
| ----------------------------------- | ------------------------------------- | -------------------------------- | -------------------------------- |
| **Interaktion nötig?**              | Mittel – Chat, Accept, manuell testen | Minimal – Prompt, Agent arbeitet | Minimal – Prompt, Agent arbeitet |
| **Hat mein Dateisystem gesehen?**   | Ja (Workspace)                        | Nein (Sandbox, nur Repo)         | Ja (volles Dateisystem!)         |
| **Hat das Skript selbst getestet?** | Nein (außer Agent-Mode)               | Nein (kein pwsh in Sandbox)      | Ja                               |
| **Laufzeit**                        | ~1 min (Assistent) / ~2 min (Agent)   | ~3 min (ohne Testlauf)           | ~9 min (inkl. Selbstkorrektur)   |
| **Kosten dieses Durchlaufs**        | Im Abo enthalten                      | Im ChatGPT-Abo enthalten         | Abp oder ~$0,05–0,30 (Token)     |
| **Datenschutz-Risiko**              | Mittel                                | Niedrig (isoliert)               | Hoch (lokaler Zugriff!)          |

#### Essenzen aus dem Skript-Vergleich (alle 5 Varianten)

| Merkmal                     | P1 ChatGPT      | P2 Assistent     | P3 VSCode-Agent | P4 Codex     | P5 OpenCode          |
| --------------------------- | --------------- | ---------------- | --------------- | ------------ | -------------------- |
| **Zeilen**                  | 218             | 134              | 68              | 92           | 245                  |
| **Sprache**                 | Englisch        | Deutsch          | Englisch        | Deutsch      | Deutsch              |
| **Ergebnis reproduzierbar** | ja              | ja               | Teilweise       | NEIN         | ja (Tracking-Datei)  |
| **Symlink-Rechte geprüft**  | nein            | nein             | nein            | nein         | JA (Test + Fallback) |
| **Logging**                 | Datei + Console | Farbig, Console  | Write-Output    | Write-Host   | Timestamp + Console  |
| **Namenskollision**         | Hash-Prefix     | ! Überschreibt ! | Counter-Suffix  | Hash+Counter | Counter-Suffix       |

**Fünf Essenzen für den Vortrag:**

1. **Umfang ≠ Qualität:** Das kürzeste Skript (P3, 68 Zeilen) nutzt eine manuelle SHA256-Implementierung statt `Get-FileHash`. Weniger Code heißt nicht weniger clever – aber auch nicht robuster.

2. **Nur OpenCode denkt an Rechte:** P5 prüft vor dem Start, ob Symlinks überhaupt möglich sind (Testlink in `$env:TEMP`) und bietet einen Hardlink-Fallback. Alle anderen laufen los und scheitern erst mittendrin.

3. **Idempotenz – drei Strategien:** ChatGPT prüft bestehende Symlink-Ziele, OpenCode legt eine Tracking-Datei (`.dedup_tracking.json`) an, Codex ignoriert das Thema komplett.

4. **Sprache verrät den Kontext:** Tools ohne deutschen Kontext (ChatGPT, VSCode-Agent) schreiben englischen Code. Tools mit AGENTS.md oder deutschem Workspace schreiben deutsch. Kleine Sache – aber zeigt, wie Kontext die Ausgabe beeinflusst.

5. **Geschwindigkeit vs. Gründlichkeit:** P2 liefert in ~1 min ungetesteten Code. P5 braucht ~9 min – schreibt, testet, erkennt einen Bug, korrigiert, testet erneut. Trade-off statt Fehler.

### 5. Gefahren & Absicherung

**Drei Gefahren, die Admins kennen müssen:**

1. **Datenabfluss:** Agent liest lokale Dateien → Inhalte gehen an die Cloud-API.
   - Gegenmaßnahme: Workspace einschränken, sensible Ordner ausschließen, Business-Tarife mit Zero-Retention nutzen.

2. **Unkontrollierte Ausführung:** Agent führt Befehle aus, die nicht gewollt waren (z. B. `Remove-Item -Recurse`).
   - Gegenmaßnahme: Sandbox/Container verwenden, Agent-Berechtigungen einschränken, Review vor Ausführung erzwingen.

3. **Halluzination mit Konsequenz:** Agent installiert ein nicht existierendes Modul oder nutzt eine erfundene API.
   - Gegenmaßnahme: Ergebnisse immer testen, keine blinde Übernahme, Versionspinning.

**Faustregel für den Admin-Alltag:**

> Je mehr Autonomie der Agent hat, desto enger muss der Käfig sein.

**Wie schütze ich mich konkret?**

- Ergebnisse nie blind übernehmen – jedes generierte Skript in einer Testumgebung ausführen.
- Agenten in Sandboxen oder Containern laufen lassen, nie direkt auf Produktivsystemen.
- Sensible Pfade (z. B. `C:\Users`, Netzlaufwerke) explizit aus dem Agent-Workspace ausschließen.
- Bei API-Nutzung: Kostenlimits setzen und Verbrauch überwachen.
- Prompts mit korrekten Leitplanken formulieren: klare Grenzen setzen, was der Agent darf und was nicht (z. B. „keine Dateien löschen", „nur lesender Zugriff", „nur im Ordner X arbeiten").

### 6. Wrap-up

**Drei Kernbotschaften:**

1. KI-Assistenz ist heute nutzbar und senkt die **Einstiegshürde** bei PowerShell deutlich.
2. KI-Agenten sind **mächtig** – aber Kontrolle und Datenschutz sind Chefsache.
3. Die Tools sind **unterschiedlich** gut für unterschiedliche Szenarien – es gibt nicht das eine perfekte Werkzeug.

**Überleitung zu den Seminaren:**

> Was ich heute in 60 Minuten zeigen konnte, ist natürlich nur ein Ausschnitt. In meinen PowerShell-Workshops bei der GFU gehen wir tiefer – vom ersten Skript bis zur Automatisierung mit KI-Unterstützung. Die Links zu den Seminaren finden Sie in den Veranstaltungsinfos.

**Passende GFU-Seminare:**

- S2241 – PowerShell Praxis-Workshop für Einsteiger
- S2242 – PowerShell Praxis-Workshop für Fortgeschrittene
