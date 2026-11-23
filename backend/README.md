# Verdant Backend

REST API for the Verdant app. It manages the catalogue, accounts, security, orders, discounts, synced user data and optional emails.

The Flutter app is documented in the [main README](../README.md).

## Stack

| Area | Technology |
| --- | --- |
| Runtime | Node.js 22.13 or later |
| API | Express |
| Database | SQLite through `node:sqlite` |
| Authentication | scrypt password hashes, JWT sessions |
| Protection | Helmet, CORS, `express-rate-limit` |
| Logs | Morgan |
| Email | Nodemailer, optional |

## Getting started

```bash
cd backend
npm install
npm start
```

The API runs at `http://localhost:3000`. On first start it creates `data/verdant.db` and imports the catalogue from `src/data/products.json`.

| Command | Description |
| --- | --- |
| `npm start` | Start the server |
| `npm run dev` | Start the server and restart it on changes |
| `npm run make-admin -- someone@example.com` | Give an existing account admin rights |

On Windows, `start-backend.bat` runs the development server from any folder.

## Configuration

Every setting is optional in development. To change one, copy `.env.example` to `.env`.

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `3000` | API port |
| `NODE_ENV` | `development` | Use `production` for a deployed server |
| `JWT_SECRET` | Generated in development | Session signing key, **required in production** |
| `SESSION_DAYS` | `30` | Session length |
| `DATABASE_PATH` | `data/verdant.db` | SQLite file |
| `CORS_ORIGINS` | Empty | Browser origins allowed in production, comma-separated |
| `SMTP_URL` | Empty | SMTP server. Email is off when empty |
| `MAIL_FROM` | `Verdant <no-reply@verdant.local>` | Email sender |

`.env` and `data/` are not committed.

## Project structure

```text
backend/
  public/products/    Product images, served under /static
  scripts/            Admin command
  src/app.js          Express app and global middleware
  src/server.js       Server start
  src/config.js       Environment settings
  src/db.js           Database schema and catalogue import
  src/data/           Product catalogue
  src/middleware/     Authentication and error handling
  src/routes/         API endpoints
  src/services/       Auth, products, orders, user data, reminders and email
  src/utils/          Input validation
```

## Security

- **Passwords:** stored only as salted scrypt hashes and compared in constant time.
- **Sessions:** signed JWTs linked to a database session, so logout revokes them immediately. Changing the password signs out other devices.
- **Access control:** each user can read and change only their own data. Catalogue management and order status require an admin account.
- **Rate limits:** 300 requests per minute overall, and 20 attempts per 15 minutes on sensitive account routes.
- **Input:** request bodies are limited to 512 KB and validated on the server.
- **HTTP:** Helmet sets security headers. In production, CORS allows only the configured origins.
- **Payment data:** full card numbers and security codes are rejected. Only the brand, last 4 digits, holder and expiry date can be stored.
- **Secrets:** production refuses to start without `JWT_SECRET`.

## Business rules

- **Orders:** the client sends product ids and quantities. The server calculates prices, discount and delivery, and updates stock in one transaction.
- **Repeated requests:** an idempotency key prevents a retry from creating a second order.
- **Delivery:** standard costs $6 and is free from $100. Express costs $12.
- **Discounts:** codes are checked on the server. `GROW10` is valid only on the first order.
- **Order status:** an admin can set `placed`, `shipped`, `delivered` or `cancelled`. Cancelling puts the items back in stock.
- **Sync:** the app stores one JSON document per data type and account. If two devices edit the same data, the last change wins.
- **Reminder emails:** when SMTP is configured, a worker checks every minute and sends each due reminder once.

## API

Responses use the form `{ "success": true, "data": ... }`. Errors use `{ "success": false, "message": ..., "code": ..., "fields": ... }`.

Routes marked **User** need `Authorization: Bearer <token>`, and routes marked **Admin** also need an admin account. `GET /` returns a summary of the endpoints.

### Catalogue

| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| GET | `/api/products` | Public | Filter with `category`, `q`, `sort`, `minPrice`, `maxPrice`, `page`, `limit` |
| POST | `/api/products` | Admin | Create a product |
| GET | `/api/products/:id` | Public | Product details |
| PUT, DELETE | `/api/products/:id` | Admin | Update or delete a product |
| GET | `/api/products/:id/reviews` | Public | Product reviews |
| PUT | `/api/products/:id/reviews` | User | Add or update your review |
| GET | `/api/categories` | Public | Category list |
| GET | `/api/categories/:category` | Public | Products in a category |
| GET | `/api/featured` | Public | Up to 3 featured products |

Sort values are `price_asc`, `price_desc`, `name` and `rating`.

### Account

| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| POST | `/api/auth/register` | Public | Create an account |
| POST | `/api/auth/login` | Public | Sign in and get a token |
| POST | `/api/auth/logout` | User | Revoke the current session |
| GET, PATCH | `/api/me` | User | Read or edit the profile |
| DELETE | `/api/me` | User | Delete the account, password required |
| POST | `/api/me/password` | User | Change password and sign out other devices |

### User data

All routes require a signed-in user.

| Method | Endpoint | Description |
| --- | --- | --- |
| GET, DELETE | `/api/sync` | Download or erase the account's app data |
| PUT | `/api/sync/:key` | Save one data store |
| GET, PUT | `/api/cart`, `/api/settings`, `/api/addresses`, `/api/payment-methods`, `/api/reminders` | Read or replace a document |
| GET | `/api/favorites` | List favourites |
| PUT, DELETE | `/api/favorites/:productId` | Add or remove a favourite |
| GET, POST | `/api/plants` | List or add plants |
| GET, PATCH, DELETE | `/api/plants/:id` | Read, edit or remove a plant |
| POST | `/api/plants/:id/water` | Mark a plant as watered |
| GET | `/api/notifications` | List notifications |
| POST | `/api/notifications/read` | Mark notifications as read |
| GET, POST | `/api/sensors/:deviceId/readings` | Read or store sensor values |

### Orders

| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| POST | `/api/discounts/validate` | User | Check a discount code |
| GET, POST | `/api/orders` | User | List or place orders |
| GET | `/api/orders/:number` | User | Order details |
| PATCH | `/api/orders/:number/status` | Admin | Change the order status |

## Known limitations

- Payments and shipping are simulated.
- Password recovery is not included.
- Emails are only in English.
- Ratings on the first six products are placeholders until real reviews exist.
- SQLite suits this project's single-server setup.
