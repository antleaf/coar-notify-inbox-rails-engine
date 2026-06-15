# notify_inbox_test

A host Rails 8 application used to run and test the [coar_notify_inbox](../) engine. It mounts the engine and provides a real runtime environment — serving as the equivalent of a `test/dummy` app but runnable via Docker for both local development and production-like testing.

---

## Requirements

- Docker and Docker Compose

No local Ruby installation is needed. The image is self-contained.

---

## Quick start

```bash
cp .env.example .env
# Edit .env — set a real POSTGRES_PASSWORD and fill in RAILS_MASTER_KEY
docker compose up --build
```

The app will be available at `http://localhost:${WEB_PORT}/coar_notify_inbox`.

---

## Configuration

All configuration is driven by `.env`. Copy `.env.example` to get started:

```bash
cp .env.example .env
```

| Variable | Description | Default |
|---|---|---|
| `RAILS_ENV` | Rails environment | `production` |
| `POSTGRES_USER` | PostgreSQL username | `notify_inbox` |
| `POSTGRES_PASSWORD` | PostgreSQL password — **change this** | `changeme` |
| `POSTGRES_DB` | PostgreSQL database name | `notify_inbox_production` |
| `DB_HOST` | Database host (matches the `db` service name) | `db` |
| `DB_PORT` | Database port | `5432` |
| `RAILS_MASTER_KEY` | Key to decrypt `config/credentials.yml.enc` — required | _(blank)_ |
| `FORCE_SSL` | Set to `false` when running without an SSL proxy | `false` |
| `ASSUME_SSL` | Set to `false` when running without an SSL proxy | `false` |
| `WEB_PORT` | Host port the app is exposed on | `3001` |
| `DOCKER_VOLUMES_PATH_PREFIX` | Prefix for volume paths — empty for named volumes, absolute path for bind mounts | _(empty)_ |

### RAILS_MASTER_KEY

The master key decrypts `config/credentials.yml.enc`. It is gitignored and must be set manually.

If the key file has been lost, regenerate credentials:

```bash
cd .notify_inbox_test
rm config/credentials.yml.enc
EDITOR=/bin/true bin/rails credentials:edit
cat config/master.key   # copy this value into .env
```

Commit the new `config/credentials.yml.enc` and store the key in a password manager.

---

## Services

| Service | Description | Host port |
|---|---|---|
| `web` | Rails app (Puma) | `$WEB_PORT` (default 3001) |
| `db` | PostgreSQL 17 | Internal only — not exposed to host |

The database is internal to the Docker network. Solid Queue, Solid Cache, and Solid Cable all use the primary database connection — no additional services are required.

---

## Useful commands

```bash
# Start in the background
docker compose up -d

# Rebuild after code changes
docker compose up --build

# Rails console
docker compose exec web bin/rails console

# View logs
docker compose logs -f web

# Run migrations manually
docker compose exec web bin/rails db:migrate

# Stop and remove containers (keep data)
docker compose down

# Full reset — stop and delete all data
docker compose down -v
```

---

## Bootstrap — first admin user

There is no signup endpoint. Create the first admin via the Rails console:

```bash
docker compose exec web bin/rails console
```

```ruby
admin = CoarNotifyInbox::User.create!(
  name:     "Admin",
  username: "admin",
  role:     :admin,
  active:   true
)
puts admin.auth_token
```

Copy the token — it is required as `Authorization: Bearer <token>` on every API request.

---

## API overview

All endpoints are under `/coar_notify_inbox` and require `Authorization: Bearer <token>`.

| Method | Path | Role required | Description |
|---|---|---|---|
| `GET` | `/users` | Admin | List users |
| `POST` | `/users` | Admin | Create user |
| `PUT` | `/users/:id/activate` | Admin | Activate user |
| `PUT` | `/users/:id/auth_token` | Admin | Rotate token |
| `GET` | `/senders` | Any active | List senders |
| `POST` | `/senders` | Any active | Register sender origin |
| `PUT` | `/senders/:id/activate` | Admin | Activate sender |
| `GET` | `/consumers` | Any active | List consumers |
| `POST` | `/consumers` | Any active | Register consumer target |
| `PUT` | `/consumers/:id/activate` | Admin | Activate consumer |
| `GET` | `/notifications` | Any active | List notifications |
| `POST` | `/notifications` | Active sender | Submit notification |
| `GET` | `/notifications/sender/:uri` | Any active | Notifications by origin URI |
| `GET` | `/notifications/consumer/:uri` | Any active | Notifications by target URI |

Full API documentation: [../docs/API_DOCUMENTATION.md](../docs/API_DOCUMENTATION.md)

---

## End-to-end test flow

### 1. Create an admin (console)

```bash
docker compose exec web bin/rails console
```
```ruby
admin = CoarNotifyInbox::User.create!(name: "Admin", username: "admin", role: :admin, active: true)
puts admin.auth_token
```

### 2. Set shell variables

```bash
ADMIN_TOKEN="<token from above>"
BASE=`http://localhost:${WEB_PORT}/coar_notify_inbox`
```

### 3. Create and activate a regular user

```bash
curl -s -X POST $BASE/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user": {"name": "Alice", "username": "alice", "role": "user", "active": true}}' | jq .

ALICE_TOKEN="<auth_token from response>"
```

### 4. Register a sender and a consumer for Alice

```bash
# Sender (origin Alice publishes from)
curl -s -X POST $BASE/senders \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "origin_uri": "https://example-repo.org/articles/1",
    "target_uris": ["https://review-service.org"],
    "sender": {"active": true}
  }' | jq .

# Consumer (target Alice reads notifications for)
curl -s -X POST $BASE/consumers \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "target_uri": "https://review-service.org",
    "origin_uris": ["https://example-repo.org/articles/1"],
    "consumer": {"active": true}
  }' | jq .
```

### 5. Submit a notification

```bash
curl -s -X POST $BASE/notifications \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "Offer",
    "origin": {"id": "https://example-repo.org/articles/1", "type": "Service"},
    "target": {"id": "https://review-service.org", "type": "Service"},
    "object": {"id": "https://example-repo.org/articles/1/preprint", "type": "Document"}
  }' | jq .
# Expect: 201 Created
```

### 6. Read notifications back

```bash
# All notifications for Alice
curl -s -H "Authorization: Bearer $ALICE_TOKEN" $BASE/notifications | jq .

# By origin (sender view)
curl -s -H "Authorization: Bearer $ALICE_TOKEN" \
  "$BASE/notifications/sender/https%3A%2F%2Fexample-repo.org%2Farticles%2F1" | jq .

# By target (consumer view)
curl -s -H "Authorization: Bearer $ALICE_TOKEN" \
  "$BASE/notifications/consumer/https%3A%2F%2Freview-service.org" | jq .
```

### 7. Verify data survives a restart

```bash
docker compose restart web
curl -s -H "Authorization: Bearer $ALICE_TOKEN" $BASE/notifications | jq length
# Same count as before — data lives in Postgres, not the container
```
