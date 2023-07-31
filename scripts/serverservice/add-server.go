package main

import (
	"context"
	"flag"
	"fmt"
	"log"

	"github.com/google/uuid"
	"github.com/hashicorp/go-retryablehttp"
	serverservice "go.hollow.sh/serverservice/pkg/api/v1"
)

func main() {

	endpoint := flag.String("endpoint", "http://localhost:8000", "Serverservice endpoint")
	serverID := flag.String("server-id", "", "Server UUID to be added into serverservice")
	facilityCode := flag.String("facility", "", "Facility code (e.g fra9)")
	bmcUser := flag.String("bmc-user", "", "BMC username")
	bmcPass := flag.String("bmc-pass", "", "BMC password")
	bmcAddr := flag.String("bmc-addr", "", "BMC address")

	flag.Parse()

	switch {
	case *serverID == "":
		log.Fatal("expected -server-id flag")
	case *facilityCode == "":
		log.Fatal("expected -facility flag")
	case *bmcUser == "":
		log.Fatal("expected -bmc-user flag")
	case *bmcPass == "":
		log.Fatal("expected -bmc-pass flag")
	case *bmcAddr == "":
		log.Fatal("expected -bmc-addr flag")
	}

	client, err := serverservice.NewClientWithToken(
		"dummy",
		*endpoint,
		retryablehttp.NewClient().StandardClient(),
	)

	if err != nil {
		panic(err)
	}

	ctx := context.Background()

	serverUUID := uuid.MustParse(*serverID)

	// Add server
	server := serverservice.Server{UUID: serverUUID, Name: serverUUID.String(), FacilityCode: *facilityCode}

	_, _, err = client.Create(ctx, server)
	if err != nil {
		panic(err)
	}

	// Add server BMC credential
	_, err = client.SetCredential(ctx, serverUUID, "bmc", *bmcUser, *bmcPass)
	if err != nil {
		panic(err)
	}

	// Add server BMC IP attribute
	addrAttr := fmt.Sprintf(`{"address": "%s"}`, *bmcAddr)
	bmcIPAttr := serverservice.Attributes{Namespace: "sh.hollow.bmc_info", Data: []byte(addrAttr)}
	_, err = client.CreateAttributes(ctx, serverUUID, bmcIPAttr)
	if err != nil {
		panic(err)
	}

}
