# HTTP requests

An in-editor client for `.http` files. The important property: **this is the same format Visual Studio 2022's built-in HTTP editor and VS Code's REST Client use**, so request collections live in the repo, diff properly, and stay usable by colleagues who never leave Visual Studio.

## Keys

Available in `.http` files.

| Key | Does |
|---|---|
| `,ks` | Send the request under the cursor |
| `,ka` | Send every request in the file |
| `,kt` | Toggle between response body and headers |
| `,kn` / `,kp` | Jump to the next / previous request |
| `,kc` | Copy the request as a curl command |
| `,ke` | Select the environment |

## The file format

Requests are separated by `###`.

```http
### Get all orders
GET https://api.example.com/orders
Accept: application/json

### Create an order
POST https://api.example.com/orders
Content-Type: application/json

{
  "customerId": 42,
  "items": ["widget"]
}
```

Put the cursor anywhere in a request and press `,ks`. The response opens in a split with body, headers and timing.

## Variables

```http
@baseUrl = https://api.example.com
@version = v2

### Uses both
GET {{baseUrl}}/{{version}}/orders
```

## Environments

Put an `http-client.env.json` next to the file:

```json
{
  "dev": {
    "baseUrl": "https://dev.api.example.com",
    "apiKey": "dev-key"
  },
  "prod": {
    "baseUrl": "https://api.example.com",
    "apiKey": "prod-key"
  }
}
```

`,ke` switches between them, and `{{baseUrl}}` resolves to whichever is selected. This is the same file Visual Studio reads.

Keep secrets out of the committed env file. `http-client.private.env.json` is the convention for the values that should stay local, and belongs in `.gitignore`.

## Chaining requests

Capture something from one response and use it in the next, which is what makes authenticated flows workable:

```http
### Log in
# @name login
POST {{baseUrl}}/auth
Content-Type: application/json

{ "user": "me", "pass": "secret" }

### Use the token from the response above
GET {{baseUrl}}/orders
Authorization: Bearer {{login.response.body.$.token}}
```

## Dynamic values

| Placeholder | Gives |
|---|---|
| `{{$uuid}}` | A fresh GUID |
| `{{$timestamp}}` | Current Unix timestamp |
| `{{$randomInt}}` | A random integer |

Useful for idempotency keys and correlation IDs.

## What this does not replace

Compared with Postman, you do not get a GUI collection runner, mock servers, monitors, team workspaces or OAuth wizards. If a flow needs those, use Postman.

What you get instead: requests that are plain text in the repo, reviewable in a pull request, versioned with the code they exercise, and openable by anyone on the team in whichever editor they prefer.

## Colemak note

Typing into a request file is ordinary Insert mode, so translation applies normally. Only Terminal mode is untranslated, and this does not use one.
