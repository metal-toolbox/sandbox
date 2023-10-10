package main

import (
	"context"
	"log"
	"strings"

	"github.com/bmc-toolbox/common"
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

	componentSlugs := []string{
		common.SlugBackplaneExpander,
		common.SlugChassis,
		common.SlugTPM,
		common.SlugGPU,
		common.SlugCPU,
		common.SlugPhysicalMem,
		common.SlugStorageController,
		common.SlugBMC,
		common.SlugBIOS,
		common.SlugDrive,
		common.SlugDriveTypePCIeNVMEeSSD,
		common.SlugDriveTypeSATASSD,
		common.SlugDriveTypeSATAHDD,
		common.SlugNIC,
		common.SlugPSU,
		common.SlugCPLD,
		common.SlugEnclosure,
		common.SlugUnknown,
		common.SlugMainboard,
	}

	for _, slug := range componentSlugs {
		sct := serverservice.ServerComponentType{
			Name: slug,
			Slug: strings.ToLower(slug),
		}

		_, err := client.CreateServerComponentType(ctx, sct)
		if err != nil {
			log.Fatal(err)
		}

	}
}
