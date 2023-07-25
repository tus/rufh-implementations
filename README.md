# Resumable Uploads: Example implementations

This repository contains server and client implementations of the [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/). Its latest iteration can be found at the [httpwg/http-extensions repository](https://github.com/httpwg/http-extensions/blob/main/draft-ietf-httpbis-resumable-upload.md).

The implementations are based on the draft [-01](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/01/).

## Clients

- `clients/ios`: iOS application built using Swift to demonstrate the new resumability support in `URLSessions` in iOS 17+
- `clients/go`: CLI interface for resumable uploads built using Go.

## Servers

- `servers/swift-nio`: Swift NIO server with support for transparent, resumable uploads
- `servers/tusd`: Feature-rich upload server written in Go.

## Interoperability

| |`clients/ios` | `clients/go` |
|--|--|--|
| `servers/swift-nio` | ❌[^1] | ✅ |
| `servers/tusd` | ✅ | ✅ |

[^1]: Swift NIO implements is still buggy: https://lists.w3.org/Archives/Public/ietf-http-wg/2023JulSep/0025.html 
