# Verdant

A plant shop and a care companion in one Android app. Users buy plants and essentials in the **Greenhouse**. They add their plants to a personal collection and get care routines and reminders for each one.

School project built with Flutter (Material 3) and an Express API with a SQLite database.

## Features

- **Accounts**: sign up, sign in, sign out, edit profile, change password, delete account.
- **Home**: today's care, featured products, categories and search (search and categories open the shop already filtered).
- **Greenhouse (shop)**: search, categories, sorting, filters (in stock and favourites) and favourites shared across pages.
- **Product details**: gallery, care steps, quantity, related products.
- **Cart and checkout**: discount codes, standard or express delivery, delivery address, simulated card and PayPal payments, order confirmation.
- **My plants**: add, edit and remove plants, filter by room and by plant status (all or needing care), plant details with a care guide for each species.
- **Care reminders**: watering, fertilising and repotting. Each reminder can repeat or fall on chosen weekdays, and can have a start date, a time and a note. Android notifications are scheduled for them.
- **Activity**: care due today, what is coming up and the history of completed care.
- **Profile**: orders, address, payment methods, reminders, time zone, language (phone, Italian or English), privacy (with "Erase my data"), help, dark mode.

User data (plants, reminders, cart, favourites, orders, address, settings) is cached on the phone and synced to the account, so offline edits upload when the connection returns. Saved cards keep only the brand, the last 4 digits, the holder and the expiry date.

> **Demo only:** payments are simulated and no real transaction happens.

## Project structure

```
lib/
  main.dart            App entry point: restores saved data, theme, locale, routes
  shell.dart           Bottom navigation and the nested tab navigator
  router/              Route names and page factory (with a 404 page)
  data/                App state, session, API client and sync
  models/              Products and plant species / care guides
  services/            Local notifications for care reminders
  pages/               Screens (profile/ holds the profile sub-pages)
  widgets/             Reusable components, grouped by area
  l10n/                Language handling and the Italian dictionary (it.dart)
  theme/               Light and dark themes, shadows
  utils/               Small helpers (price formatting)
backend/
  src/app.js           Express app; server.js starts it
  src/routes/          HTTP endpoints
  src/services/        Auth, products, orders, sync, email
  src/middleware/      Authentication and error handling
  src/data/            Catalogue imported into SQLite on first start
  public/products/     Product images, served under /static
  test/                API tests
test/                  Flutter tests
assets/                Fonts (Inter, Lora) and images
```

## Requirements

- Flutter SDK with Dart 3.13 or later
- Node.js 22.13 or later and npm (for the backend)
- Android emulator or device. The app is designed for Android, and notifications only work there.

## Getting started

### 1. Start the backend

```bash
cd backend
npm install
npm start        # or: npm run dev (restarts on changes)
```

The API runs at `http://localhost:3000` and creates its database in `backend/data/`. On Windows you can also run `backend/start-backend.bat` after `npm install`.

Settings are optional in development: copy `backend/.env.example` to `backend/.env` to change them. Production requires `JWT_SECRET`, and email needs `SMTP_URL`. To give an account admin rights, run `npm run make-admin -- someone@example.com`.

### 2. Run the app

```bash
flutter pub get
flutter run
```

The app picks the backend address automatically:

| Platform         | Address used             |
| ---------------- | ------------------------ |
| Android emulator | `http://10.0.2.2:3000`   |
| Others           | `http://localhost:3000`  |

On a real phone, pass your computer's address on the local network:

```bash
flutter run --dart-define=API_ORIGIN=http://192.168.1.10:3000
```

## API

| Method | Endpoint                     | Description                                              |
| ------ | ---------------------------- | -------------------------------------------------------- |
| GET    | `/api/products`              | Summaries (`category`, `q`, `sort`, `minPrice`, `maxPrice`, `page`, `limit`) |
| GET    | `/api/products/:id`          | Product details with care steps and related products     |
| GET    | `/api/categories`            | Category list (`plants`, `planters`, `accessories`)      |
| GET    | `/api/categories/:category`  | Products of one category                                 |
| GET    | `/api/featured`              | Up to 3 featured products                                |
| POST   | `/api/auth/register`         | Create an account                                        |
| POST   | `/api/auth/login`            | Sign in, returns a token                                 |
| POST   | `/api/auth/logout`           | Revoke the current session                               |
| GET, PATCH, DELETE | `/api/me`        | Read, edit or delete the account                         |
| GET, POST | `/api/orders`             | Order history, place an order                            |
| GET, PUT, DELETE | `/api/sync`        | Sync the app's data (`PUT /api/sync/:key`)               |

`GET /` lists every endpoint, including cart, favourites, plants, reminders, notifications and sensors. Account routes need `Authorization: Bearer <token>`. Responses are wrapped as `{ "data": ... }`. Product images are served under `/static/products/`.

## Useful commands

```bash
flutter analyze      # static analysis
flutter test         # app tests
npm test             # API tests (from backend/)
dart format lib      # format the code
flutter build apk    # Android release build
```

## Roadmap

Still to do: real payments and shipping, physical smart-pot sensors, password recovery by email and Italian emails.
