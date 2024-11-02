# Resumable Uploads: Implementations

The HTTP working group is currently discussing a draft for resumable uploads over HTTP: [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/). Its latest iteration can be found at the [httpwg/http-extensions repository](https://github.com/httpwg/http-extensions/blob/main/draft-ietf-httpbis-resumable-upload.md). This repository contains information about known client and server implementations of the draft, including instructions and examples on how to use them.

## Clients

### URLSession (iOS 17+, macOS 14+)

Apple added support for resumable uploads (draft version 01) in `URLSession` on iOS 17+ and macOS 14+. This API can be used from Swift and Object-C. A detailed introduction into resumable downloads and uploads as well as links to the API documentation can be found in [Apple's WWDC23](https://developer.apple.com/videos/play/wwdc2023/10006/). This repository contains a small iOS application demonstrating the use of resumable uploads in [`clients/ios`](/clients/ios/).

### Tus-js-client (Browser, Node.js)

[Tus-js-client](https://github.com/tus/tus-js-client) is a client implementing the [tus resumable upload protocol](https://tus.io) for various JavaScript environment, including browsers, Node.js, React Native etc. In recent versions, it also provides experimental support for the resumable upload draft. A browser-based example can be found in [`clients/tus-js`](/clients/tus-js/).

### Go client example

A simple resumable upload client written in Go can be found in [`clients/go`](/clients/go/). Its purpose is to demonstrate the basic logic of a resumable upload client and serve as inspiration for new client implementations.

## Servers

### SwiftNIO

Apple published an example implementation of a resumable upload server built using [SwiftNIO](https://opensource.apple.com/projects/swiftnio/). It is based on the `NIOResumableUpload` package, which was published from [Apple's WWDC23](https://developer.apple.com/videos/play/wwdc2023/10006/) and provides transparently translates resumable uploads into non-resumable uploads for easy server-side handling. An example can be found in [`servers/swift-nio`](/servers/swift-nio/).

### Tusd (Go)

[Tusd](https://tus.github.io/tusd/) is a server originally developed for the [tus resumable upload protocol](https://tus.io), but recent versions also provide experimental support for the draft of Resumable Upload For HTTP. Its authors intend to support all draft versions and serve as a testing ground for new and existing upload clients. Tusd is a feature-rich upload server written in Go and supports storing data on various cloud providers and notifying applications about upload progress. A quick guide on getting tusd up and running can be found in [`servers/tusd`](/servers/tusd/).

### Tusdotnet (.NET)

[Tusdotnet](https://github.com/tusdotnet/tusdotnet/) is a feature-rich .NET server implementation of the [tus resumable upload protocol](https://tus.io), which also includes experimental support for the draft of Resumable Upload For HTTP. Details on how to use tusdotnet with the draft can be found at https://github.com/tusdotnet/tusdotnet/tree/POC/tus2.

### Go server example

A simple resumable upload server written in Go can be found in [`servers/go`](/servers/go/). Its purpose is to demonstrate the basic logic of a resumable upload server and serve as inspiration for new server implementations.

### Caddy module

[Caddy](https://caddyserver.com/) is an HTTP proxy with support for custom modules. [caddy-rufh](https://github.com/Murderlon/caddy-rufh) is such a module and transparently translated resumable uploads into traditional, non-resumable uploads, so that backends don't have to take care of handling resumable uploads on their own. The proxy will take care of this.

https://github.com/Murderlon/caddy-rufh

## Tools

### Conformity tester

At the IETF 118's hackathon, a conformity tester was developed to verify whether a server correctly implements the draft. This tool should help to validate server-side setups and assist in creating interoperable implementations. Its source code and instructions for use can be found at https://github.com/tus/ietf-hackathon/tree/main/tests.

### Load tester

A simple load testing tool for concurrent, resumable uploads can be found at [github.com/tus/load-tester](https://github.com/tus/load-tester). It can be used to measure the upload duration and throughput under various scenarios by simulating multiple, parallel users.

## Version support

The draft is currently still in a developing state, where it is actively discussed and modified based on the gathered feedback. This can also result in changes in the protocol mechanism that will make existing implementations of earlier draft version incompatible with newer versions. To indicate such breaking changes, each draft version specifies an interoperability version (interop version), which is incremented when a new draft version includes a breaking change over the previous versions. This interop version is included in requests and responses, allowing client and server implementations to detect when incompatible draft versions are used by the respective parties.

The following table provides an overview of which draft version is supported by which client or server implementation. A client or server can support multiple versions by adjusting to the request of the user or client. If you want to pair a client with a server for uploading data, please ensure that both implement at least one shared draft version.

| Draft version     | [-01](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-resumable-upload-01) | [-02](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-resumable-upload-02) | [-03](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-resumable-upload-03) |[-04](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-resumable-upload-04)|[-05](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-resumable-upload-05)|
|:------------------|----|----|----|----|-------|
| Interop version   | 3  | 4  | 5  | 6  | 6[^4] |
| **Clients**       |    |    |    |    |       |
| URLSession        | ✅[^5] | | ✅[^6] | ✅[^7] | ✅[^7] |
| tus-js-client     |    |    |    |    |       |
| Go example        | ✅ |    |    |    |       |
| **Servers**       |    |    |    |    |       |
| tusd              | ✅ | ✅ | ✅ |    |       |
| tusdotnet         | ✅ |    | ✅ |✅  | ✅    |
| SwiftNIO          | ✅ |    |    |    |       |
| Go example        | ✅ |    |    |    |       |
| Caddy module      |    | ✅ |    |    |       |
| **Tools**         |    |    |    |    |       |
| Conformity tester |    | ✅ |    |    |       |
| Load tester       |    |    | ✅ |    |       |

[^4]: Draft -05 did not introduce breaking changes compared to -04 and therefore kept the interop version.
[^5]: Only in iOS 17.x and macOS 14.x
[^6]: Only in iOS 18.0 and macOS 15.0
[^7]: Only since iOS 18.1 and macOS 15.1

## Interoperability

The goal is to have interoperable implementations for testing purposes. Below shows a table of the interoperability between various client and server implementations.

|                   | URLSession (iOS) | Tus-js-Client | Go client example |
|-------------------|------------------|---------------|-------------------|
| SwiftNIO          | ✅               | ❌[^3]        | ❌[^1]            |
| Tusd              | ✅               | ✅            | ✅                |
| Tusdotnet         | ✅               | ✅            | ?[^2]             |
| Go server example | ❌[^1]           | ✅            | ✅                |

[^1]: No interop version implemented by server and client.
[^2]: Interoperability has not been tested yet.
[^3]: [Cross-Origin Resource Sharing](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) is not supported by server.

## Network simulation

When running a client and server locally, the data transfer can be too fast to usefully test the pause/resume capabilities of resumable uploads. Throttling the network speed is a handy way to simulate more realistic scenarios. Browsers natively provide a setting for this in their developer tools (e.g. [Firefox](https://firefox-source-docs.mozilla.org/devtools-user/network_monitor/throttling/index.html) and [Chrome](https://developer.chrome.com/docs/devtools/settings/throttling/). When working outside of browsers, a proxy like [toxiproxy](https://github.com/Shopify/toxiproxy) can be placed in front of the upload server and control the transfer speed. It is also capable of simulating other kinds of network interruptions.
