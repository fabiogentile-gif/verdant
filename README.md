# Verdant

A plant shop and a care companion in one Android app. Users buy plants and essentials in the **Greenhouse**, add their plants to a personal collection, and get care routines and reminders for each one.

| Part | Folder | Technology | Documentation |
| --- | --- | --- | --- |
| **Frontend** | `lib/`, `assets/` | Flutter, Dart, Material 3 | This file |
| **Backend** | `backend/` | Node.js, Express, SQLite | [backend/README.md](backend/README.md) |

The frontend handles the interface and the user experience. The backend handles accounts, security, business rules and stored data.

> **Demo only:** payments are simulated. No money is charged and nothing is shipped.

## Features

- **Accounts**: sign up, sign in, sign out, edit profile, change password and delete account.
- **Home**: today's care, featured products, categories and search.
- **Greenhouse**: 16 products with search, categories, sorting, in-stock and favourites filters.
- **Product details**: care guide, quantity and related products.
- **Cart and checkout**: discount codes, standard or express delivery, delivery address, simulated card and PayPal payments.
- **Orders**: history, details and delivery status.
- **My plants**: add, edit and remove plants, filter by room or care needed, and read a care guide for each species.
- **Care reminders**: watering, fertilising and repotting, with repeats, weekdays, start date, time and notes. Android notifications are scheduled on the phone.
- **Activity**: care due today, what is coming up and completed care.
- **Languages**: English and Italian, including the catalogue, dates and prices. The app can follow the phone's language.
- **Profile**: address, payment methods, reminders, language, dark mode, privacy, "Erase my data" and help.

## Frontend stack

| Area | Technology |
| --- | --- |
| Framework | Flutter, Dart, Material 3 |
| Local data | `shared_preferences` |
| Session token | `flutter_secure_storage` |
| Network | `http` |
| Notifications | `flutter_local_notifications`, `timezone` |
| Languages and dates | `flutter_localizations`, `intl` |
| Icons and fonts | Lucide, Inter, Lora |

## Getting started

### Requirements

- Flutter SDK with Dart 3.13.4 or later
- An Android emulator or device
- The backend running, as described in [backend/README.md](backend/README.md)

### Run the app

From the project root:

```bash
flutter pub get
flutter run
```

The Android emulator reaches the backend at `http://10.0.2.2:3000` automatically. On a real phone, use your computer's address on the same network:

```bash
flutter run --dart-define=API_ORIGIN=http://192.168.1.10:3000
```

### Try it

1. Create an account in the app.
2. Add a delivery address in **Profile**.
3. Add a simulated card with number `4242 4242 4242 4242` and any future expiry date.
4. Use the code `GROW10` for 10% off the first order.

## Project structure

```text
lib/
  main.dart           App entry point, theme, language and routes
  shell.dart          Bottom navigation and tab navigator
  data/               App state, session, API client and sync
  l10n/               Language handling and Italian dictionary
  models/             Products, plant species and care guides
  pages/              Screens
  router/             Named routes and 404 page
  services/           Local notifications
  theme/              Light and dark themes
  utils/              Small helpers
  widgets/            Reusable components
assets/               Fonts and images
```

## How the app works

- **State:** each area, such as the cart, plants or settings, has a shared store that pages listen to.
- **Offline use:** stores save on the phone first and upload to the account afterwards. Changes made offline are kept and sent when the connection returns.
- **Forms:** the app checks fields to give immediate feedback. The backend makes the final decision.
- **Translations:** English text is the key. Interface text uses `'Sign in'.tr` or `trArgs('Order {0}', [number])`, and Italian text lives in `lib/l10n/it.dart`. Missing translations fall back to English.
- **Themes:** light and dark themes are defined in `lib/theme/theme.dart`.

## Useful commands

```bash
flutter analyze      # static analysis
dart format lib      # format Dart code
flutter build apk    # Android release build
```

## Troubleshooting

- **Black screen on the emulator:** in Android Studio, open **Device Manager → your device → Edit → Additional settings** and set **Graphics acceleration** to **Software**. Then restart the emulator.
- **The app can't reach the greenhouse:** check that the backend is running. On a real phone, use `API_ORIGIN` and keep the phone and computer on the same network.

## Known limitations

- Payments and shipping are simulated.
- Password recovery is not included.
- The app has no screen for writing reviews or showing sensor data.
- New products appear in English until their text is added to the Italian dictionary.

## Credits

The Inter and Lora fonts are licensed under the SIL Open Font License. The license texts are in `assets/fonts/`.
