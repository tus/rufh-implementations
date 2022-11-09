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
			fmt.Println(code, header)
			return nil
		},
	})

	req, err := http.NewRequestWithContext(ctx, "GET", "http://localhost:8080/", nil)
	if err != nil {
		log.Fatal(err)
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()

	fmt.Printf("Response code: %d\n", res.StatusCode)
}
