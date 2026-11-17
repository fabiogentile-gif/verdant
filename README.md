# Verdant

A plant shop and a care companion in one Android app. Users buy plants and essentials in the **Greenhouse**. They add their plants to a personal collection and get care routines and reminders for each one.

School project built with Flutter (Material 3) and a small Express API for the product catalogue.

## Features

- **Home**: today's care, featured products, categories and search (search and categories open the shop already filtered).
- **Greenhouse (shop)**: search, categories, sorting, filters (in stock and favourites) and favourites shared across pages.
- **Product details**: gallery, care steps, quantity, related products.
- **Cart and checkout**: discount codes, standard or express delivery, delivery address, simulated card and PayPal payments, order confirmation.
- **My plants**: add, edit and remove plants, filter by room and by plant status (all or needing care), plant details with a care guide for each species.
- **Care reminders**: watering, fertilising and repotting. Each reminder can repeat or fall on chosen weekdays, and can have a start date, a time and a note. Android notifications are scheduled for them.
- **Activity**: care due today, what is coming up and the history of completed care.
- **Profile**: orders, address, payment methods, reminders, time zone, privacy (with "Erase my data"), help, dark mode.

All user data (plants, reminders, cart, favourites, orders, address, settings) is saved on the phone with `shared_preferences`. Saved cards keep only the brand, the last 4 digits, the holder and the expiry date.

> **Demo only:** payments are simulated and no real transaction happens. There are no user accounts yet, so the profile is a fixed demo user.

## Project structure

```
lib/
  main.dart            App entry point: restores saved data, theme, locale, routes
  shell.dart           Bottom navigation and the nested tab navigator
  router/              Route names and page factory (with a 404 page)
  data/                App state (cart, care schedule, plants, orders…), saved on the device
  models/              Products and plant species / care guides
  services/            Local notifications for care reminders
  pages/               Screens (profile/ holds the profile sub-pages)
  widgets/             Reusable components, grouped by area
  theme/               Light and dark themes, shadows
  utils/               Small helpers (price formatting)
backend/
  src/server.js        Express API
  src/data/            Product catalogue (JSON)
  products/            Product images served by the API
assets/                Fonts (Inter, Lora) and images
```

## Requirements

- Flutter SDK with Dart 3.13 or later
- Node.js and npm (for the backend)
- Android emulator or device. The app is designed for Android, and notifications only work there.

## Getting started

### 1. Start the backend

```bash
cd backend
npm install
npm start        # or: npm run dev (restarts on changes)
```

The API runs at `http://localhost:3000`. On Windows you can also run `start-backend.bat` from the project root, after `npm install`.

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
| GET    | `/api/products`              | All products (optional `?category=plants`)               |
| GET    | `/api/products/:id`          | Product details with care steps and related products     |
| GET    | `/api/categories`            | Category list (`plants`, `planters`, `accessories`)      |
| GET    | `/api/categories/:category`  | Products of one category                                 |
| GET    | `/api/featured`              | Featured products                                        |

Responses are wrapped as `{ "data": ... }`. Product images are served from the server root (e.g. `/product_white_orchid.png`).

## Useful commands

```bash
flutter analyze      # static analysis
dart format lib      # format the code
flutter build apk    # Android release build
```

## Roadmap

See [TODO.md](TODO.md). Still to do: user accounts and login, a backend for orders, discount codes and email reminders, and smart-pot sensors (humidity, light, temperature).

Design notes live in [DESIGN.md](DESIGN.md) and the product brief in [PRODUCT.md](PRODUCT.md).
