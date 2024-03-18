# Tusd Resumable Upload Server

[Tusd](https://github.com/tus/tusd) is a server originally developed for the [tus resumable upload protocol](https://tus.io), but recent versions also provide experimental support for the resumable upload draft from the HTTP working group. Its goal is to support all draft versions and serve as a testing ground for new upload clients. Tusd is a feature-rich upload server and supports storing data on various cloud providers and notifying applications about upload progress (see its [documentation](https://github.com/tus/tusd#documentation)).

## Running

1. Download the pre-built binary from https://github.com/tus/tusd/releases/tag/v2.4.0 (or obtain the source and compile it own your own).
   ```bash
   # For example (be sure to change to your OS and architecture):
   wget https://github.com/tus/tusd/releases/download/v2.4.0/tusd_darwin_amd64.zip
   ```
2. Extract the archive
   ```bash
   unzip tusd_darwin_arm64.zip
   ```
3. Run the tusd server
   ```bash
   ./tusd_darwin_arm64/tusd -enable-experimental-protocol -host 127.0.0.1 -port 8080 -base-path /files/
   ```
4. The resumable upload server is then accepting resumable uploads at http://127.0.0.1:8080/files. It supports uploads using [draft-ietf-httpbis-resumable-upload](https://datatracker.ietf.org/doc/draft-ietf-httpbis-resumable-upload/) and [tus v1](https://tus.io/protocols/resumable-upload).

## Example

```sh
# Upload Creation Procedure
$ curl -X POST http://127.0.0.1:8080/files/ -H 'Upload-Draft-Interop-Version: 5' -H 'Upload-Complete: ?0' -d 'hello ' -i
HTTP/1.1 104 status code 104
Location: http://127.0.0.1:8080/files/d7ba0e74411775c88be9c3763c1f5b0d
Upload-Draft-Interop-Version: 5
X-Content-Type-Options: nosniff

HTTP/1.1 201 Created
Location: http://127.0.0.1:8080/files/d7ba0e74411775c88be9c3763c1f5b0d
Upload-Draft-Interop-Version: 5
Upload-Offset: 6
X-Content-Type-Options: nosniff
Date: Mon, 18 Mar 2024 20:45:37 GMT
Content-Length: 0

# Offset Retrieving Procedure
$ curl --head http://127.0.0.1:8080/files/d7ba0e74411775c88be9c3763c1f5b0d -H 'Upload-Draft-Interop-Version: 5'
HTTP/1.1 204 No Content
Cache-Control: no-store
Upload-Complete: ?0
Upload-Draft-Interop-Version: 5
Upload-Offset: 6
X-Content-Type-Options: nosniff
Date: Mon, 18 Mar 2024 20:46:11 GMT

# Upload Appending Procedure
$ curl -X PATCH http://127.0.0.1:8080/files/d7ba0e74411775c88be9c3763c1f5b0d -H 'Upload-Draft-Interop-Version: 5' -H 'Upload-Incomplete: ?0' -H 'Upload-Offset: 6' -d 'world!' -i
HTTP/1.1 204 No Content
Upload-Offset: 12
X-Content-Type-Options: nosniff
Date: Mon, 18 Mar 2024 20:46:36 GMT

# Offset Retrieving Procedure
$ curl --head http://127.0.0.1:8080/files/d7ba0e74411775c88be9c3763c1f5b0d -H 'Upload-Draft-Interop-Version: 5'
HTTP/1.1 204 No Content
Cache-Control: no-store
Upload-Complete: ?0
Upload-Draft-Interop-Version: 5
Upload-Offset: 12
X-Content-Type-Options: nosniff
Date: Mon, 18 Mar 2024 20:46:47 GMT

# Obtain uploaded file
$ curl http://127.0.0.1:8080/files/d7ba0e74411775c88be9c3763c1f5b0d
hello world!
```
