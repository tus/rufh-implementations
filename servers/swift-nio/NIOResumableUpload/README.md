# Building a resumable upload server with SwiftNIO

Support HTTP resumable upload protocol in SwiftNIO by translating resumable uploads to regular uploads.

## Overview

- Note: This sample code project is associated with WWDC23 session 10006: [Build robust and resumable file transfers](https://developer.apple.com/wwdc23/10006/).

## Configure the sample code project

Before you run the sample code project:

1. In the `Package.swift` file of an existing HTTP server project, add `.package(path: "/path/to/swift-nio-resumable-upload")` as one of the dependencies.
2. Import `NIOResumableUpload` in your SwiftNIO bootstrapping code.
3. Create an upload context: `let uploadContext = HTTPResumableUploadContext(origin: "https://example.com")`.
4. Wrap your HTTP server channel handler within `HTTPResumableUploadHandler`.
