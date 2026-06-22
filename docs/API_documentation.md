# API documentation — COAR Notify Inbox

This document describes the HTTP API provided by the `coar_notify_inbox` engine for **Users**, **Senders**, and **Consumers**.
Base path (when the engine is mounted at `/coar_notify_inbox`):

```
BASE_URL = http://localhost:3000/coar_notify_inbox
```

All requests require authentication with a user token unless otherwise noted.

---

## Authentication

Every request must include an Authorization header:

```
Authorization: Bearer <auth_token>
```

Tokens are generated when a `User` is created. Admin users can rotate tokens via the API.

---

## Users API

### Summary
Manage engine users (admin-only creation). Users have `role` (user|admin), `username`, `name`, `auth_token`, and `active` flags.

### Endpoints

#### GET /users
List users.

- Auth: required (must be active). Admin can list all; non-admins — ability controlled by CanCan (usually not allowed).

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

**Success (200)**
```json
{ "id": 42, "name": "Test User", "username": "testuser", "role": "user", "active": true, "created_at":"...", "updated_at":"..." }
```

#### PUT /users/:id
Update user details. Only admin can set `active: true`.

- Allowed fields: `name`, `active` (admin only).
- Request body: `{ "user": { "name": "New name", "active": false } }`

**Success (200)**
```json
{ "message": "User updated", "data": { "id": 42, "name": "New name", "active": false, "created_at": "...", "updated_at":"..." } }
```

#### PUT /users/:id/auth_token
Rotate/re-generate a user's token. **Admin-only**.

**Success (200)**
```json
{ "auth_token": "<new-token>" }
```

#### PUT /users/:id/activate
Activate a user (set `active` to true). **Admin-only**.

**Success (200)**
```json
{ "message": "User activated successfully" }
```

---

## Senders API

### Summary
Senders represent services that send COAR Notify notifications into this inbox. Unique constraint: **username + origin_uri**.

- `origin_uri` (required): the inbox URI of the sending service.
- `target_uris` (optional): known target service URIs. Will be auto-populated as notifications arrive.
- `active` boolean: only admin can set `true`; both admin/user can set `false`.

### Endpoints

#### GET /senders
List senders. Admin sees all; non-admin sees only their own.

**Success (200)**
```json
[
  {
    "id": 1,
    "username": "testuser",
    "origin_uri": "https://origin.example/coar_notify/",
    "target_uris": ["https://consumer.example/inbox/"],
    "active": false,
    "created_at": "..."
  }
]
```

#### POST /senders
Create a sender. All fields go inside the `sender` object.

**Request body**
```json
{
  "sender": {
    "origin_uri": "https://origin.example/coar_notify/",
    "target_uris": ["https://consumer.example/inbox/"],
    "active": false
  }
}
```

Admin creating for another user — pass `username` at the top level:
```json
{
  "username": "testuser",
  "sender": {
    "origin_uri": "https://origin.example/coar_notify/",
    "target_uris": ["https://consumer.example/inbox/"],
    "active": true
  }
}
```

**Rules**
- `origin_uri` is required.
- `target_uris` is optional (defaults to `[]`). The system will append new targets automatically as notifications arrive.
- If `current_user` is admin and `username` is provided at top level, the engine checks that username exists and is active; otherwise returns `422`.
- If non-admin sets `active: true`, it will be forced `false`.
- Duplicate `(username, origin_uri)` → `409 Conflict`.

**Success (201)**
```json
{ "id": 10, "username": "testuser", "origin_uri": "https://origin.example/coar_notify/", "target_uris": [], "active": false }
```

**Errors**
- `409 Conflict` — duplicate (username + origin_uri).
- `422 Unprocessable Entity` — missing `origin_uri` or invalid fields.

#### PUT /senders/:id
Update sender. All fields inside the `sender` object.

```json
{
  "sender": {
    "origin_uri": "https://origin.example/new/",
    "target_uris": ["https://targetA/", "https://targetB/"],
    "active": false
  }
}
```

- `username` cannot be changed.
- `target_uris` are replaced exactly with the provided array.

**Success (200)**
```json
{ "id": 10, "username": "testuser", "origin_uri": "https://origin.example/new/", "target_uris": ["https://targetA/"], "active": false }
```

#### PUT /senders/:id/activate
Admin-only — set `active: true`.

**Success (200)**
```json
{ "id": 10, "username": "testuser", "origin_uri": "...", "active": true }
```

---

## Consumers API

### Summary
Consumers represent services that pull notifications from this inbox. Unique constraint: **username + target_uri**.

- `target_uri` (required): the inbox URI of the consuming service.
- `origin_uris` (optional): known sender URIs. Will be auto-populated as notifications arrive.
- `active` boolean: only admin can set `true`; both admin/user can set `false`.

### Endpoints

#### GET /consumers
List consumers. Admin sees all; non-admin sees only their own.

**Success (200)**
```json
[
  {
    "id": 5,
    "username": "testuser",
    "target_uri": "https://consumer.example/coar_notify/",
    "origin_uris": ["https://origin.example/coar_notify/"],
    "active": false
  }
]
```

#### POST /consumers
Create a consumer. All fields go inside the `consumer` object.

**Request body**
```json
{
  "consumer": {
    "target_uri": "https://consumer.example/coar_notify/",
    "origin_uris": ["https://origin.example/coar_notify/"],
    "active": false
  }
}
```

Admin creating for another user:
```json
{
  "username": "testuser",
  "consumer": {
    "target_uri": "https://consumer.example/coar_notify/",
    "active": true
  }
}
```

