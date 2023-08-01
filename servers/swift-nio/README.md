# SwiftNIO Resumable Upload Server

This example contains a resumable upload server built using SwiftNIO. It is based on the `NIOResumableUpload` package, which was published from [Apple's WWDC23](https://developer.apple.com/videos/play/wwdc2023/10006/).

## Directory Structure

- `ExampleServer/Sources/main.swift` contains the main server logic. It does not consider resumable uploads directly because this is handled transparently by NIOResumableUpload
- `NIOResumableUpload` contains the logic for handling the resumable upload protocol. It was taken from the [WWDC23 sample project](https://developer.apple.com/documentation/foundation/urlsession/building_a_resumable_upload_server_with_swiftnio).

## Running

Swift 5.7 is required for running the code. To start the server, use

```bash
cd ExampleServer/ && swift run
```

The resumable upload server will be accessible at http://127.0.0.1:8080/

## Examples

1. Sending a complete upload in one request. The entire data is included in the Upload Creation Procedure:

```
$ curl -i -X POST 127.0.0.1:8080 -H 'upload-draft-interop-version: 3' -H 'upload-incomplete: ?0' -d "hello world!"
HTTP/1.1 104 Upload Resumption Supported
Upload-Draft-Interop-Version: 3
Location: http://127.0.0.1:8080/resumable_upload/11300331685477311003-8980133255566083779

HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 38
Upload-Draft-Interop-Version: 3
Location: http://127.0.0.1:8080/resumable_upload/11300331685477311003-8980133255566083779
Upload-Incomplete: ?0
Upload-Offset: 12

Receive a request with body length: 12
```

2. Send an upload in multiple requests. The first Upload Creation Procedure is carries the partial file. Then the Offset Retrieving Procedure fetches the current offset and allow the Upload Appending Procedure to complete the upload:

```
$ curl -i -X POST 127.0.0.1:8080 -H 'upload-draft-interop-version: 3' -H 'upload-incomplete: ?1' -d "hello "
HTTP/1.1 104 Upload Resumption Supported
Upload-Draft-Interop-Version: 3
Location: http://127.0.0.1:8080/resumable_upload/4775349330246725696-8661204137960432797

HTTP/1.1 201 Created
Upload-Draft-Interop-Version: 3
Location: http://127.0.0.1:8080/resumable_upload/4775349330246725696-8661204137960432797
Upload-Incomplete: ?1
Upload-Offset: 6
transfer-encoding: chunked

$ curl -i --head  http://127.0.0.1:8080/resumable_upload/4775349330246725696-8661204137960432797 -H 'upload-draft-interop-version: 3'
HTTP/1.1 204 No Content
Upload-Draft-Interop-Version: 3
Upload-Incomplete: ?1
Upload-Offset: 6
Cache-Control: no-store

$ curl -i -X PATCH http://127.0.0.1:8080/resumable_upload/4775349330246725696-8661204137960432797 -H 'upload-draft-interop-version: 3' -H 'upload-offset: 6' -H 'upload-incomplete: ?0' -d "world!"
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 38
Upload-Draft-Interop-Version: 3
Upload-Incomplete: ?0
Upload-Offset: 12

Receive a request with body length: 12
```
