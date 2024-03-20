# products

## Run server
```sh
go build -o server && $PWD/cmd/server && ./server -config=config/local.yaml

# If you are really conscious about the size. You can run this instead:
go build -ldflags="-s -w" -a -o server && $PWD/cmd/server -config=config/local.yaml
```

---
## Install as Helm chart
```sh
kubectl create ns products

cd charts/products

CONTEXT=kind-cell-1-blue
RELEASE_NAME=products
# RELEASE_NAME=canary
# RELEASE_NAME=baseline
helm --kube-context $CONTEXT template -v 5 \
    --create-namespace \
    --namespace products \
    --logtostderr \
    --debug \
    --values values-default.yaml \
    --values values-secrets.yaml \
    --values values-infra-secrets.yaml \
    $RELEASE_NAME \
    .

RELEASE_NAME=products
# RELEASE_NAME=canary
# RELEASE_NAME=baseline
helm --kube-context $CONTEXT upgrade -v 3 \
    --create-namespace \
    --namespace products \
    --logtostderr \
    --debug \
    --install \
    --atomic \
    --timeout 60s \
    --debug \
    --cleanup-on-fail \
    --values values-default.yaml \
    --values values-secrets.yaml \
    --values values-infra-secrets.yaml \
    $RELEASE_NAME \
    .
```

---
## Create a Git Tag
Whenever a new release/tag has to be created, just update `version.go` and push it to `main` branch. A github workflow is already configured that creates the actual (git) tag, which will be available in https://github.com/nandak522/modular-monolith/tags page.

> For now Github release creation is still manual.

---
## Create a Docker Image
Every git push to `main` branch creates a new docker image tagged with git sha. Besides this, When there is a `version.go` change, an additional docker image gets pushed with the respective version as tag. Images can be verified at [Dockerhub](https://hub.docker.com/r/nanda/modular-monolith/tags?page=1&ordering=last_updated).
