# API Documentation — COAR Notify Inbox

This document describes the HTTP API provided by the `coar_notify_inbox` engine for **Users**, **Senders**, and **Consumers**.
Base path (when the engine is mounted at `/coar_notify_inbox`):

```
BASE_URL = http://localhost:3000/coar_notify_inbox
```

All requests require authentication with a user token unless otherwise noted.

---

## Authentication

- Every request (except when running in a development console) must include an Authorization header:

```
Authorization: Bearer <auth_token>
```

- Tokens are generated when a `User` is created. Admin users can rotate tokens via the API.

---

# Users API

### Summary
Manage engine users (admin-only creation). Users have `role` (user|admin), `username`, `name`, `auth_token`, and `active` flags.

### Endpoints

#### GET /users
List users.

- Auth: required (must be active). Admin can list all; non-admins — ability controlled by CanCan (usually not allowed).
- Response: array of users.

**curl**
```bash
curl -H "Authorization: Bearer <ADMIN_TOKEN>" \
  GET http://localhost:3000/coar_notify_inbox/users
```

**Success (200)**
```json
[
  { "id": 1, "name": "Admin", "username": "admin", "role": "admin", "active": true, "created_at": "...", "updated_at": "..." },
  { "id": 2, "name": "Test", "username": "testuser", "role": "user", "active": true, "created_at": "...", "updated_at": "..." }
]
```

#### POST /users
Create a user. **Admin-only**.

- Body params (JSON):
  - `user`: object with `name` (required), `username` (required, unique), `role` (optional; `user` or `admin`), `active` (optional).
- On success returns new `auth_token`.

**curl**
```bash
curl -X POST http://localhost:3000/coar_notify_inbox/users \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Test User",
      "username": "testuser",
      "role": "user",
      "active": true
    }
  }'
```

**Success (201)**
```json
{ "message": "User created", "auth_token": "abc123...", "id": 42 }
```

**Errors**
- `403 Forbidden` — when non-admin attempts to create.
- `409 Conflict` — username already exists.
- `422 Unprocessable Entity` — invalid fields.

#### GET /users/:id
Show user.

**curl**
```bash
curl -H "Authorization: Bearer <ADMIN_TOKEN>" \
  GET http://localhost:3000/coar_notify_inbox/users/42
```

**Success (200)**
```json
{ "id": 42, "name": "Test User", "username": "testuser", "role": "user", "active": true, "created_at":"...", "updated_at":"..." }
```

#### PUT /users/:id
Update user details. Only admin can set `active: true`. Non-admins cannot activate.

- Allowed fields: `name`, `active` (admin only).
- Request body: `{ "user": { "name": "New name", "active": false } }`

**Success (200)**
```json
{ "message": "User updated", "data": { "id": 42, "name": "New name", "active": false, "created_at": "...", "updated_at":"..." } }
```

**Errors**
- `422 Unprocessable Entity` — validation failures.

#### PUT /users/:id/auth_token
Rotate/re-generate a user's token. **Admin-only**.

**curl**
```bash
curl -X PUT http://localhost:3000/coar_notify_inbox/users/42/auth_token \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

**Success (200)**
```json
{ "auth_token": "<new-token>" }
```

#### PUT /users/:id/activate
Activate a user (set `active` to true). **Admin-only**.

**curl**
```bash
curl -X PUT http://localhost:3000/coar_notify_inbox/users/42/activate \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

**Success (200)**
```json
{ "message": "User activated successfully" }
```

---

# Senders API

### Summary
Senders represent sources of notifications. Unique constraint: **username + origin_uri**. Only the user who owns the username (or admin) can manage senders.

- `username` is used as owner key (string).
- `origin_uri`: single string.
- `target_uris`: array of strings.
- `active` boolean: only admin can set `true`; both admin/user can set to `false`.
- Duplicate create (username + origin_uri exists) → `409 Conflict`.

### Endpoints

#### GET /senders
List senders.

- Admin: list all.
- Non-admin: list only those where `username == current_user.username`.

**curl**
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  GET http://localhost:3000/coar_notify_inbox/senders
```

**Success (200)**
```json
[
  { "id": 1, "username": "testuser", "origin_uri": "https://origin/a/", "target_uris": ["https://t/1/"], "active": false, "created_at":"..." }
]
```

#### POST /senders
Create a sender.

- Request body (examples accept `sender` object or top-level):
```json
{
  "sender": {
    "origin_uri": "https://origin.example/coar_notify/",
    "active": false
  },
  "user_name": "testuser",       // when current_user is admin and wants to create for another user
  "target_uris": [
    "https://target.example/inbox/",
    "https://target2.example/inbox/"
  ]
}
```

**Rules**
- If `current_user` is admin and `username` is provided, the engine checks that provided username exists and is active; otherwise returns `422`.
- If `current_user` is non-admin, `username` is ignored and `current_user.username` is used.
- If a sender with `(username, origin_uri)` already exists: return `409 Conflict` with message to update instead.
- If non-admin sets `active: true`, it will be forced `false`.

**Success (201)**
```json
{ "id": 10, "username": "testuser", "origin_uri": "https://origin.example/coar_notify/", "target_uris": ["https://target.example/inbox/"], "active": false }
```

**Errors**
- `409 Conflict` — duplicate entry (username + origin_uri).
- `422 Unprocessable Entity` — invalid payload, missing required fields.

#### PUT /senders/:id
Update sender. Only certain fields permitted: `origin_uri` (must still be unique with username), `target_uris` (replace exact), `active` (only admin can set `true`, both can set `false`).

- Request body example:
```json
{
  "sender": {
    "origin_uri": "https://origin.example/new/",
    "active": false,
    "target_uris": ["https://targetA/","https://targetB/"]
  }
}
```

**Notes**
- `username` cannot be changed.
- If `origin_uri` is changed, it must not conflict with another sender for same username (409 on conflict).
- `target_uris` are replaced exactly with the provided payload (current behavior; TODO in code allows changing this later).

**Success (200)**
```json
{ "id": 10, "username": "testuser", "origin_uri": "https://origin.example/new/", "target_uris": ["https://targetA/"], "active": false }
```

#### PUT /senders/:id/activate
Admin-only endpoint to set `active: true`.

**curl**
```bash
curl -X PUT http://localhost:3000/coar_notify_inbox/senders/10/activate \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

