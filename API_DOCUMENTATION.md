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

| Parameter | Type   | Required | Description          |
|-----------|--------|----------|----------------------|
| name      | string | Yes      | User's display name  |

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
  -d '{"user": {"name": "John Doe"}}'
```

---

#### 2. Get All Users

Retrieves a list of all users in the system.

**Request:**
```
GET /users
Authorization: Bearer {auth_token}
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "role": "user",
    "active": true,
    "created_at": "2025-11-26T10:30:00.000Z",
    "updated_at": "2025-11-26T10:30:00.000Z"
  },
  {
    "id": 2,
    "name": "Jane Smith",
    "role": "user",
    "active": false,
    "created_at": "2025-11-26T10:35:00.000Z",
    "updated_at": "2025-11-26T10:45:00.000Z"
  }
]
```

**Example:**
```bash
curl -X GET {base_url}/coar_notify_inbox/users \
  -H "Authorization: Bearer a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
```

---

#### 3. Activate User

Activates a user account (sets `active` to `true`).

**Request:**
```
PATCH /users/{id}/activate
Authorization: Bearer {auth_token}
Content-Type: application/json
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | User ID     |

**Request Body:**
```json
{}
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
{
  "message": "User activated successfully"
}
```

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`
- **Body:**
```json
{
  "error": "Not Found"
}
```

**Example:**
```bash
curl -X PATCH {base_url}/coar_notify_inbox/users/1/activate \
  -H "Authorization: Bearer a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

#### 4. Deactivate User

Deactivates a user account (sets `active` to `false`).

**Request:**
```
PATCH /users/{id}/deactivate
Authorization: Bearer {auth_token}
Content-Type: application/json
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | User ID     |

**Request Body:**
```json
{}
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
{
  "message": "User deactivated successfully"
}
```

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`

