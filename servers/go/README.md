# Simple Resumable Upload Server

This folder contains a simple server implementation in Go of the [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/). Its latest iteration can be found at the [httpwg/http-extensions repository](https://github.com/httpwg/http-extensions/blob/main/draft-ietf-httpbis-resumable-upload.md).

The implementations are based on the draft [-05](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/05/).

## Requirements

The implementations have been developed using Go 1.19.

## Running

To run it:

```
go run main.go
```

Once started, it accepts the Upload Creation Procedure at `http://localhost:8080`. Uploaded files are saved in the `uploads/` directory. Please see the curl examples section below for more details on the requests.

## Curl Examples

1. Uploading a single file in one request using the Upload Creation Procedure:

```
$ curl -i -X POST -H 'Upload-Complete: ?1' -d 'hello world' http://localhost:8080/
HTTP/1.1 104 status code 104
Location: http://localhost:8080/uploads/aec84ea1-1f64-4db6-b285-88c8d122b2d4

HTTP/1.1 201 Created
Location: http://localhost:8080/uploads/aec84ea1-1f64-4db6-b285-88c8d122b2d4
Upload-Complete: ?1
Upload-Offset: 11
Date: Fri, 11 Nov 2022 01:09:33 GMT
Content-Length: 0
```

2. Upload a file over two requests using Upload Appending Procedure and an Offset Retrieving Procedure:

```
$ curl -i -X POST -H 'Upload-Complete: ?0' http://localhost:8080/
HTTP/1.1 104 status code 104
Location: http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33

HTTP/1.1 201 Created
Location: http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
Upload-Complete: ?0
Upload-Offset: 0
Date: Fri, 11 Nov 2022 01:11:02 GMT
Content-Length: 0

$ curl -i -X PATCH -H 'Upload-Complete: ?0' -H 'Upload-Offset: 0' -H 'Content-Type: application/partial-upload' -d 'hello ' http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
HTTP/1.1 200 OK
Upload-Complete: ?0
Upload-Offset: 6
Date: Fri, 11 Nov 2022 01:11:52 GMT
Content-Length: 0

$ curl --head http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
HTTP/1.1 200 OK
Upload-Complete: ?0
Upload-Offset: 6
Date: Fri, 11 Nov 2022 01:12:10 GMT

$ curl -i -X PATCH -H 'Upload-Complete: ?1' -H 'Upload-Offset: 6' -H 'Content-Type: application/partial-upload' -d 'world' http://localhost:8080/uploads/5bfdf470-7bac-4e83-afcb-bbaf87ff2c33
HTTP/1.1 200 OK
Upload-Complete: ?1
Upload-Offset: 11
Date: Fri, 11 Nov 2022 01:12:31 GMT
Content-Length: 0
```
