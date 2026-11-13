# TODO – Verdant

Analisi delle cartelle `lib/` (app Flutter) e `backend/` (API Express).
Elenco delle funzionalità mancanti, incomplete o rotte, in ordine di priorità.

---

## 🔴 Bug bloccanti

- [x] **Errore di compilazione in `lib/pages/plants.dart:150`** – la classe `OwnedPlant` è definita due volte
  (`lib/data/owned_plants.dart` e `lib/pages/plants.dart`). `ownedPlants` usa quella di `data/`, mentre
  `PersonalPlantDetails` si aspetta quella di `pages/plants.dart` → `argument_type_not_assignable`.
  Eliminare la copia in `plants.dart` e far importare a `personal_plant_details.dart` quella di `data/owned_plants.dart`.
- [x] **Filtro categoria ignorato dal backend** – `ApiProductRepository.getProducts(category:)` chiama
  `GET /api/products?category=...`, ma `server.js` non legge `req.query.category` e restituisce sempre tutti i prodotti.
  Gestire la query string lato server (oppure usare `GET /api/categories/:category` lato app).
- [x] **Test di default rotto** – `test/widget_test.dart` è ancora il test "counter" del template Flutter; va riscritto.

---

## 📱 Frontend (`lib/`)

### Homepage (`lib/pages/homepage.dart`)
- [ ] Campanella notifiche: `onActionTap: () {}` – manca pagina/pannello notifiche e logica `hasUnread`
  (il pallino in `search_field.dart` → `_buildBell` è commentato).
- [ ] Barra di ricerca senza `onChanged`/`onSubmitted` – la ricerca non fa nulla.
- [ ] `PopularCategories`: la selezione cambia solo l'indice, non filtra né naviga verso il Greenhouse.
- [ ] `SeasonalFeatureCard` creata senza `onTap`.
- [ ] `FeaturedProducts`: `onFavoriteTap` e `onAddTap` non passati (preferiti / aggiunta al carrello).
- [ ] `PersonalCollection`: dati della pianta hardcoded (Monstera) e `onPlantTap: () {}` – dovrebbe aprire `PersonalPlantDetails`
  e prendere la pianta che ha bisogno di cure da `ownedPlants`.
- [ ] `UpcomingCare`: promemoria hardcoded, `onViewAll: () {}` e nessun `onTap` sui singoli promemoria.
- [ ] Nome utente "Maya" hardcoded nel titolo.

### Greenhouse / Shop (`lib/pages/greenhouse.dart`)
- [x] Carrello: modello `lib/data/cart.dart` + pagina `lib/pages/cart.dart` (rotta `/cart`). Checkout in `lib/pages/checkout.dart` con pagamento simulato (carta o PayPal finti, `lib/data/payment.dart`). Restano: badge quantità sull'icona, persistenza (carrello e metodi di pagamento si svuotano al riavvio), indirizzo di consegna fisso (Maya Thompson), storico ordini.
- [ ] Barra di ricerca senza `onChanged` – la ricerca prodotti non funziona.
- [ ] Chip categorie: `_categoryIndex` viene aggiornato ma i prodotti non vengono filtrati. Inoltre le categorie della UI
  (`Indoor Plants`, `Outdoor Plants`, `Pots`, `Soil`, `Fertilizers`, `Accessories`) non corrispondono a quelle del backend
  (`plants`, `planters`, `accessories`) → valutare di caricarle da `GET /api/categories`.
- [ ] `_FeaturedCollection(onTap: () {})` – nessuna azione.
- [ ] `_SortAndFilter`: è solo grafica, manca ordinamento (prezzo, nome, rating…) e pannello filtri.
- [x] `ProductCard.onAddTap: () {}` – aggiunta al carrello non implementata.
- [ ] Preferiti salvati solo in memoria (`Set<int>`), persi al cambio tab; non condivisi con la pagina dettaglio/homepage.
- [ ] Divisione "favorites" / "recommended" basata su `take(4)`/`skip(4)` invece che su dati reali.
- [x] `ShopProduct.tag` mai valorizzato in `fromSummary`.