**Rules**
- `target_uri` is required.
- `origin_uris` is optional (defaults to `[]`). Auto-populated as notifications arrive.
- Duplicate `(username, target_uri)` → `409 Conflict`.
- If non-admin sets `active: true`, it will be forced `false`.

**Success (201)**
```json
{ "id": 5, "username": "testuser", "target_uri": "https://consumer.example/coar_notify/", "origin_uris": [], "active": false }
```

#### PUT /consumers/:id
Update consumer. All fields inside `consumer` object.

- `username` cannot be changed.
- `origin_uris` are replaced exactly with the provided array.

**Success (200)**
```json
{ "id": 5, "username": "testuser", "target_uri": "https://consumer.example/coar_notify/", "origin_uris": ["https://origin.example/coar_notify/"], "active": false }
```

#### PUT /consumers/:id/activate
Admin-only — set `active: true`.

---

## Notifications API

### Summary
Incoming notifications are validated, stored as immutable records, and queryable by user, sender, or consumer.

### Endpoints

#### POST /notifications
Send a notification into the inbox.

The sender is identified by the `origin` field. The engine checks that the authenticated user has a registered sender with a matching `origin_uri`. **No check is performed against target URIs.**

Both `id` and `inbox` are accepted on `origin` and `target` — `id` takes precedence if both are present.

**Simplified format**
```json
{
  "type": "Offer",
  "origin": {
    "inbox": "https://origin.example/coar_notify/"
  },
  "target": {
    "inbox": "https://consumer.example/coar_notify/"
  },
  "object": {
    "id": "https://repository.example/preprint/123",
    "type": "Dataset"
  }
}
```

**Full COAR Notify format**
```json
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://coar-notify.net"
  ],
  "id": "urn:uuid:0370c0fb-bb78-4a9b-87f5-bed307a509dd",
  "type": ["Offer", "coar-notify:ReviewAction"],
  "actor": {
    "id": "https://orcid.org/0000-0002-1825-0097",
    "name": "Josiah Carberry",
    "type": "Person"
  },
  "object": {
    "id": "https://research-organisation.org/repository/preprint/201203/421/",
    "ietf:cite-as": "https://doi.org/10.5555/12345680",
    "type": ["Page", "sorg:AboutPage"]
  },
  "origin": {
    "id": "https://research-organisation.org/repository",
    "inbox": "https://research-organisation.org/inbox/",
    "type": "Service"
  },
  "target": {
    "id": "https://review-service.com/system",
    "inbox": "https://review-service.com/inbox/",
    "type": "Service"
  }
}
```

**Auto-population**
After a notification is accepted, the engine automatically:
- Appends the `target_uri` to the sender's `target_uris` (if not already present).
- Appends the `origin_uri` to the matching consumer's `origin_uris` (if a consumer with that `target_uri` exists and the origin is not already listed).

**Success (201)**
```json
{
  "id": 1,
  "username": "testuser",
  "origin_uri": "https://origin.example/coar_notify/",
  "target_uri": "https://consumer.example/coar_notify/",
  "notification_type": "Offer",
  "created_at": "2025-12-15T10:30:00Z"
}
```

**Errors**
- `401 Unauthorized` — missing or invalid token.
- `403 Forbidden` — origin URI not registered for this user.
- `422 Unprocessable Entity` — missing required fields or invalid URI.

#### GET /notifications
List notifications. Admin sees all; non-admin sees only their own.

#### GET /notifications/:type/:uri
Filter notifications by sender origin or consumer target.

- `type` must be `sender` or `consumer`.
- `uri` is the origin URI (sender) or target URI (consumer).

Example: `GET /notifications/sender/https://origin.example/coar_notify/`

---

## Origins & Targets (background indexing)

When Senders or Consumers are created/updated, the engine enqueues `CoarNotifyInbox::UpdateOriginsTargetsJob` (ActiveJob) to maintain two index tables:
- `coar_notify_inbox_origins` — `{ id, uri, senders: [ids], consumers: [ids] }`
- `coar_notify_inbox_targets` — `{ id, uri, senders: [ids], consumers: [ids] }`

This is **asynchronous** and may appear in the DB a short time after the API response completes.

---

## Error codes

| Code | Meaning |
|------|---------|
| `200 OK` | Successful read/update |
| `201 Created` | Resource created |
| `401 Unauthorized` | Missing or invalid auth token |
| `403 Forbidden` | Insufficient privileges |
| `409 Conflict` | Duplicate unique combination |
| `422 Unprocessable Entity` | Validation errors / missing fields |
| `500 Internal Server Error` | Unexpected server errors |

---

## Example flows

### 1. Create user (admin)
```bash
curl -X POST "{{BASE_URL}}/users" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "user": { "name": "Test User", "username": "testuser", "role": "user", "active": true } }'
```

### 2. Create sender
```bash
curl -X POST "{{BASE_URL}}/senders" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "sender": {
      "origin_uri": "https://origin.local/coar_notify/",
      "active": false
    }
  }'
```

### 3. Create consumer
```bash
curl -X POST "{{BASE_URL}}/consumers" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "consumer": {
      "target_uri": "https://consumer.local/coar_notify/",
      "active": false
    }
  }'
```

### 4. Send a notification
```bash
curl -X POST "{{BASE_URL}}/notifications" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "Offer",
    "origin": { "inbox": "https://origin.local/coar_notify/" },
    "target": { "inbox": "https://consumer.local/coar_notify/" },
    "object": { "id": "https://repository.example/objects/123", "type": "Dataset" }
  }'
```
