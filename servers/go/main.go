package main

import (
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

const UploadDir = "./uploads/"
const InteropVersion = "3"

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/", UploadCreationHandler).Methods("POST")
	r.HandleFunc("/uploads/{id}", UploadAppendingHandler).Methods("PATCH")
	r.HandleFunc("/uploads/{id}", OffsetRetrievingHandler).Methods("HEAD")
	r.HandleFunc("/uploads/{id}", UploadCancellationHandler).Methods("DELETE")

	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"POST", "PATCH", "HEAD", "DELETE"},
		AllowedHeaders: []string{"*"},
		ExposedHeaders: []string{"Upload-Draft-Interop-Version", "Upload-Offset", "Upload-Incomplete", "Location"},
	})
	http.Handle("/", c.Handler(r))

	log.Println("Listening on http://localhost:8080/")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func UploadCreationHandler(w http.ResponseWriter, r *http.Request) {
	// TODO: Handle cases without prefer

	var uploadId string
	var file *os.File
	var err error

	// Create a new upload.
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

	uploadUrl := "http://localhost:8080/uploads/" + uploadId
	w.Header().Set("Location", uploadUrl)

	// Respond with informational response, if interop version matches
	if getInteropVersion(r) == InteropVersion {
		w.Header().Set("Upload-Draft-Interop-Version", InteropVersion)
		w.WriteHeader(104)
		w.Header().Del("Upload-Draft-Interop-Version")
	}

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
		w.WriteHeader(400)
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
}

func getInteropVersion(r *http.Request) string {
	return r.Header.Get("Upload-Draft-Interop-Version")
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