### Dettaglio prodotto (`lib/pages/product_details.dart`)
- [x] `onAddToCart: () {}` – manca l'aggiunta al carrello con la quantità selezionata.
- [ ] Codici sconto validati solo lato app (`GROW10` in `Cart._codes`) → spostarli sul backend.
- [ ] Tag prodotto (`AppFilterChip`) con `onTap: () {}`.
- [x] Prodotti correlati: `onAddTap: () {}`.
- [ ] Preferito (`_favorite`, `_relatedFavorites`) solo locale, non persistito né sincronizzato.
- [ ] Duplicazioni da rimuovere: `_imageFor` (esiste già `imageFor` in `product_repository.dart`) e `_price`
  (formattazione prezzo ripetuta anche in homepage e greenhouse → creare un helper comune o usare `intl`).

### Le mie piante (`lib/pages/plants.dart`)
- [ ] Pulsante "+" in app bar e "Add a plant to your collection": `onPressed: () {}` – manca il flusso di aggiunta pianta.
- [ ] Chip "By room": `onTap: () {}` – manca il filtro per stanza.
- [ ] Le piante senza `details` (tutte tranne la Monstera) non aprono nulla al tap.
- [ ] Dati delle piante hardcoded in `lib/data/owned_plants.dart` – manca un repository (API o storage locale) come per i prodotti.

### Dettaglio pianta personale (`lib/pages/personal_plant_details.dart`)
- [ ] Menu "altro" (`onMore: () {}`) – modifica / rimozione pianta.
- [ ] "Mark as watered": `onPressed: () {}` – dovrebbe aggiornare ultima annaffiatura, stato e storico.
- [ ] "Schedule a care reminder": `onPressed: () {}` – manca la creazione di promemoria.
- [ ] Etichette date (`lastWateredLabel`, `nextCareLabel`, `history`…) sono stringhe statiche: servono `DateTime` reali
  e calcolo del prossimo intervento.

### Activity (`lib/pages/activity.dart`)
- [x] Pagina completa: riepilogo, oggi, in arrivo, storico (dati in `lib/data/care_schedule.dart`, relativi a oggi, solo in memoria).
- [x] Icona calendario: apre la scelta del periodo (7/14/30 giorni).
- [ ] Collegare `careSchedule` anche a Homepage (UpcomingCare), pagina Piante (stato "Needs water") e dettaglio pianta ("Mark as watered"), che usano ancora testi fissi.
- [ ] Salvare davvero i promemoria creati da "Edit care reminder" nel `careSchedule`.

### Profilo (`lib/pages/profile.dart`)
- [ ] Azione app bar `onActionTap: () {}`.
- [ ] `onOpenPlants` mai passato dal router (`Profile()` in `router.dart`) → il link alla collezione non funziona;
  usare `AppShell.of(context)?.goTotab(AppRoutes.plants)`.
- [ ] Tutte le voci senza implementazione: My orders, Saved addresses, Payment methods, Care reminders, Time zone,
  Account & security, Privacy & permissions, Help & support, About Verdant.
- [ ] "Edit profile" e "Sign out": `onPressed: () {}` – manca autenticazione / gestione utente.
- [ ] Toggle push/email solo in stato locale, non persistiti né collegati a un sistema di notifiche.
- [ ] Dark mode: `themeMode` non viene salvato (si perde al riavvio) – es. `shared_preferences`.
- [ ] Dati utente ("Maya", "Portland, OR") hardcoded.

### Generale / infrastruttura
- [ ] **Notifiche** (obiettivo del progetto: "smart pots with notification system"): nessuna integrazione
  (es. `flutter_local_notifications` / FCM).
- [ ] **Smart pot**: nessun modello/servizio per sensori (umidità, luce, temperatura) o collegamento dispositivi.
- [ ] Gestione stato globale assente (carrello, preferiti, utente, piante) – valutare Provider/Riverpod o simili.
- [ ] `ProductRepository`: nessun timeout, nessuna cache, nessuna gestione errori di rete tipizzata;
  manca un repository equivalente per piante, utente, ordini.
