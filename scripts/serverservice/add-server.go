package main

import (
	"context"

	"github.com/google/uuid"
	"github.com/hashicorp/go-retryablehttp"
	serverservice "go.hollow.sh/serverservice/pkg/api/v1"
)

func main() {
	client, err := serverservice.NewClientWithToken(
		"dummy",
		"http://localhost:8000",
		retryablehttp.NewClient().StandardClient(),
	)

	if err != nil {
		panic(err)
	}

	ctx := context.Background()

	serverUUID := uuid.MustParse("")

	// Add server
	server := serverservice.Server{UUID: serverUUID, Name: "ede81024", FacilityCode: "fra9"}

	_, _, err = client.Create(ctx, server)
	if err != nil {
		panic(err)
	}

	// Add server BMC credential
	_, err = client.SetCredential(ctx, serverUUID, "bmc", "root", "calvin")
	if err != nil {
		panic(err)
	}

	// Add server BMC IP attribute
	bmcIPAttr := serverservice.Attributes{Namespace: "sh.hollow.bmc_info", Data: []byte(`{"address": "192.168.1.1"}`)}

	_, err = client.CreateAttributes(ctx, serverUUID, bmcIPAttr)
	if err != nil {
		panic(err)
	}

}
