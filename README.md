# Resumable Uploads: Example implementations

This repository contains a server and client implementation of the [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/). Its latest iteration can be found at the [httpwg/http-extensions repository](https://github.com/httpwg/http-extensions/blob/main/draft-ietf-httpbis-resumable-upload.md).

The implementations are based on the draft -00 with following additional proposals:
- Server-generated upload URLs (https://github.com/httpwg/http-extensions/pull/2292)
- Retry-able upload creations using Idempotency-Key (https://github.com/httpwg/http-extensions/issues/2293)

## Requirements

The implementations have been developed using Go 1.19.

## Client

The client is located at `client/`. Currently, it is not able to upload files but is just demonstration to show how Go programs can receive 1XX status codes.

To run it (after running the server in a separate terminal):

```
go run client/main.go
```

## Server

The server is located at `server/`. Once started, it accepts the Upload Creation Procedure at `http://localhost:8080`. Uploaded files are saved in the `uploads/` directory. Please see the curl examples section below for more details on the requests.

To run it:

```
go run server/main.go
```

## Curl Examples

1. Uploading a single file in one request using the Upload Creation Procedure:

```
$ curl -i -X POST -H 'Upload-Incomplete: ?0' -d 'hello world' http://localhost:8080/
HTTP/1.1 104 status code 104
Location: http://localhost:8080/uploads/aec84ea1-1f64-4db6-b285-88c8d122b2d4

HTTP/1.1 201 Created
Location: http://localhost:8080/uploads/aec84ea1-1f64-4db6-b285-88c8d122b2d4
Upload-Incomplete: ?0
Upload-Offset: 11
Date: Fri, 11 Nov 2022 01:09:33 GMT
Content-Length: 0
```

2. Upload a file over two requests using Upload Appending Procedure and an Offset Retrieving Procedure:
```
$ curl -i -X POST -H 'Upload-Incomplete: ?1' http://localhost:8080/
HTTP/1.1 104 status code 104
Location: http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33

HTTP/1.1 201 Created
Location: http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
Upload-Incomplete: ?1
Upload-Offset: 0
Date: Fri, 11 Nov 2022 01:11:02 GMT
Content-Length: 0

$ curl -i -X PATCH -H 'Upload-Incomplete: ?1' -H 'Upload-Offset: 0' -d 'hello ' http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
HTTP/1.1 200 OK
Upload-Incomplete: ?1
Upload-Offset: 6
Date: Fri, 11 Nov 2022 01:11:52 GMT
Content-Length: 0

$ curl --head http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
HTTP/1.1 200 OK
Upload-Incomplete: ?1
Upload-Offset: 6
Date: Fri, 11 Nov 2022 01:12:10 GMT

$ curl -i -X PATCH -H 'Upload-Incomplete: ?0' -H 'Upload-Offset: 6' -d 'world' http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
HTTP/1.1 200 OK
Upload-Incomplete: ?0
Upload-Offset: 11
Date: Fri, 11 Nov 2022 01:12:31 GMT
Content-Length: 0
```

3. Upload a file while retrying the Upload Creation Procedure using Idempotency-Key:
```
$ curl -i -X POST -H 'Upload-Incomplete: ?0' -H 'Idempotency-Key: foo' -d 'hello world' http://localhost:8080/
HTTP/1.1 104 status code 104
Location: http://localhost:8080/uploads/5d167756-db41-4a5a-855f-5af346c23558

HTTP/1.1 201 Created
Location: http://localhost:8080/uploads/5d167756-db41-4a5a-855f-5af346c23558
Upload-Incomplete: ?0
Upload-Offset: 11
Date: Fri, 11 Nov 2022 01:15:22 GMT
Content-Length: 0

$ curl -i -X POST -H 'Upload-Incomplete: ?0' -H 'Idempotency-Key: foo' -d 'hello world' http://localhost:8080/
HTTP/1.1 200 OK
Upload-Incomplete: ?0
Upload-Offset: 11
Date: Fri, 11 Nov 2022 01:15:25 GMT
Content-Length: 0
```
