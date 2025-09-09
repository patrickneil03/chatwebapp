# Realtime Chat Frontend (Vanilla JS)

A clean, dependency-free frontend for an AWS API Gateway **WebSocket** chat backend.

## Features
- Join any **room** with a display name
- Connect to your **WebSocket URL** (API Gateway stage)
- Optional **JWT** support — app appends `?token=...` to the connect URL
- Optional **REST API** base URL to **fetch message history**
- Online users panel, typing indicator, reconnect with exponential backoff
- Zero frameworks: HTML + CSS + JS

## Expected Backend Message Shapes
Your WebSocket backend (Lambda) should send JSON like:

```jsonc
{ "type":"welcome", "ts": 1710000000000 }

{ "type":"joined", "userId":"abc", "name":"Patrick", "room":"general",
  "users":[{"id":"abc","name":"Patrick"},{"id":"xyz","name":"Neil"}], "ts":1710000000000 }

{ "type":"left", "userId":"abc", "name":"Patrick", "ts":1710000000000 }

{ "type":"message", "from":"Patrick", "text":"Hello", "ts":1710000000000 }

{ "type":"history", "items":[{"from":"Neil","text":"Earlier msg","ts":1710000000000}] }

{ "type":"typing", "from":"Neil", "room":"general", "on":true }
```

And accept client-sent actions like:

```jsonc
{ "action":"hello", "name":"Patrick" }
{ "action":"join", "room":"general" }
{ "action":"sendMessage", "room":"general", "text":"Hi!" }
{ "action":"typing", "room":"general", "on":true }
```

> You can adapt your Lambda routes to translate actual DynamoDB/Kinesis/EventBridge events into these shapes.

## Deploy
- Serve the three files over any static host (S3 + CloudFront recommended).
- Optionally set defaults in `config.js` (WebSocket URL, REST base URL, default room).

## Cognito (Optional)
If your `$connect` integration expects JWTs, paste an **ID or Access Token** into the join screen or modify your backend to read `token` from the query string.

## Run locally
Just open `index.html` in a browser, or host via a simple HTTP server.
