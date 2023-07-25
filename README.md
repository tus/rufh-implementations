# Resumable Uploads: Example implementations

This repository contains server and client implementations of the [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/). Its latest iteration can be found at the [httpwg/http-extensions repository](https://github.com/httpwg/http-extensions/blob/main/draft-ietf-httpbis-resumable-upload.md).

The implementations are based on the draft [-01](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/01/).

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
| `servers/swift-nio` | ❌[^1] | ✅ | ❌[^3] |
| `servers/tusd` | ✅ | ✅ | ✅ |
| `servers/go` | ?[^2] | ✅ | ✅ |
| tusdotnet | ✅ | ?[^2] | ?[^2] |

[^1]: Swift NIO implementation is still buggy: https://lists.w3.org/Archives/Public/ietf-http-wg/2023JulSep/0025.html 
[^2]: Interoperability has not been tested yet.
[^3]: [Cross-Origin Resource Sharing](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) is not supported by server.
