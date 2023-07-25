# Go Resumable Upload Client

This folder contains a simple resumable upload client in Go.

## Running

First, make sure that you have a resumable upload server running, for example at http://localhost:8080/files. Then, to upload a file `my_file.bin`, run

```sh
go run main.go --file my_file.bin --endpoint http://localhost:8080/files/ --state ./upload-state.txt
```

The upload state (i.e. the upload URL) will be stored in the state file `upload-state.txt`. If you rerun the client with the same state file, it will try to resume the upload by querying the server for the upload offset. You can also try to interrupt the client process while the upload is ongoing and rerun the command to resume the upload.