- [ ] Router: nessuna pagina 404 (`onGenerateRoute` restituisce `null` per rotte sconosciute) e nessuna rotta
  nominata per `PersonalPlantDetails`.
- [ ] `main.dart`: `debugShowCheckedModeBanner: true` da rimettere a `false` ("da togliere dopo").
- [ ] Localizzazione: le date usano `it_IT` ma tutti i testi sono in inglese hardcoded → introdurre `flutter_localizations`/ARB.
- [ ] Warning `flutter analyze` in `lib/widgets/components/page_header.dart` (righe 34, 45, 50: `!` inutili, initializing formal).
- [ ] File fuori posto: `lib/search_field.dart` contiene `StandardAppBar` → spostarlo in `lib/widgets/components/`.

---

## 🖥️ Backend (`backend/`)

### Prodotti
- [ ] Supporto query string su `GET /api/products`: `category`, `search`/`q`, `sort`, `minPrice`/`maxPrice`, paginazione (`page`, `limit`).
- [ ] `GET /api/products` restituisce l'oggetto completo; l'app si aspetta una versione "summary" (`id, name, price, image, tag`) → alleggerire la risposta.
- [ ] `GET /api/featured`: il commento dice "top 3" ma non c'è alcun limite.
- [ ] Endpoint `GET /api/categories/:category` non elencato nella root `/` (documentazione endpoint incompleta).
- [ ] CRUD prodotti (POST/PUT/DELETE) per amministrazione; il campo `stock` non viene mai aggiornato.
- [ ] Validazione `id` (`parseInt` può dare `NaN` → 404 generico invece di 400).

### Funzionalità mancanti
- [ ] **Autenticazione utenti** (registrazione, login, JWT/sessioni, logout) e profilo utente (`/api/me`).
- [ ] **Carrello** (`/api/cart`) e **ordini** (`/api/orders`, storico, stato spedizione).
- [ ] **Preferiti** (`/api/favorites`).
- [ ] Indirizzi e metodi di pagamento (`/api/addresses`, `/api/payment-methods`) / integrazione pagamenti.
- [ ] **Piante dell'utente** (`/api/plants`): CRUD, dettagli cura, storico eventi, "mark as watered".
- [ ] **Promemoria / notifiche** (`/api/reminders`, `/api/notifications`) e invio push/email.
- [ ] **Smart pot / sensori**: endpoint per ricevere e leggere letture dei dispositivi.
- [ ] Recensioni (`rating`/`reviewCount` sono statici nel JSON).
- [ ] Impostazioni utente (notifiche, fuso orario, tema).

### Infrastruttura
- [ ] Database reale al posto di `src/data/products.json` (caricato una sola volta, `loadProducts()` non attesa prima di `app.listen`).
- [ ] Middleware di gestione errori centralizzato e handler 404 per rotte inesistenti.
- [ ] Validazione input (`express.json()` presente ma nessun endpoint POST).
- [ ] Rate limiting, logging richieste (es. `morgan`), configurazione via `.env` (`dotenv`).
- [ ] CORS aperto a tutte le origini (`cors()` senza opzioni) → restringere in produzione.
- [ ] Organizzazione codice: tutte le rotte in `server.js` → separare in `routes/`, `controllers/`, `services/`.
- [ ] `tsconfig.json` presente ma il progetto è JavaScript puro (nessun `typescript` nelle dipendenze) → migrare a TS o rimuoverlo.
- [ ] Nessun test (`npm test` non definito) – aggiungere Jest/Supertest.
- [ ] `start-backend.bat` esegue `cd backend`: funziona solo se lanciato dalla root del progetto, non dalla cartella `backend/`.
- [ ] Immagini servite da `backend/products/` come static root: spostarle in `public/` o simile e servirle sotto un prefisso (es. `/static`).
