# Resumable Uploads: Example implementations

This repository contains server and client implementations of the [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/). Its latest iteration can be found at the [httpwg/http-extensions repository](https://github.com/httpwg/http-extensions/blob/main/draft-ietf-httpbis-resumable-upload.md).

The implementations are based on the draft [-01](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/01/). We will update them to match [-02](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/02/) soon.

## Clients

- `clients/ios`: iOS application built using Swift to demonstrate the new resumability support in `URLSessions` in iOS 17+.
- `clients/go`: CLI interface for resumable uploads built using Go.
- `clients/tus-js`: JavaScript-based upload client for browsers.

## Servers

- `servers/swift-nio`: Swift NIO server with support for transparent, resumable uploads.
- `servers/tusd`: Feature-rich upload server written in Go.
- `servers/go`: A simple Go server example.
- [tusdotnet](https://github.com/tusdotnet/tusdotnet/tree/POC/tus2): Feature-rich upload server using the .NET ecosystem.

## Interoperability

The goal is to have interoperable implementations for testing purposes. Below shows a table of the interopability between various client and server implementations.

| |`clients/ios` | `clients/go` | `client/tus-js` |
|--|--|--|--|
| `servers/swift-nio` | ✅ | ✅ | ❌[^3] |
| `servers/tusd` | ✅ | ✅ | ✅ |
| `servers/go` | ?[^2] | ✅ | ✅ |
| tusdotnet | ✅ | ✅ | ✅ |

[^2]: Interoperability has not been tested yet.
[^3]: [Cross-Origin Resource Sharing](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) is not supported by server.

## Network simulation

When running a client and server locally, the data transfer can be too fast to usefully test the pause/resume capabilities of resumable uploads. Throttling the network speed is a handy way to simulate more realistic scenarios. Browsers natively provide a setting for this in their developer tools (e.g. [Firefox](https://firefox-source-docs.mozilla.org/devtools-user/network_monitor/throttling/index.html) and [Chrome](https://developer.chrome.com/docs/devtools/settings/throttling/). When working outside of browsers, a proxy like [toxiproxy](https://github.com/Shopify/toxiproxy) can be placed in front of the upload server and control the transfer speed. It is also capable of simulating other kinds of network interruptions.
