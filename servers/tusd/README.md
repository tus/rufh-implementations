# tusd Resumable Upload Server

[tusd](https://github.com/tus/tusd) is a server implementing the [tus resumable upload protocol](https://tus.io). Since version v1.12.1, it also provides experimental support for the resumable upload draft from the HTTP working group. It is a feature-rich upload server and supports storing data on various cloud providers and notifying applications about upload progress (see its [documentation](https://github.com/tus/tusd#documentation)).

## Running

1. Download the pre-built binary from https://github.com/tus/tusd/releases/tag/v1.12.0 (or obtain the source and compile it own your own).
   ```bash
   # For example (be sure to change to your OS and architecture):
   wget https://github.com/tus/tusd/releases/download/v1.12.1/tusd_darwin_arm64.zip
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
$ curl -X POST http://127.0.0.1:8080/files/ -H 'Upload-Draft-Interop-Version: 3' -H 'Upload-Incomplete: ?1' -d 'hello ' -i
HTTP/1.1 104 status code 104
Location: http://127.0.0.1:8080/files/06aa228f635ce4e36abc29f804043efe
Upload-Draft-Interop-Version: 3
X-Content-Type-Options: nosniff

HTTP/1.1 201 Created
Location: http://127.0.0.1:8080/files/06aa228f635ce4e36abc29f804043efe
Upload-Draft-Interop-Version: 3
Upload-Offset: 6
X-Content-Type-Options: nosniff
Date: Tue, 25 Jul 2023 12:27:41 GMT
Content-Length: 0

# Offset Retrieving Procedure
$ curl --head  http://127.0.0.1:8080/files/06aa228f635ce4e36abc29f804043efe -H 'Upload-Draft-Interop-Version: 3'
HTTP/1.1 204 No Content
Cache-Control: no-store
Upload-Draft-Interop-Version: 3
Upload-Incomplete: ?1
Upload-Offset: 6
X-Content-Type-Options: nosniff
Date: Tue, 25 Jul 2023 12:28:33 GMT

# Upload Appending Procedure
$ curl -X PATCH http://127.0.0.1:8080/files/06aa228f635ce4e36abc29f804043efe  -H 'Upload-Draft-Interop-Version: 3' -H 'Upload-Incomplete: ?0' -H 'Upload-Offset: 6' -d 'world!' -i
HTTP/1.1 204 No Content
Upload-Offset: 12
X-Content-Type-Options: nosniff
Date: Tue, 25 Jul 2023 12:29:53 GMT

# Offset Retrieving Procedure
$ curl --head  http://127.0.0.1:8080/files/06aa228f635ce4e36abc29f804043efe -H 'Upload-Draft-Interop-Version: 3'
HTTP/1.1 204 No Content
Cache-Control: no-store
Upload-Draft-Interop-Version: 3
Upload-Incomplete: ?0
Upload-Offset: 12
X-Content-Type-Options: nosniff
Date: Tue, 25 Jul 2023 12:30:46 GMT

# Obtain uploaded file
$ curl http://127.0.0.1:8080/files/06aa228f635ce4e36abc29f804043efe
hello world!
```
