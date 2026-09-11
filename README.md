# MealBase — Smart Food & Inventory Manager

Applicazione mobile Flutter (Android) per la gestione della dispensa domestica: tracciamento di prodotti, quantità e scadenze, lista della spesa con carrello integrato, scanner barcode con correzione manuale e notifiche di scadenza.

Progetto realizzato per il corso di **Sviluppo Applicazioni Mobile** — Università degli Studi di Udine, A.A. 2025/2026.

> La relazione completa (System Concept Statement, Competitive Assessment, Requirements Brief, Sketching, Wireframe, Evaluation) è in [`relazione/relazione.pdf`](relazione/relazione.pdf).

---

## Indice

- [Funzionalità](#funzionalità)
- [Architettura](#architettura)
- [Struttura del progetto](#struttura-del-progetto)
- [Persistenza dei dati](#persistenza-dei-dati)
- [Notifiche di scadenza](#notifiche-di-scadenza)
- [Requisiti](#requisiti)
- [Avviare l'app](#avviare-lapp)
- [APK pronto all'uso](#apk-pronto-alluso)
- [Icona dell'app](#icona-dellapp)
- [Scraper recensioni concorrenti](#scraper-recensioni-concorrenti)
- [Qualità del codice](#qualità-del-codice)
- [Limiti noti e roadmap](#limiti-noti-e-roadmap)

---

## Funzionalità

- **Multi-casa** — dispense, liste e spazi separati per ogni casa (es. "Casa", "Casa al mare")
- **Dispensa a tab** — Tutto / Frigo / Dispensa / Freezer, più spazi personalizzati riordinabili
- **Scanner barcode** — integrazione [Open Food Facts](https://world.openfoodfacts.org/), con form di correzione manuale prima del salvataggio
- **Inserimento manuale o fotografico** — per prodotti sfusi o con barcode illeggibile
- **Ricerca e filtri** — per nome, categoria, posizione e prossimità alla scadenza
- **Lista della spesa** — sezioni "da acquistare" e "nel carrello" sulla stessa schermata, un tocco sposta l'articolo
- **Passaggio spesa → dispensa** — salvando un prodotto suggerito dal carrello, l'articolo di origine viene rimosso automaticamente
- **Notifiche locali** — promemoria il giorno prima della scadenza
- **Eliminazione con annullamento** — snackbar con "ANNULLA", niente scritture su disco finché la scelta non è definitiva
- **Onboarding leggero** — inviti sulle schermate vuote e due suggerimenti contestuali, mostrati una volta sola

---

## Architettura

**Provider** per lo stato, **Hive** per la persistenza locale. Nessun backend: tutti i dati restano sul device.

La separazione è a quattro livelli e le dipendenze scendono in una sola direzione — nessun servizio conosce un provider, nessun provider conosce una schermata.

```
   Schermate          leggono i provider, non toccano mai Hive
       │
       ▼
   Provider           ChangeNotifier: stato in memoria + notifiche alla UI
       │
       ▼
   Servizi            accesso a Hive, rete, notifiche, file
       │
       ▼
   Modelli            HiveObject: quello che finisce su disco
```

Ogni dominio ha la propria catena verticale:

| Provider | Servizio | Modello |
|---|---|---|
| `PantryProvider` | `HiveService` | `Product` |
| `ShoppingListProvider` | `ShoppingListService` | `ShoppingItem` |
| `LocationProvider` | `LocationService` | `Location` |
| `HouseProvider` | `HouseService` | `House` |

I primi tre servizi ereditano da **`HouseScopedHiveService`**, la classe base astratta che incapsula il concetto di "dato scoperto per casa": apre il box giusto, gestisce le migrazioni, espone il CRUD. Le sottoclassi aggiungono solo la logica del proprio dominio tramite l'hook `onHouseSwitched()` — `LocationService` lo usa per creare Frigo/Dispensa/Freezer in una casa nuova, `ShoppingListService` per migrare dati da schemi precedenti.

Quattro servizi sono trasversali e non hanno un provider dedicato, perché non producono stato applicativo: `NotificationService`, `ImageStorageService`, `BarcodeService`, `OnboardingService`.

### Navigazione

Entrambi i contenitori usano `IndexedStack`, che mantiene vivo lo stato delle schermate sorelle: scroll, ricerca e tab selezionata sopravvivono al cambio di scheda.

```
HomeScreen                          IndexedStack, 2 tab
├── HouseListScreen                 seleziona la casa → switchHouse sui 3 provider
│   └── MainScreen                  IndexedStack, 3 tab
│       ├── ShoppingListScreen
│       │   ├── ShoppingItemEditScreen
│       │   └── ShoppingScannerScreen
│       ├── PantryScreen            tab iniziale
│       │   ├── ProductFormScreen
│       │   ├── ScannerScreen → ProductFormScreen
│       │   ├── ManageLocationsScreen
│       │   └── HouseSettingsScreen        segnaposto
│       └── RecipesScreen                  segnaposto
└── ProfileScreen                          in gran parte segnaposto
```

---

## Struttura del progetto

```
mealbase/
├── lib/
│   ├── main.dart               Entry point: adapter Hive, apertura box, MultiProvider
│   ├── models/                 6 modelli + 4 adapter generati (*.g.dart)
│   ├── providers/              4 ChangeNotifier
│   ├── services/               9 servizi (dati, barcode, notifiche, immagini, onboarding)
│   ├── screens/                13 schermate
│   ├── widgets/                14 componenti riusabili
│   ├── theme/                  Design system: palette, stili testo, radius, spacing
│   └── utils/                  Helper senza stato (snackbar centralizzate)
├── android/                    Progetto nativo Android (Gradle)
├── assets/icon/                Icona sorgente
├── APK/                        APK già compilato
├── scraperApp/                 Script Python per la Competitive Assessment
├── relazione/                  Relazione del progetto (LaTeX + PDF)
├── test/                       Test unitari (3 file)
├── analysis_options.yaml       Regole dell'analyzer Dart
├── requirements.txt            Dipendenze Python dello scraper
└── pubspec.yaml                Dipendenze e configurazione Flutter
```

I widget seguono una regola precisa: **dodici su quattordici importano soltanto il tema**. Ricevono dati e callback dal chiamante, quindi funzionerebbero identici in un altro progetto. Fanno eccezione `pantry_product_list` (usa `PantryProvider` e naviga; è di fatto una porzione di `PantryScreen` estratta per accorciarla) e `product_image_picker` (chiama `ImageStorageService` direttamente, perché copiare un file non genera stato che un provider debba notificare).

---

## Persistenza dei dati

Un box Hive globale per le case, più tre box **per ogni casa**, identificati dall'UUID della casa:

```
houses                       elenco delle case
onboarding_flags             suggerimenti già visti
products_<houseId>           dispensa
locations_<houseId>          spazi
shopping_items_<houseId>     lista della spesa
```

La chiave è `House.id` e non il nome: il nome è testo libero che l'utente può cambiare o duplicare, quindi usarlo come nome del box significherebbe rendere i dati irraggiungibili a ogni rinomina e far condividere la stessa dispensa a due case omonime. `HouseScopedHiveService` migra automaticamente, alla prima apertura, i box creati dagli schemi di naming precedenti e poi li cancella dal disco.

Nota per chi legge il codice: un `HiveObject` è legato al box in cui si trova, quindi la migrazione **non può** riusare la stessa istanza in un box diverso. Da qui il parametro `cloneForMigration` che ogni servizio passa alla classe base.

---

## Notifiche di scadenza

Il promemoria è programmato per il giorno prima della scadenza alle 9:00. Se quel momento è già passato ma il prodotto non è ancora scaduto, la notifica viene comunque programmata a breve, invece di essere scartata.

Viene usata la modalità **inesatta** (`inexactAllowWhileIdle`): la modalità esatta richiede `SCHEDULE_EXACT_ALARM`, che Google concede solo a sveglie, timer e calendari. Il prezzo è che in Doze la consegna può ritardare.

⚠️ **Le notifiche pianificate richiedono configurazione nativa.** Dalla versione 16, `flutter_local_notifications` dichiara nel proprio manifest solo il minimo: i due receiver vanno dichiarati dall'app. Senza, l'allarme viene registrato ma non raggiunge nessun componente — nessuna notifica e nessun errore lato Dart. In `android/app/src/main/AndroidManifest.xml` devono essere presenti:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

`RECEIVE_BOOT_COMPLETED` e il secondo receiver servono a riprogrammare le notifiche dopo un riavvio del telefono, che altrimenti le azzera tutte.

Il fuso orario del dispositivo viene letto con `flutter_timezone` e impostato
su `tz.local` all'avvio. Non è indispensabile per le schedulazioni attuali,
dato che `TZDateTime.from` preserva l'istante assoluto, ma lo diventa per
qualunque logica basata sull'ora di parete.

Per diagnosticare, `NotificationService` espone `debugStato()`, `isEnabled()`, `pendingCount()` e `showTestNotification()`. La voce "Notifiche" nel profilo apre le impostazioni di sistema dell'app.

Il file `android/app/src/main/res/raw/keep.xml` impedisce a R8 di scartare l'icona della notifica in release: viene risolta per nome a runtime, quindi il compilatore non ne vede alcun riferimento statico.

---

## Requisiti

- **Flutter SDK**, canale `stable` (progetto creato con la revision `058e0af2c2b`)
- **Dart SDK** `^3.12.2` (vincolo in `pubspec.yaml`)
- Un device Android o un emulatore — il progetto è configurato solo per Android
- **Java 17** e **core library desugaring** abilitato in `android/app/build.gradle`, richiesti da `flutter_local_notifications` 22.x; `minSdk` 24 o superiore
- Permessi già dichiarati nel manifest: fotocamera (scanner) e `POST_NOTIFICATIONS` (Android 13+)

---

## Avviare l'app

```bash
git clone https://github.com/NadalMattia/mealbase.git
cd mealbase/mealbase

flutter pub get

# Solo se hai modificato i modelli: rigenera gli adapter Hive
dart run build_runner build --delete-conflicting-outputs

flutter run
```

Per un APK installabile:

```bash
flutter build apk --release
```

L'output è in `build/app/outputs/flutter-apk/app-release.apk`.

> ℹ️ Le cartelle `build/`, `.dart_tool/` e `venv/` contengono solo output generato e sono in `.gitignore`. Si rigenerano con i comandi qui sopra, o con `pip install -r requirements.txt` per lo scraper.

⚠️ **Attenzione se rigeneri gli adapter.** `models/product.g.dart` e `models/shopping_item.g.dart` contengono una modifica manuale, segnalata da un commento nel punto esatto: la lettura della quantità accetta sia `int` sia `double` (`(fields[x] as num).toInt()`), così i prodotti salvati da versioni precedenti non fanno fallire l'apertura dell'intera dispensa. Rigenerare con `build_runner` sovrascrive la correzione: va riapplicata a mano, o sostituita con un adapter scritto su misura.

---

## APK pronto all'uso

L'APK viene compilato automaticamente a ogni versione taggata ed è
scaricabile dalla pagina delle
[Release](https://github.com/NadalMattia/mealbase/releases/latest).

Su Android potrebbe essere necessario abilitare "Installa da fonti
sconosciute" nelle impostazioni di sicurezza.

---

## Icona dell'app

Generata da `assets/icon/iconApp.jpg` con [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) (configurazione in fondo a `pubspec.yaml`). Per rigenerarla dopo aver sostituito l'immagine:

```bash
flutter pub get
dart run flutter_launcher_icons
```

---

## Scraper recensioni concorrenti

[`scraperApp/scraper.py`](scraperApp/scraper.py) è lo strumento usato per la **Competitive Assessment** della relazione. Scarica da Google Play, per i tre concorrenti diretti analizzati (KitchenPal, NoWaste, BestBefore), i metadati dell'app e fino a 1000 recensioni per lingua (italiano e inglese).

È codice Python, indipendente dal resto del progetto, e richiede un virtual environment separato.

```bash
# Dalla root del progetto
python -m venv venv

# Attiva l'ambiente
venv\Scripts\Activate.ps1      # Windows (PowerShell)
source venv/bin/activate       # macOS / Linux

pip install -r requirements.txt

python scraperApp/scraper.py
```

Al termine, in `scraperApp/`:

- `app_metadata.csv` — sviluppatore, download, rating delle tre app
- `dataset_3_apps.csv` — recensioni deduplicate, con colonne `App`, `Lingua`, `Valutazione`, `Utente`, `Data`, `Recensione`

Per uscire dall'ambiente virtuale: `deactivate`.

> ⚠️ Lo script usa le API pubbliche di Google Play tramite [`google-play-scraper`](https://pypi.org/project/google-play-scraper/): tempi e disponibilità dei dati dipendono dalla risposta di Google Play in quel momento.

---

## Qualità del codice

```bash
flutter analyze
```

`analysis_options.yaml` estende il set raccomandato di `flutter_lints` con alcune regole mirate ai problemi effettivamente incontrati nel progetto, tra cui `use_build_context_synchronously` e `unawaited_futures`.

```bash
flutter test
```

Ventidue test unitari in tre file:

- `test/notification_schedule_test.dart` — il calcolo dell'istante di
  notifica, compresi i casi limite che facevano sembrare le notifiche non
  funzionanti (prodotto in scadenza entro 24 ore, prodotto già scaduto)
- `test/pantry_sort_test.dart` — i quattro criteri di ordinamento e la
  gestione dei prodotti senza data di scadenza
- `test/models_test.dart` — i valori predefiniti dei modelli e la coerenza
  delle categorie

Due di questi file **replicano** logica che nel codice di produzione vive
dentro un metodo privato o dentro il `build` di un widget, e lo dichiarano
in testa. È un compromesso: rende la logica verificabile subito, ma va
tenuta allineata a mano. Estrarla in funzioni pure è il passo successivo, e
renderebbe i test veri test di regressione invece che verifiche di una
copia.

Non ci sono test di integrazione né widget test.

---

## Limiti noti e roadmap

L'app copre i requisiti a priorità **ALTA** del Requirements Brief, ma resta un MVP.

**Non implementato:**

- **Autenticazione e account** — le case sono locali al device
- **Sincronizzazione multi-dispositivo** — nessun backend, tutto su Hive locale
- **Condivisione familiare** — `HouseSettingsScreen` è un segnaposto
- **Rinomina ed eliminazione di una casa** — la schermata non esiste ancora
- **Suggerimento ricette** — voce in navigazione per continuità visiva
- **Dark mode**

**Limiti dell'implementazione attuale:**

- Filtri e ordinamenti della dispensa sono calcolati in memoria: con qualche migliaio di prodotti per casa servirebbe un database con supporto a query
- Tutte le stringhe dell'interfaccia sono in italiano, scritte direttamente nei widget
- L'id delle notifiche deriva dall'hash dell'id prodotto: funziona ed è coerente fra programmazione e cancellazione, ma non è garantito stabile fra versioni di Dart
- Rinomina ed eliminazione di una casa non sono implementate, pur essendo ora sicure da realizzare grazie ai box chiavati per id
- Su OEM aggressivi (Xiaomi, Huawei) le notifiche pianificate possono non arrivare per restrizioni di sistema indipendenti dal codice

Il progetto è strutturato per accogliere queste funzionalità senza stravolgimenti architetturali — vedi la sezione *Conclusione* della relazione.

---

## Autore

**Mattia Nadal**
Dipartimento di Scienze Matematiche, Informatiche e Fisiche
Università degli Studi di Udine
