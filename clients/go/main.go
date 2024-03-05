package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httptrace"
	"net/textproto"
	"os"
	"strconv"
	"strings"
)

const InteropVersion = "4"

var endpoint string
var filepath string
var stateFile string

func main() {

	flag.StringVar(&endpoint, "endpoint", "http://localhost:8080/", "")
	flag.StringVar(&filepath, "file", "", "")
	flag.StringVar(&stateFile, "state", "./upload-state.txt", "")

	flag.Parse()

	if filepath == "" {
		log.Fatalln("Please specify an input file using the --file option")
	}

	file, err := os.Open(filepath)
	if err != nil {
		log.Fatalf("failed to open input file: %s", err)
	}

	fileInfo, err := file.Stat()
	if err != nil {
		log.Fatalf("failed to get file info: %s", err)
	}

	uploadUrl, ok, err := loadUploadState()
	if err != nil {
		log.Fatalf("failed to load upload state: %s", err)
	}

	var response string
	if !ok {
		// No upload state found, so we start a fresh upload with the
		response, err = uploadCreationProcedure(file)
		if err != nil {
			log.Fatalf("upload creation procedure failed: %s", err)
		}
	} else {
		offset, err := offsetRetrievingProcedure(uploadUrl)
		if err != nil {
			log.Fatalf("offset retrieving procedure failed: %s", err)
		}

		log.Printf("Upload offset is: %d", offset)

		uploadCompleteHeader := "?1"

		if offset == fileInfo.Size() {
			log.Println("File is already uploaded")
		}

		if _, err := file.Seek(offset, os.SEEK_SET); err != nil {
			log.Fatalf("failed to seek to offset: %s", err)
		}

		response, err = uploadAppendingProcedure(uploadUrl, file, offset, uploadCompleteHeader)
		if err != nil {
			log.Fatalf("upload creation procedure failed: %s", err)
		}
	}

	log.Println("Response from server is:")
	fmt.Println(response)

}

func loadUploadState() (uploadUrl string, ok bool, err error) {
	content, err := os.ReadFile(stateFile)
	if errors.Is(err, os.ErrNotExist) {
		ok = false
		err = nil
		return
	}
	if err != nil {
		return "", false, err
	}

	uploadUrl = strings.TrimSpace(string(content))
	ok = uploadUrl != ""

	return
}

func saveUploadState(uploadUrl string) error {
	return os.WriteFile(stateFile, []byte(uploadUrl), 0o644)
}

func uploadCreationProcedure(file *os.File) (string, error) {
	ctx := context.Background()
	ctx = httptrace.WithClientTrace(ctx, &httptrace.ClientTrace{
		Got1xxResponse: func(code int, header textproto.MIMEHeader) error {
			if code != 104 {
				return nil
			}

			if header.Get("Upload-Draft-Interop-Version") != InteropVersion {
				log.Printf("Received mismatching interop version for 1xx response. Ignoring it.")
				return nil
			}

			uploadOffset := header.Get("Upload-Offset")
			if uploadOffset != "" {
				log.Printf("Received 104 response. Server reported to have saved %s bytes\n", uploadOffset)
			}

			uploadUrl := header.Get("Location")
			if uploadUrl != "" {
				log.Printf("Received 104 response. Location is: %s\n", uploadUrl)

				if err := saveUploadState(uploadUrl); err != nil {
					log.Printf("failed to write upload state file: %s", err)
				}
			}

			return nil
		},
	})

	req, err := http.NewRequestWithContext(ctx, "POST", endpoint, file)
	req.Header.Set("Upload-Draft-Interop-Version", InteropVersion)
	req.Header.Set("Upload-Complete", "?1")
	if err != nil {
		return "", err
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()

	if res.StatusCode < 200 || res.StatusCode > 299 {
		return "", fmt.Errorf("unexpected status code: %d", res.StatusCode)
	}

	response, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}

	return string(response), nil
}

func offsetRetrievingProcedure(uploadUrl string) (offset int64, err error) {
	req, err := http.NewRequest("HEAD", uploadUrl, nil)
	req.Header.Set("Upload-Draft-Interop-Version", InteropVersion)
	if err != nil {
		return 0, err
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer res.Body.Close()

	if res.StatusCode < 200 || res.StatusCode > 299 {
		return 0, fmt.Errorf("unexpected status code: %d", res.StatusCode)
	}

	offset, err = strconv.ParseInt(res.Header.Get("Upload-Offset"), 10, 64)
	if err != nil {
		return 0, fmt.Errorf("failed to parse upload-offset header: %s", err)
	}

	return
}

func uploadAppendingProcedure(uploadUrl string, file *os.File, offset int64, uploadCompleteHeader string) (string, error) {
	req, err := http.NewRequest("PATCH", uploadUrl, file)
	req.Header.Set("Upload-Draft-Interop-Version", InteropVersion)
	req.Header.Set("Upload-Offset", strconv.FormatInt(offset, 10))
	req.Header.Set("Upload-Complete", uploadCompleteHeader)
	if err != nil {
		return "", err
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()

	if res.StatusCode < 200 || res.StatusCode > 299 {
		return "", fmt.Errorf("unexpected status code: %d", res.StatusCode)
	}

	response, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}

	return string(response), nil
}