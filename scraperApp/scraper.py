import os
import pandas as pd
from google_play_scraper import Sort, reviews

os.makedirs('scraperApp', exist_ok=True)

APPS = {
    'KitchenPal': 'fr.icuisto.icuisto',
    'NoWaste': 'com.khcreations.nowaste',
    'BestBefore': 'com.peytu.bestbefore'
}

all_reviews = []

print("🚀 Inizio scraping delle recensioni...")

for app_name, app_id in APPS.items():
    print(f"\nScaricamento per: {app_name} ({app_id})...")
    
    # --- Scarica recensioni in Italiano ---
    try:
        res_it, _ = reviews(
            app_id,
            lang='it',
            country='it',
            sort=Sort.NEWEST,
            count=1000  # numero recensioni da scaricare 
        )
        for r in res_it:
            r['app_name'] = app_name
            r['lingua'] = 'IT'
            all_reviews.append(r)
        print(f"Recensioni IT trovate: {len(res_it)}")
    except Exception as e:
        print(f"Errore IT per {app_name}: {e}")

    # --- Scarica recensioni in Inglese ---
    try:
        res_en, _ = reviews(
            app_id,
            lang='en',
            country='us',
            sort=Sort.NEWEST,
            count=1000
        )
        for r in res_en:
            r['app_name'] = app_name
            r['lingua'] = 'EN'
            all_reviews.append(r)
        print(f"Recensioni EN trovate: {len(res_en)}")
    except Exception as e:
        print(f"Errore EN per {app_name}: {e}")

df = pd.DataFrame(all_reviews)

if not df.empty:
    # Manteniamo le colonne fondamentali + la lingua
    columns_to_keep = ['app_name', 'lingua', 'score', 'userName', 'at', 'content']
    df_filtered = df[columns_to_keep].copy()

    # Rinominiamo le colonne
    df_filtered.columns = ['App', 'Lingua', 'Valutazione', 'Utente', 'Data', 'Recensione']

    # ELIMINAZIONE DUPLICATI REALE: Rimuove righe con stesso utente, testo e app
    df_filtered = df_filtered.drop_duplicates(subset=['App', 'Utente', 'Recensione'])

    # 3. Salva in CSV
    output_path = os.path.join('scraperApp', 'dataset_3_apps.csv')
    df_filtered.to_csv(output_path, index=False, encoding='utf-8-sig')

    print(f"\n Operazione completata!")
    print(f" Dataset salvato in: '{output_path}'")
    print(f" Totale recensioni uniche estratte: {len(df_filtered)}")
else:
    print("\n Nessuna recensione estratta.")