**Example:**
```bash
curl -X PATCH {base_url}/coar_notify_inbox/users/1/deactivate \
  -H "Authorization: Bearer a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## Senders API

The Senders API manages sender entities that can send notifications. A sender belongs to a user and can be associated with multiple targets.

### Endpoints

#### 1. Create Sender

Creates a new sender associated with a user and optionally an origin.

**Request:**
```
POST /senders
Content-Type: application/json
```

**Parameters:**

| Parameter | Type    | Required | Description                              |
|-----------|---------|----------|------------------------------------------|
| user_id   | integer | Yes      | ID of the user who owns this sender      |
| origin_id | integer | No       | ID of the origin (COAR notify origin)    |

**Request Body:**
```json
{
  "sender": {
    "user_id": 1,
    "origin_id": null
  }
}
```

**Response:**
- **Status Code:** `201 Created`
- **Body:**
```json
{
  "id": 1,
  "user_id": 1,
  "origin_id": null,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**Error Response (Invalid User):**
- **Status Code:** `422 Unprocessable Entity`
- **Body:**
```json
{
  "errors": ["User must exist"]
}
```

**Example:**
```bash
curl -X POST {base_url}/coar_notify_inbox/senders \
  -H "Content-Type: application/json" \
  -d '{"sender": {"user_id": 1}}'
```

---

#### 2. Get All Senders

Retrieves a list of all senders in the system.

**Request:**
```
GET /senders
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "origin_id": null,
    "created_at": "2025-11-26T10:30:00.000Z",
    "updated_at": "2025-11-26T10:30:00.000Z"
  },
  {
    "id": 2,
    "user_id": 2,
    "origin_id": 1,
    "created_at": "2025-11-26T10:35:00.000Z",
    "updated_at": "2025-11-26T10:35:00.000Z"
  }
]
```

**Example:**
```bash
curl -X GET {base_url}/coar_notify_inbox/senders
```

---

#### 3. Get Sender by ID

Retrieves a specific sender and includes its associated targets.

**Request:**
```
GET /senders/{id}
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | Sender ID   |

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
{
  "id": 1,
  "user_id": 1,
  "origin_id": null,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z",
  "targets": [
    {
      "id": 1,
      "uri": "https://example.com/target/1",
      "created_at": "2025-11-26T10:30:00.000Z",
      "updated_at": "2025-11-26T10:30:00.000Z"
    }
  ]
}
```

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`

**Example:**
```bash
curl -X GET {base_url}/coar_notify_inbox/senders/1
```

---

#### 4. Update Sender

Updates a sender's properties and optionally associates targets.

**Request:**
```
PUT /senders/{id}
Content-Type: application/json
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | Sender ID   |

**Parameters:**

| Parameter | Type    | Required | Description                         |
|-----------|---------|----------|-------------------------------------|
| user_id   | integer | No       | ID of the user who owns this sender |
| origin_id | integer | No       | ID of the origin                    |
| targets   | array   | No       | Array of target objects with IDs    |

**Request Body:**
```json
{
  "sender": {
    "user_id": 1,
    "origin_id": 1
  },
  "targets": [
    { "id": 1 },
    { "id": 2 }
  ]
}
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
{
  "id": 1,
  "user_id": 1,
  "origin_id": 1,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:40:00.000Z"
}
```

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`

**Example:**
```bash
curl -X PUT {base_url}/coar_notify_inbox/senders/1 \
  -H "Content-Type: application/json" \
  -d '{"sender": {"user_id": 1, "origin_id": 1}, "targets": [{"id": 1}]}'
```

---

#### 5. Delete Sender

Deletes a sender and all associated sender-target relationships.

**Request:**
```
DELETE /senders/{id}
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | Sender ID   |

**Response:**
- **Status Code:** `204 No Content`
- **Body:** (empty)

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`

**Example:**
```bash
curl -X DELETE {base_url}/coar_notify_inbox/senders/1
```

---

## Consumers API

The Consumers API manages consumer entities that can receive notifications. A consumer belongs to a user and can be associated with multiple targets.

### Endpoints

#### 1. Create Consumer

Creates a new consumer associated with a user.

**Request:**
```
POST /consumers
Content-Type: application/json
```

**Parameters:**

| Parameter | Type    | Required | Description                                |
|-----------|---------|----------|--------------------------------------------|
| user_id   | integer | Yes      | ID of the user who owns this consumer      |

**Request Body:**
```json
{
  "consumer": {
    "user_id": 1
  }
}
```

**Response:**
- **Status Code:** `201 Created`
- **Body:**
```json
{
  "id": 1,
  "user_id": 1,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**Error Response (Invalid User):**
- **Status Code:** `422 Unprocessable Entity`
- **Body:**
```json
{
  "errors": ["User must exist"]
}
```

**Example:**
```bash
curl -X POST {base_url}/coar_notify_inbox/consumers \
  -H "Content-Type: application/json" \
  -d '{"consumer": {"user_id": 1}}'
```

---

#### 2. Get All Consumers

Retrieves a list of all consumers in the system.

**Request:**
```
GET /consumers
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "created_at": "2025-11-26T10:30:00.000Z",
    "updated_at": "2025-11-26T10:30:00.000Z"
  },
  {
    "id": 2,
    "user_id": 2,
    "created_at": "2025-11-26T10:35:00.000Z",
    "updated_at": "2025-11-26T10:35:00.000Z"
  }
]
```

**Example:**
```bash
curl -X GET {base_url}/coar_notify_inbox/consumers
```

---

#### 3. Get Consumer by ID

Retrieves a specific consumer.

**Request:**
```
GET /consumers/{id}
```

**Path Parameters:**

| Parameter | Type    | Required | Description  |
|-----------|---------|----------|--------------|
| id        | integer | Yes      | Consumer ID  |

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
{
  "id": 1,
  "user_id": 1,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`

**Example:**
```bash
curl -X GET {base_url}/coar_notify_inbox/consumers/1
```

---

#### 4. Update Consumer

Updates a consumer's properties.

**Request:**
```
PUT /consumers/{id}
Content-Type: application/json
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | Consumer ID |

**Parameters:**

| Parameter | Type    | Required | Description                              |
|-----------|---------|----------|------------------------------------------|
| user_id   | integer | Yes      | ID of the user who owns this consumer    |

**Request Body:**
```json
{
  "consumer": {
    "user_id": 1
  }
}
```

**Response:**
- **Status Code:** `200 OK`
- **Body:**
```json
{
  "id": 1,
  "user_id": 1,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:40:00.000Z"
}
```

**Error Response (Invalid User):**
- **Status Code:** `422 Unprocessable Entity`
- **Body:**
```json
{
  "errors": ["User must exist"]
}
```

**Example:**
```bash
curl -X PUT {base_url}/coar_notify_inbox/consumers/1 \
  -H "Content-Type: application/json" \
  -d '{"consumer": {"user_id": 1}}'
```

---

#### 5. Delete Consumer

Deletes a consumer and all associated consumer-target relationships.

**Request:**
```
DELETE /consumers/{id}
```

**Path Parameters:**

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| id        | integer | Yes      | Consumer ID |

**Response:**
- **Status Code:** `204 No Content`
- **Body:** (empty)

**Error Response (Not Found):**
- **Status Code:** `404 Not Found`

**Example:**
```bash
curl -X DELETE {base_url}/coar_notify_inbox/consumers/1
```

---

## Response Format

### Success Response

All successful responses follow a consistent JSON format:

```json
{
  "id": 1,
  "name": "Resource Name",
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

### List Response

List endpoints return an array of resources:

```json
[
  { "id": 1, "name": "Resource 1", "created_at": "...", "updated_at": "..." },
  { "id": 2, "name": "Resource 2", "created_at": "...", "updated_at": "..." }
]
```

### Empty Response

Some endpoints return no body with a 204 status code on successful deletion:

```
Status: 204 No Content
Body: (empty)
```

---

## Error Handling

The API uses standard HTTP status codes to indicate the success or failure of requests.

### Status Codes

| Status Code | Meaning                  | Description                                        |
|-------------|--------------------------|-----------------------------------------------------|
| 200         | OK                       | Request successful, data returned                  |
| 201         | Created                  | Resource successfully created                      |
| 204         | No Content               | Request successful, no data returned (e.g., delete)|
| 400         | Bad Request              | Invalid request format or malformed JSON            |
| 404         | Not Found                | Resource does not exist                            |
| 422         | Unprocessable Entity     | Request data fails validation                      |
| 500         | Internal Server Error    | Server error occurred                              |

### Error Response Format

#### Validation Error (422)

```json
{
  "errors": [
    "Name can't be blank",
    "User must exist"
  ]
}
```

#### Not Found Error (404)

```json
{
  "error": "Not Found"
}
```

#### Invalid JSON (400)

```json
{
  "error": "Invalid JSON"
}
```

### Common Errors

| Scenario                      | Status | Error Message                          |
|-------------------------------|--------|----------------------------------------|
| Missing required field        | 422    | `[field] can't be blank`               |
| Invalid foreign key           | 422    | `[Model] must exist`                   |
| Duplicate unique value        | 422    | `[field] has already been taken`       |
| Resource not found            | 404    | (empty or not found message)           |
| Malformed JSON                | 400    | (JSON parse error)                     |
| Invalid request parameters    | 422    | (validation error messages)            |

---

## Examples

### Complete User Workflow

**1. Create a new user:**
```bash
curl -X POST {base_url}/coar_notify_inbox/users \
  -H "Content-Type: application/json" \
  -d '{"user": {"name": "Alice Smith"}}'
```

Response:
```json
{
  "message": "User created",
  "auth_token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
  "id": 1,
  "name": "Alice Smith",
  "role": "user",
  "active": true,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**2. List all users:**
```bash
curl -X GET {base_url}/coar_notify_inbox/users \
  -H "Authorization: Bearer a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
```

**3. Deactivate the user:**
```bash
curl -X PATCH {base_url}/coar_notify_inbox/users/1/deactivate \
  -H "Authorization: Bearer a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

### Complete Sender Workflow

**1. Create a sender:**
```bash
curl -X POST {base_url}/coar_notify_inbox/senders \
  -H "Content-Type: application/json" \
  -d '{"sender": {"user_id": 1}}'
```

Response:
```json
{
  "id": 5,
  "user_id": 1,
  "origin_id": null,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**2. Get sender details:**
```bash
curl -X GET {base_url}/coar_notify_inbox/senders/5
```

**3. Update sender with targets:**
```bash
curl -X PUT {base_url}/coar_notify_inbox/senders/5 \
  -H "Content-Type: application/json" \
  -d '{
    "sender": {"user_id": 1},
    "targets": [{"id": 1}, {"id": 2}]
  }'
```

**4. Delete sender:**
```bash
curl -X DELETE {base_url}/coar_notify_inbox/senders/5
```

---

### Complete Consumer Workflow

**1. Create a consumer:**
```bash
curl -X POST {base_url}/coar_notify_inbox/consumers \
  -H "Content-Type: application/json" \
  -d '{"consumer": {"user_id": 1}}'
```

Response:
```json
{
  "id": 3,
  "user_id": 1,
  "created_at": "2025-11-26T10:30:00.000Z",
  "updated_at": "2025-11-26T10:30:00.000Z"
}
```

**2. Get all consumers:**
```bash
curl -X GET {base_url}/coar_notify_inbox/consumers
```

**3. Update consumer:**
```bash
curl -X PUT {base_url}/coar_notify_inbox/consumers/3 \
  -H "Content-Type: application/json" \
  -d '{"consumer": {"user_id": 2}}'
```

**4. Delete consumer:**
```bash
curl -X DELETE {base_url}/coar_notify_inbox/consumers/3
```

---

## Rate Limiting

Currently, the API does not implement rate limiting. For production deployments, implement appropriate rate limiting middleware.

## Versioning

The API version is indicated in the documentation. Future versions will be available under different paths if backward compatibility needs to be maintained.

## Support

For issues, questions, or contributions, please refer to the main repository:
[COAR Notify Inbox Rails Engine](https://github.com/antleaf/coar-notify-inbox-rails-engine)

---

**Last Updated:** November 26, 2025  
**API Version:** 1.0.0
