# COAR Notify Inbox — Postman Testing Guide

This guide explains how to import, configure, and run the provided Postman collection to test all APIs of the COAR Notify Inbox Rails Engine.

It assumes only basic familiarity with Postman and terminal commands.
___

### 1. Download the Postman Collection
- You can downalod this using the this [link](/docs/coar_notify_inbox_postman_collection.json)

### 2. Import the Collection into Postman
1. Open Postman
2. Click Import (top-left)
3. Choose File
4. Select `coar_notify_inbox_postman_collection.json`
5. A new collection named `COAR Notify Inbox` will appear in the sidebar.

Inside this collection, you will see:
- All requests for Senders, Consumers, Notifications
- Collection-level variables (e.g., auth_token)

### 3. Get Your Authentication Token
You need to use the token that was generated when you created the first admin user. If you have another admin token available, you can use that as well.

### 4. Set the Postman Variables
1. In Postman, click the three dots (…) next to the collection
2. Select Edit
3. Open the Variables tab
    1. Paste your token into auth_token (CURRENT VALUE only)
4. Click Save.
 
_You only need to paste the token once — every request will use it._

### 5. Run the Test Suite
You can run:

1. Option A — Run Entire Collection (Recommended)
    1. Click over the collection name
    2. Click the Run (▶️) icon
    3. Select Run Collection
    Postman will:
        - Execute all API requests in order
        - Validate responses
        - Save IDs (sender, consumer, notification) for chaining
        - Ensure authentication works
        - Check for correct status codes (201, 200, 409, etc.)
2. Option B — Run Individual Requests
    1. Expand the main folder and open any feature folder and click any request:
    2. Click Send.
    All requests automatically apply:
        ```
        Authorization: Bearer {{auth_token}}
        Base URL: {{baseUrl}}
        ```
        No manual header changes needed.
