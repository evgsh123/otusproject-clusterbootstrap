#!/bin/bash
echo $GH_TOKEN | gh auth login --with-token
for i in $(gh repo ls | grep boutiqu | awk '{print $1}'); do
	gh secret -R $i set REPO_NAME  --body "cr.yandex/$(cat out/ycr.conf)"
	gh secret -R $i set YC_SA_JSON_CREDENTIALS  < out/auth.key.json
        #gh workflow -R $i run workflow.yaml
done
