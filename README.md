# MealBase — Smart Food & Inventory Manager

MealBase è un'applicazione mobile (Flutter, Android) per la gestione della dispensa domestica: tracciamento di prodotti, quantità e scadenze, lista della spesa integrata con carrello, scanner barcode con correzione manuale del match e notifiche di scadenza.

Progetto realizzato per il corso di **Sviluppo Applicazioni Mobile** — Università degli Studi di Udine, A.A. 2025/2026.

> La relazione completa del progetto (System Concept Statement, Competitive Assessment, Requirements Brief, Sketching, Wireframe, Evaluation) è disponibile in [`relazione/relazione.pdf`](relazione/relazione.pdf).

---

## Indice

- [Funzionalità](#funzionalità)
- [Struttura del progetto](#struttura-del-progetto)
- [Requisiti](#requisiti)
- [Come avviare l'app](#come-avviare-lapp)
- [APK pronto all'uso](#apk-pronto-alluso)
- [Generazione dell'icona](#generazione-dellicona)
- [Scraper recensioni concorrenti](#scraper-recensioni-concorrenti)
- [Roadmap / cosa manca](#roadmap--cosa-manca)

---

## Funzionalità

**Implementate:**
- Gestione multi-casa (dispense separate, es. "Casa 1", "Casa 2")
- Dispensa digitale con vista a tab (Tutto / Frigo / Dispensa / posizioni personalizzate)
- Scanner barcode (integrazione [Open Food Facts](https://world.openfoodfacts.org/)) con form di correzione manuale del prodotto riconosciuto prima del salvataggio
- Inserimento manuale/fotografico del prodotto (per articoli sfusi o senza barcode leggibile)
- Ricerca e filtro prodotti per categoria, posizione e prossimità alla scadenza
- Lista della spesa con sezioni "da acquistare" / "carrello" sulla stessa schermata, spostamento diretto degli articoli
- Notifiche push locali per i prodotti in scadenza
- Modifica manuale di categoria e posizione, sempre persistente
- Onboarding leggero (invito persistente sulla dispensa/lista vuota, tip contestuale sullo scanner e sul carrello, mostrati una sola volta)

**Non ancora implementate** (vedi [Roadmap](#roadmap--cosa-manca)): autenticazione/account, sincronizzazione multi-dispositivo, condivisione familiare, suggerimento ricette, dark mode.

---

## Struttura del progetto

```
mealbase/
├── lib/
│   ├── main.dart                 # Entry point, inizializzazione Hive/servizi
│   ├── models/                   # Modelli dati (Hive) + adapter generati (*.g.dart)
│   ├── providers/                # State management (Provider): PantryProvider,
│   │                              # ShoppingListProvider, HouseProvider, LocationProvider
│   ├── services/                 # Logica di business e accesso ai dati:
│   │                              # Hive, barcode/Open Food Facts, notifiche,
│   │                              # storage immagini, onboarding
│   ├── screens/                  # Schermate dell'app
│   ├── widgets/                  # Componenti UI riutilizzabili
│   ├── theme/                    # Palette colori, stili testo, radius condivisi
│   └── utils/                    # Helper vari (es. snackbar)
├── assets/icon/                  # Icona sorgente dell'app
├── android/                      # Progetto nativo Android (Gradle)
├── test/                         # Test Flutter
├── APK/                          # APK già compilato, pronto da installare
├── scraperApp/                   # Script Python per l'analisi dei concorrenti
├── relazione/                    # Relazione del progetto (LaTeX + PDF)
├── requirements.txt              # Dipendenze Python per lo scraper
└── pubspec.yaml                  # Dipendenze e configurazione Flutter/Dart
```

**Pattern architetturale:** Provider (state management) + Hive (persistenza locale NoSQL, nessun backend/cloud). Ogni "casa" ha i propri box Hive scoperti per nome, tramite una classe base comune (`HouseScopedHiveService`) condivisa da tutti i servizi che gestiscono dati per-casa (prodotti, articoli spesa, posizioni).

---

## Requisiti

- **Flutter SDK** — canale `stable` (progetto creato con la revision `058e0af2c2b`; consigliata una versione recente del canale stable)
- **Dart SDK** `^3.12.2` (vincolo in `pubspec.yaml`)
- Un device Android o un emulatore (il progetto è configurato solo per Android: `ios: false` nella generazione icone, nessuna cartella `ios/` mantenuta attiva)
- Per lo scanner barcode: permesso fotocamera (già dichiarato in `AndroidManifest.xml`)
- Per le notifiche: permesso `POST_NOTIFICATIONS` (Android 13+, già dichiarato)

---

## Come avviare l'app

```bash
# 1. Clona la repository
git clone https://github.com/NadalMattia/mealbase.git
cd mealbase/mealbase

# 2. Scarica le dipendenze
flutter pub get

# 3. (Se necessario) rigenera gli adapter Hive dai modelli
dart run build_runner build --delete-conflicting-outputs

# 4. Avvia l'app su un device/emulatore collegato
flutter run
```

Per generare un APK installabile:

```bash
flutter build apk --release
```

L'APK compilato sarà in `build/app/outputs/flutter-apk/app-release.apk` (cartella `build/` non versionata, si rigenera ad ogni build — vedi sotto).

> ℹ️ **Nota su `build/`, `.dart_tool/` e `venv/`**: queste cartelle contengono solo output generato automaticamente (build Flutter/Gradle, cache Dart, ambiente virtuale Python) e sono escluse da `.gitignore`. Non serve scaricarle: si rigenerano da sole con i comandi sopra (per Flutter) o con `pip install -r requirements.txt` (per lo scraper, vedi sotto).

---

## APK pronto all'uso

Se non vuoi compilare il progetto, in `APK/mealbase.apk` trovi un APK già pronto: scaricalo e installalo direttamente su un device Android (potrebbe essere necessario abilitare "Installa da fonti sconosciute" nelle impostazioni di sicurezza del device).

---

## Generazione dell'icona

L'icona dell'app viene generata a partire da `assets/icon/iconApp.jpg` tramite il pacchetto [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) (configurazione in fondo a `pubspec.yaml`). Per rigenerarla dopo aver sostituito l'immagine sorgente:

```bash
flutter pub get
dart run flutter_launcher_icons
```

---

## Scraper recensioni concorrenti

Lo script [`scraperApp/scraper.py`](scraperApp/scraper.py) è lo strumento usato per la **Competitive Assessment** della relazione: scarica da Google Play, per i tre concorrenti diretti analizzati (KitchenPal, NoWaste, BestBefore), i metadati dell'app (sviluppatore, download, rating) e fino a 1000 recensioni per lingua (italiano + inglese), salvando tutto in due CSV dentro `scraperApp/`.

### Setup ambiente virtuale

Lo script richiede un **virtual environment Python** separato dal resto del progetto (non è codice Flutter/Dart). Da terminale, nella root del progetto:

```bash
# Crea il virtual environment
python -m venv venv

# Attivalo
# Windows (PowerShell):
venv\Scripts\Activate.ps1
# macOS / Linux:
source venv/bin/activate

# Installa le dipendenze
pip install -r requirements.txt
```

### Esecuzione

```bash
python scraperApp/scraper.py
```

Al termine troverai in `scraperApp/`:
- `app_metadata.csv` — metadati delle tre app (sviluppatore, download, rating, ecc.)
- `dataset_3_apps.csv` — dataset delle recensioni raccolte (deduplicate), con colonne `App`, `Lingua`, `Valutazione`, `Utente`, `Data`, `Recensione`

Per disattivare il virtual environment al termine: `deactivate`.

> ⚠️ Lo script interroga le API pubbliche di Google Play tramite [`google-play-scraper`](https://pypi.org/project/google-play-scraper/): tempi di esecuzione e disponibilità dei dati dipendono dalla risposta di Google Play in quel momento.

---

## Roadmap / cosa manca

L'app copre i requisiti a priorità **ALTA** individuati nel Requirements Brief della relazione, ma resta un MVP volutamente estendibile. Non ancora implementati:

- **Autenticazione e account utente** — le case sono attualmente locali al device, nessun login/registrazione
- **Sincronizzazione multi-dispositivo** — nessun backend cloud, i dati restano su Hive locale
- **Condivisione familiare della dispensa/lista** — la schermata Impostazioni Casa esiste come placeholder ("in arrivo")
- **Suggerimento ricette** — voce presente in navigazione per continuità visiva, non ancora sviluppata
- **Dark mode**

Il progetto è stato strutturato fin dall'inizio per poter accogliere queste funzionalità senza stravolgimenti architetturali — vedi la sezione *Conclusione* della relazione per il dettaglio.

---

## Autore

**Mattia Nadal**
Dipartimento di Scienze Matematiche, Informatiche e Fisiche, Università degli Studi di Udine