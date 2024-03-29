#!/bin/sh
set -e

gum confirm '
Are you ready to start?
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

echo "
## You will need following tools installed:
|Name            |Required             |More info                                          |
|----------------|---------------------|---------------------------------------------------|
|git             |Yes                  |'https://git-scm.com/book/en/v2/Getting-Started-Installing-Git'|
|kubectl         |Yes                  |'https://kubernetes.io/docs/tasks/tools/#kubectl'  |
" | gum format

gum confirm "
Do you have those tools installed?
" || exit 0

#########
# Setup #
#########

INGRESS_CLASSNAME=$(yq ".ingress.classname" settings.yaml)

INGRESS_HOST=$(yq ".ingress.host" settings.yaml)

yq --inplace ".spec.ingressClassName = \"$INGRESS_CLASSNAME\"" \
    skooner/ingress.yaml

yq --inplace \
    ".spec.rules[0].host = \"dashboard.$INGRESS_HOST\"" \
    skooner/ingress.yaml

GITOPS_APP=$(yq ".gitOps.app" settings.yaml)

cp $GITOPS_APP/skooner.yaml infra/.

git add . 

git commit -m "Skooner"

git push

COUNTER=$(kubectl --namespace skooner get pods --no-headers | wc -l)

while [ $COUNTER -eq "0" ]; do
	sleep 10
	COUNTER=$(kubectl --namespace skooner get pods --no-headers | wc -l)
done

TOKEN=$(kubectl --namespace skooner create token skooner-sa)

echo "
## Use the following token to login to Skooner

$TOKEN
" | gum format