**Success (200)**
```json
{ "id": 10, "username": "testuser", "origin_uri": "...", "active": true }
```

---

# Consumers API

### Summary
Consumers represent endpoints that receive notifications. Unique constraint: **username + target_uri**.

- `username` is owner key (string).
- `target_uri` single string.
- `origin_uris` array of origin URIs.
- `active` boolean: only admin can set `true`; both admin/user can set `false`.

### Endpoints

#### GET /consumers
List consumers.

- Admin: list all.
- Non-admin: list only those where `username == current_user.username`.

**Success (200)**
```json
[
  { "id": 5, "username": "testuser", "target_uri": "https://consumer.example/inbox/", "origin_uris": ["https://origin.example/inbox/"], "active": false }
]
```

#### POST /consumers
Create a consumer.

- Body example:
```json
{
  "consumer": {
    "target_uri": "https://consumer.example/inbox/",
    "active": false
  },
  "origin_uris": ["https://origin.example/inbox/"]
}
```

**Rules**
- Admin may pass `username` to create a consumer for another user — the engine verifies the username exists & is active.
- If consumer `(username, target_uri)` already exists → `409 Conflict`.
- If non-admin sets `active: true` → will be forced `false`.

**Success (201)**
```json
{ "id": 5, "username": "testuser", "target_uri":"https://consumer.example/inbox/", "origin_uris":["https://origin.example/inbox/"], "active": false }
```

#### PUT /consumers/:id
Update consumer (allowed fields: `target_uri`, `origin_uris`, `active` with admin restriction).

- `username` cannot be changed.
- `origin_uris` are replaced with provided payload (TODO: option to append instead).

**Success (200)**
```json
{ "id": 5, "username": "testuser", "target_uri":"https://consumer.example/inbox/", "origin_uris":["https://origin.example/inbox/","https://origin2.example/inbox/"], "active": false }
```

#### PUT /consumers/:id/activate
Admin-only — set active = true.

---

# Origins & Targets (background indexing)

- When Senders or Consumers are created/updated, the engine enqueues `CoarNotifyInbox::UpdateOriginsTargetsJob` (ActiveJob) to maintain two tables:
  - `coar_notify_inbox_origins` — rows: `{ id, uri, senders: [ids], consumers: [ids] }`
  - `coar_notify_inbox_targets` — rows: `{ id, uri, senders: [ids], consumers: [ids] }`
- These are maintained as JSON arrays and updated with optimistic-locking & retries to avoid lost updates under concurrency.
- This work is **asynchronous** (non-blocking) and may appear in the DB a short time after the API response completes.

---

# Error codes & common responses

- `200 OK` — successful read/update
- `201 Created` — resource created
- `202 Accepted` — used for async flows if applicable (not used in current APIs)
- `301 / 303` — reserved for notification redirect semantics (not used by default)
- `401 Unauthorized` — missing or invalid auth token
- `403 Forbidden` — insufficient privileges (e.g., non-admin trying admin action)
- `409 Conflict` — duplicate unique combination (username + origin_uri or username + target_uri)
- `422 Unprocessable Entity` — validation errors (missing fields, invalid payload)
- `500 Internal Server Error` — unexpected server errors (check logs)

---

# Example flows (quick)

## 1. Create user (admin)
Use Rails console or `POST /users` (admin token).

## 2. Create consumer (testuser)
```bash
curl -X POST "{{BASE_URL}}/consumers" \
  -H "Authorization: Bearer <TESTUSER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "consumer": { "target_uri": "https://consumer.local/inbox/", "active": false },
    "origin_uris": ["https://origin.local/inbox/"]
  }'
```

## 3. Create sender (testuser)
```bash
curl -X POST "{{BASE_URL}}/senders" \
  -H "Authorization: Bearer <TESTUSER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "sender": { "origin_uri": "https://origin.local/coar_notify/", "active": false },
    "target_uris": ["https://consumer.local/inbox/"]
  }'
```

## 4. Create notification (example)
Notification ingestion uses the COAR Notify payload and requires a matching consumer (`target.inbox` must equal consumer.target_uri). See notifications docs.