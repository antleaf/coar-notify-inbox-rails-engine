# COAR Notify Inbox API Documentation

## Overview

The COAR Notify Inbox API is a Rails engine providing a complete COAR Notify Inbox implementation following [v1.0.1 of the COAR Notify specification](https://coar-notify.net/specification/1.0.1/). This API manages users, senders, and consumers for notification management.

**Base URL:** `{base_url}/coar_notify_inbox`

Replace `{base_url}` with your actual server address (e.g., `{base_url}`, `https://api.example.com`)

**API Version:** 1.0.0

---

## Table of Contents

1. [Authentication](#authentication)
2. [Users API](#users-api)
3. [Senders API](#senders-api)
4. [Consumers API](#consumers-api)
5. [Response Format](#response-format)
6. [Error Handling](#error-handling)
7. [Examples](#examples)

---

## Authentication

### Overview

The API uses token-based authentication via Authorization headers. An `auth_token` is automatically generated when a user is created.

### Using Auth Token

Include the token in the Authorization header for authenticated endpoints:

```
Authorization: Bearer {auth_token}
```

### Getting a Token

Create a new user to obtain an `auth_token`:

```bash
curl -X POST {base_url}/coar_notify_inbox/users \
  -H "Content-Type: application/json" \
  -d '{"user": {"name": "Your Name"}}'
```

The response includes the `auth_token`:

```json
{
  "message": "User created",
  "auth_token": "1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p"
}
```

---

## Users API

The Users API manages user accounts and their activation states.

### Endpoints

#### 1. Create User

Creates a new user with automatic role assignment (`user`) and active status (`true`).

**Request:**

```
POST /users
Content-Type: application/json
```

**Parameters:**

| Parameter | Type   | Required | Description         |
| --------- | ------ | -------- | ------------------- |
| name      | string | Yes      | User's display name |

**Request Body:**

```json
{
  "user": {
    "name": "John Doe"
  }
}
```

**Response:**

- **Status Code:** `201 Created`
- **Body:**

```json
{
  "message": "User created",
  "auth_token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
  "id": 1,
  "name": "John Doe",
  "role": "user",
  "active": true,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**Error Response:**

- **Status Code:** `422 Unprocessable Entity`
- **Body (Empty name):**

```json
{
  "errors": ["Name can't be blank"]
}
```

**Example:**

```bash
curl -X POST {base_url}/coar_notify_inbox/users \
  -H "Content-Type: application/json" \
  # COAR Notify Inbox API Documentation

  ## Overview

  This document describes the public COAR Notify Inbox API: users, senders, consumers, and notifications. It includes authentication rules, payloads, and role-based behavior (admin vs user).

  **Base URL:** `{base_url}/coar_notify_inbox`

  **API Version:** 1.0.0

  ---

  ## Quick Reference
  - Authentication: `Authorization: Bearer {auth_token}` header required for protected endpoints.
  - Admins can manage other users, enable/disable resources, and view all notifications.
  - Regular users can manage their own senders/consumers and view resources they own.

  ---

  ## Table Of Contents

  1. [Authentication](#authentication)
  2. [Users API](#users-api)
  3. [Senders API](#senders-api)
  4. [Consumers API](#consumers-api)
  5. [Notifications API](#notifications-api)
  6. [Response & Error Formats](#response--error-formats)
  7. [Examples](#examples)

  ---

  ## Authentication

  All protected endpoints require an `Authorization` header with a Bearer token:

```

Authorization: Bearer {auth_token}

````

The `auth_token` is automatically generated when a user is created. Admins and active users have tokens.

Where an endpoint requires an admin token, this is explicitly documented.

---

## Users API

Admin users manage users. Regular users can modify their own profile and regenerate their token.

Base path: `/users`

### Create first admin user (command line)

To bootstrap the system, create the first admin user from the Rails console. Example:

```ruby
# in rails console
CoarNotifyInbox::User.create!(name: 'Admin User', role: :admin, active: true)
# The auth_token will be generated automatically on create
````

### Endpoints

#### List users

- Method: `GET /users`
- Auth: admin `auth_token` required
- Returns: list of users (all users for admin)

### Create a user

- Method: `POST /users`
- Auth: **admin `auth_token` required** (only admin can create users)
- Payload fields accepted:
  - `username` (optional external identifier)
  - `name` (required)
  - `active` (optional, default: `false` unless admin sets `true`)
  - `type` (optional, e.g., `Person`)

Example request body:

```json
{
  "user": {
    "username": "mailto:josiah.carberry@example.com",
    "name": "Josiah Carberry",
    "type": "Person",
    "active": false
  }
}
```

On success the server returns `201 Created` and an `auth_token` is generated:

```json
{
  "message": "User created",
  "auth_token": "<auto-generated-token>",
  "id": "mailto:josiah.carberry@example.com",
  "name": "Josiah Carberry",
  "active": false,
  "type": "Person"
}
```

Notes:

- If `active` is omitted when a regular user creates (or admin creates but does not set active), it defaults to `false`.
- Only admin users can set `active: true` when creating or updating other users.

#### Modify user

- Method: `PUT /users/{id}`
- Auth: admin `auth_token` or the user's own `auth_token`
- Body fields: `name`, `active` (only admin may set `active: true`)

Example:

```json
{
  "user": { "name": "Josiah C.", "active": true }
}
```

#### Regenerate auth token

- Method: `PUT /users/{id}/auth_token`
- Auth: **admin `auth_token` required** (only admin can regenerate tokens)
- Purpose: rotate/regenerate the user's token
- Response: returns new `auth_token`

## Notification Types API

Notification types are used to categorize notifications. Only admins can manage notification types.

Base path: `/notification_types`

### Endpoints

#### List notification types

- Method: `GET /notification_types`
- Auth: admin `auth_token` required

#### Create notification type

- Method: `POST /notification_types`
- Auth: admin `auth_token` required
- Payload:
  - `notification_type` (string, required)

#### Update notification type

- Method: `PUT /notification_types/{id}`
- Auth: admin `auth_token` required
- Payload:
  - `notification_type` (string, required)

#### Delete notification type

- Method: `DELETE /notification_types/{id}`
- Auth: admin `auth_token` required

---

## Setup Instructions

Before using the API, create one admin user via Rails console:

```ruby
CoarNotifyInbox::User.create!(name: 'Admin User', role: :admin, active: true)
# Copy the generated auth_token for use in API requests and Postman tests.
```

Use this admin token for all endpoints requiring admin privileges.

---

#### Get user

- Method: `GET /users/{id}`
- Auth: admin `auth_token` or the user's own `auth_token`

#### Delete user (deferred)

- Method: `DELETE /users/{id}` (to be implemented later)
- Rules: only admin; user must be inactive and not referenced by other resources

---

## Senders API

Senders represent the origin side of notification flows. Both admins and users can register senders; admins may create senders for other users.

Base path: `/senders`

### Create sender

- Method: `POST /senders`
- Auth: `Authorization: Bearer {auth_token}` required
  - If token belongs to admin, the payload may include `username` to create sender for another user.
  - If token belongs to normal user, sender is created for `current_user`.
- Payload:
  - `user_name` or `user_id` (optional, admin only)
  - `origin_uri` (required)
  - `target_uris` (array) (optional)
  - `active` (boolean) — only admin may set `true`; otherwise defaults to `false`

Rules:

- The combination of `user_id` and `origin_uri` must be unique.
- If the pair exists, the API allows updating target URIs but will not create a duplicate sender.
- The user for whom the sender is created must be active.

Example body:

```json
{
  "sender": {
    "origin_uri": "https://origin.example/1",
    "target_uris": ["https://target.example/1", "https://target.example/2"],
    "active": false
  }
}
```

### List senders

- Method: `GET /senders`
- Auth: `Authorization: Bearer {auth_token}` required
- Behavior:
  - Admin token: returns all senders
  - User token: returns only senders for that user

### Get sender

- Method: `GET /senders/{id}`
- Auth: admin or owner user

### Update sender

- Method: `PUT /senders/{id}`
- Auth: admin or owner user
- Can update `target_uris`. Only admin may set `active: true`. Both admin and user can set `active: false`.

### Delete sender (deferred)

- Method: `DELETE /senders/{id}` (to be implemented later)

---

## Consumers API

Consumers represent endpoints that receive notifications (the consumer's target URI). Admins and users can register consumers; admins may register on behalf of others.

Base path: `/consumers`

### Create consumer

- Method: `POST /consumers`
- Auth: `Authorization: Bearer {auth_token}` required
- Payload:
  - `target_uri` (required) — a single target URI per consumer
  - `origin_uris` (array) — origins the consumer will accept
  - `user_name` or `user_id` (optional, admin only)
  - `active` (boolean) — only admin may set `true`; otherwise defaults to `false`

Rules:

- The combination of `user_id` and `target_uri` must be unique.
- If a consumer exists for the pair, the API will allow updating the consumer's origins but not creating a duplicate.

### List consumers

- Method: `GET /consumers`
- Auth: `Authorization: Bearer {auth_token}` required
- Admins see all; users see only their own

### Get consumer

- Method: `GET /consumers/{id}`
- Auth: admin or owner user

### Update consumer

- Method: `PUT /consumers/{id}`
- Auth: admin or owner user
- Can update `origin_uris`. Only admin may set `active: true`.

---

## Notifications API

Notifications are created by senders and delivered to consumers. The API validates that the origin belongs to the sender (the authenticated user) and that the target matches a consumer.

Base path: `/notifications`

### Create notification

- Method: `POST /notifications`
- Auth: `Authorization: Bearer {auth_token}` — token must belong to a user who is a sender for the provided `origin_uri`.
- Payload fields:
  - `origin_uri` (string) — required
  - `target_uri` (string) — required
  - `type` (string) — notification type identifier (must exist in `notification_types`)
  - `payload` (JSON object) — actual notification content

Validation steps (server):

1. Authenticate `auth_token` and ensure user is active.
2. Verify `origin_uri` exists and is configured for the authenticated user as a sender.
3. Verify `target_uri` exists or create it as needed.
4. Verify `type` exists in `notification_types`.
5. If a matching notification already exists for (user, type, origin, target) return `303 See Other`. Otherwise create and return `201 Created`.

Return codes:

- `201 Created` — created successfully
- `303 See Other` — resource already exists (idempotency)
- `400` / `422` — validation or payload error

### List notifications

- Method: `GET /notifications`
- Auth: `Authorization: Bearer {auth_token}` required
- Admins: return all notifications. Users: return notifications where `user_id` equals the authenticated user.

### Search / Filter notifications

- Method: `GET /notifications/search`
- Query params: `type` (sender|consumer) and/or `uri` (origin or target URI)
- Behavior:
  - Both `type` and `uri` provided: filter accordingly (type=sender matches origin_uri; type=consumer matches target_uri)
  - Only `uri` provided: search notifications where either origin or target matches the uri
  - Only `type` provided (no uri): no-op (returns empty) — the API requires a uri to filter on a type

Examples:

```
GET /notifications/search?type=sender&uri=https://origin.example/1
GET /notifications/search?type=consumer&uri=https://target.example/1
GET /notifications/search?uri=https://example.com/some/uri
```

---

## Response & Error Formats

Successful responses are JSON. Errors use the following conventions:

- `422 Unprocessable Entity` — validation errors, response body:

```json
{ "errors": ["field can't be blank"] }
```

- `401 Unauthorized` — missing or invalid auth token
- `403 Forbidden` — authenticated but not permitted
- `404 Not Found` — resource not found
- `303 See Other` — resource already exists (idempotent create)

---

## Examples

Create notification (sender must be authenticated and own the origin):

```bash
curl -X POST {base_url}/coar_notify_inbox/notifications \
  -H "Authorization: Bearer {auth_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "origin_uri": "https://origin.example/1",
    "target_uri": "https://target.example/1",
    "type": "review",
    "payload": { "message": "Document updated" }
  }'
```

List notifications (admin sees all, user sees own):

```bash
curl -X GET {base_url}/coar_notify_inbox/notifications \
  -H "Authorization: Bearer {auth_token}"
```

Search notifications by origin:

```bash
curl -X GET "{base_url}/coar_notify_inbox/notifications/search?type=sender&uri=https://origin.example/1" \
  -H "Authorization: Bearer {auth_token}"
```

---

## Appendix & Notes

- The API is intentionally minimal in the payloads it accepts from clients; the server sets sensible defaults (e.g., `auth_token`) and enforces relationships (user active, sender origin ownership, unique constraints).
- If you need different payload shapes (e.g., nested `consumer[target_uri]` or simple arrays for `origin_uris/target_uris`) we can adapt the controllers and update the documentation accordingly.

---

**Last Updated:** December 01, 2025  
 **API Version:** 1.0.0
**Path Parameters:**
