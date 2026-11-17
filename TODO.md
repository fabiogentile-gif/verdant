# TODO – Verdant

Analisi delle cartelle `lib/` (app Flutter) e `backend/` (API Express).
Stato aggiornato: il frontend è completo tranne le parti che richiedono **login/utenti**, **backend** o **hardware**.

---

## 🔴 Bug bloccanti

- [x] Errore di compilazione `OwnedPlant` duplicata.
- [x] Filtro categoria ignorato dal backend.
- [x] Test di default rotto.

---

## 📱 Frontend (`lib/`) – fatto

Dati salvati sul telefono (`shared_preferences`, `lib/data/storage.dart`): piante, promemoria, storico cure, carrello, metodi di pagamento (solo ultime 4 cifre), preferiti, ordini, indirizzo, impostazioni.

- [x] **Homepage**: campanella → pagina Notifiche con pallino "non letto"; ricerca e categorie aprono il Greenhouse filtrato; card stagionale cliccabile; prodotti in evidenza con preferiti e "+" carrello; pianta in evidenza e promemoria presi dal calendario cure.
- [x] **Greenhouse**: ricerca, categorie (filtrate sui dati reali), ordinamento, filtri (disponibili / preferiti), badge carrello, "Easy-grow edit", preferiti condivisi, divisione piante / accessori reale, errori di rete leggibili.
- [x] **Dettaglio prodotto**: tag → Greenhouse filtrato, "View all", preferiti condivisi, helper duplicati rimossi (`imageFor`, `lib/utils/money.dart`).
- [x] **Le mie piante**: aggiunta pianta (specie, nome, stanza) con promemoria automatico, filtro per stanza, dettaglio per tutte le piante.
- [x] **Dettaglio pianta**: menu ⋯ (modifica / promemoria / rimuovi), "Mark as watered", date reali, guida per specie (`PlantSpecies` in `lib/models/plant_details.dart`).
- [x] **Promemoria cure**: salvataggio reale (acqua / concime / rinvaso, ripetizione, giorni, data, ora, nota, push/email), eliminazione.
- [x] **Activity**: collegata al calendario condiviso con Homepage, Piante e dettaglio.
- [x] **Profilo**: I miei ordini (+ dettaglio), indirizzo, metodi di pagamento, promemoria, fuso orario, privacy e permessi (con "Erase my data"), aiuto (FAQ), About (con licenze font), tema scuro salvato, icona impostazioni.
- [x] **Notifiche**: `flutter_local_notifications` programma i promemoria (canale "Care reminders"), permesso Android 13+.
- [x] **Infrastruttura**: router con pagina 404 e rotte nominate (`/plant/:id`, `/orders/:n`, …), `ProductRepository` con timeout, cache ed errori tipizzati, banner debug tolto, app tutta in inglese (date incluse) con `flutter_localizations`, warning `page_header.dart` risolti, `StandardAppBar` spostata in `widgets/components/`.

## 📱 Frontend – rimandato

### Login / utenti (da fare insieme all'autenticazione)
- [ ] Nome "Maya" fisso (Homepage, Piante, Profilo) e "Plant parent · Portland, OR".
- [ ] "Edit profile", "Sign out", "Account & security" senza azione.
- [ ] Indirizzo demo precompilato (ora modificabile, ma non legato a un account).

### Richiede backend
- [ ] Codici sconto validati solo nell'app (`GROW10` in `Cart._codes`).
- [ ] Email reminders: la preferenza è salvata ma nessuna email viene inviata.
- [ ] Ordini, preferiti, piante e promemoria solo sul telefono (nessuna sincronizzazione).
- [ ] Stato ordine stimato dalle date ("Placed" / "On its way" / "Delivered"), non reale.

### Richiede hardware
- [ ] **Smart pot / sensori** (umidità, luce, temperatura): nessun dato reale disponibile; in `PRODUCT.md` è segnato come non deciso.

### Possibili migliorie
- [ ] Traduzione italiana (oggi l'app è tutta in inglese, già predisposta con `flutter_localizations`).
- [ ] Area di tocco < 48 dp su alcune icone (cuori sulle card prodotto, "+" carrello).
- [ ] Test automatici: la cartella `test/` è stata rimossa.

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
