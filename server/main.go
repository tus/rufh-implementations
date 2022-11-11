package main

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

const UploadDir = "./uploads/"

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/", UploadCreationHandler).Methods("POST")
	r.HandleFunc("/uploads/{id}", UploadAppendingHandler).Methods("PATCH")
	r.HandleFunc("/uploads/{id}", OffsetRetrievingHandler).Methods("HEAD")
	r.HandleFunc("/uploads/{id}", UploadCancellationHandler).Methods("DELETE")
	http.Handle("/", r)

	log.Fatal(http.ListenAndServe(":8080", nil))
}

func UploadCreationHandler(w http.ResponseWriter, r *http.Request) {
	// TODO: Handle cases without prefer

	var uploadId string
	var file *os.File
	var err error

	idempotencyKey := getIdempotencyKey(r)
	if idempotencyKey != "" {
		content, err := os.ReadFile("./uploads/" + idempotencyKey)
		if err != nil {
			if !errors.Is(err, fs.ErrNotExist) {
				sendError(w, err)
				return
			}
		} else {
			uploadId = string(content)

			var isComplete bool
			var exists bool
			var offset int64
			file, exists, isComplete, offset, err = loadUpload(uploadId)
			if err != nil {
				sendError(w, err)
				return
			}
			if !exists {
				uploadId = ""
			} else {
				defer file.Close()
				if isComplete {
					// If the upload is complete, we simply discard the request body
					// and respond with the upload state.
					setUploadHeaders(w, isComplete, offset)
					return
				}

				// Discard bytes, so request body is at same offset as file
				if _, err := io.CopyN(io.Discard, r.Body, offset); err != nil {
					sendError(w, err)
					return
				}
			}
		}
	}

	// If we were not able to find an upload using an idempotency key, create a new upload.
	if uploadId == "" {
		uploadId = uuid.NewString()

		// Create file to save uploaded chunks
		file, err = os.OpenFile("./uploads/"+uploadId, os.O_WRONLY|os.O_CREATE, 0o644)
		if err != nil {
			sendError(w, err)
			return
		}
		defer file.Close()

		// Create file to indicate incompleteness
		if err := os.WriteFile("./uploads/"+uploadId+".incomplete", nil, 0o644); err != nil {
			sendError(w, err)
			return
		}

		if idempotencyKey != "" {
			// Create file to look up idempotency key
			if err := os.WriteFile("./uploads/"+idempotencyKey, []byte(uploadId), 0o644); err != nil {
				sendError(w, err)
				return
			}
		}
	}

	// Respond with informational response
	uploadUrl := "http://localhost:8080/uploads/" + uploadId
	w.Header().Set("Location", uploadUrl)
	w.WriteHeader(104)

	// Copy request body to file
	_, err = io.Copy(file, r.Body)
	if err != nil {
		sendError(w, err)
		return
	}

	// Obtain latest offset
	uploadOffset, err := file.Seek(0, io.SeekEnd)
	if err != nil {
		sendError(w, err)
		return
	}

	// Check if upload is done now.
	// Note: If there was an issue reading the request body, we will already
	// have errored out. So here we can assume the request body reading was successful.
	uploadIsComplete := !getUploadIncomplete(r)
	if uploadIsComplete {
		// Remove file indicating incompleteness
		if err := os.Remove("./uploads/" + uploadId + ".incomplete"); err != nil {
			sendError(w, err)
			return
		}
	}

	setUploadHeaders(w, uploadIsComplete, uploadOffset)
	w.WriteHeader(201)
}

func UploadAppendingHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	file, exists, isComplete_server, offset_server, err := loadUpload(id)
	if err != nil {
		sendError(w, err)
		return
	}
	if !exists {
		w.WriteHeader(404)
		w.Write([]byte("upload not found\n"))
		return
	}
	defer file.Close()

	isComplete_client := !getUploadIncomplete(r)
	offset_client, ok := getUploadOffset(r)
	if !ok {
		w.WriteHeader(500)
		w.Write([]byte("invalid or missing Upload-Offset header\n"))
		return
	}

	if offset_server != offset_client {
		setUploadHeaders(w, isComplete_server, offset_server)
		w.WriteHeader(409)
		w.Write([]byte("mismatching Upload-Offset value\n"))
		return
	}

	if isComplete_server {
		setUploadHeaders(w, isComplete_server, offset_server)
		w.WriteHeader(400)
		w.Write([]byte("upload is already complete\n"))
		return
	}

	// r.Body is always non-nil
	n, err := io.Copy(file, r.Body)
	if err != nil {
		sendError(w, err)
		return
	}

	offset_server += n

	if isComplete_client {
		isComplete_server = true
		if err := os.Remove(UploadDir + id + ".incomplete"); err != nil {
			sendError(w, err)
			return
		}
	}

	setUploadHeaders(w, isComplete_server, offset_server)
}

func OffsetRetrievingHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	file, exists, isComplete, offset, err := loadUpload(id)
	if err != nil {
		sendError(w, err)
		return
	}
	if !exists {
		w.WriteHeader(404)
		w.Write([]byte("upload not found\n"))
		return
	}
	defer file.Close()

	setUploadHeaders(w, isComplete, offset)
}

func UploadCancellationHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	err := os.Remove(UploadDir + id)
	if errors.Is(err, os.ErrNotExist) {
		w.WriteHeader(404)
		w.Write([]byte("upload not found\n"))
		return
	}
	if err != nil {
		sendError(w, err)
		return
	}

	_ = os.Remove(UploadDir + id + ".incomplete")

	// TODO: link from Idempotency-Key should also be removed, if available
}

func getIdempotencyKey(r *http.Request) string {
	idempotencyKey := r.Header.Get("Idempotency-Key")
	if idempotencyKey == "" {
		return ""
	}

	sum := sha256.Sum256([]byte(idempotencyKey))
	return hex.EncodeToString(sum[:])
}

func getUploadIncomplete(r *http.Request) bool {
	if r.Header.Get("Upload-Incomplete") == "?1" {
		return true
	} else {
		return false
	}
}

func getUploadOffset(r *http.Request) (int64, bool) {
	offset, err := strconv.Atoi(r.Header.Get("Upload-Offset"))
	if err != nil {
		return 0, false
	}
	return int64(offset), true
}

func sendError(w http.ResponseWriter, err error) {
	w.WriteHeader(500)
	w.Write([]byte(err.Error() + "\n"))
}

func setUploadHeaders(w http.ResponseWriter, isComplete bool, offset int64) {
	if isComplete {
		w.Header().Set("Upload-Incomplete", "?0")
	} else {
		w.Header().Set("Upload-Incomplete", "?1")
	}
	w.Header().Set("Upload-Offset", strconv.FormatInt(offset, 10))
}

func loadUpload(id string) (file *os.File, exists bool, isComplete bool, offset int64, err error) {
	file, err = os.OpenFile(UploadDir+id, os.O_WRONLY, 0o644)
	if errors.Is(err, os.ErrNotExist) {
		exists = false
		err = nil
		return
	}
	if err != nil {
		return
	}

	exists = true
	offset, err = file.Seek(0, io.SeekEnd)
	if err != nil {
		return
	}

	_, err = os.Stat(UploadDir + id + ".incomplete")
	if errors.Is(err, os.ErrNotExist) {
		isComplete = true
		err = nil
	}
	if err != nil {
		return
	}

	return
}
