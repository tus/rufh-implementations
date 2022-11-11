package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"net/http/httptrace"
	"net/textproto"
)

func main() {
	ctx := context.Background()
	ctx = httptrace.WithClientTrace(ctx, &httptrace.ClientTrace{
		Got1xxResponse: func(code int, header textproto.MIMEHeader) error {
			uploadUrl := header.Get("Location")
			fmt.Printf("Received 1xx response: %d. Location is: %s\n", code, uploadUrl)
			return nil
		},
	})

	req, err := http.NewRequestWithContext(ctx, "POST", "http://localhost:8080/", nil)
	if err != nil {
		log.Fatal(err)
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()

	uploadUrl := res.Header.Get("Location")
	fmt.Printf("Received 2xx response: %d. Location is: %s\n", res.StatusCode, uploadUrl)
}
