# Modular Monolith

This monolithic repo hosts two independent Golang services, `products` and `payments`, as separate modules for independent deployments.
| Branch | Default | Requirements |
| \
--- | --- | --- |
|`main`| Yes | Treated as trunk/integration branch. Need to be stable all the time as changes in this branch auto-flow to other branches.|
|`release`| No | Releases are made from this branch. Have to be stable all the time.|
|`restricted`| No | Special branch whose merge to `main` is not allowed. |

## Notable features

- [x] `products` service runs at `8080`.
    - [x] Graceful Termination
- [x] `payments` service runs at `9090`
    - [x] Graceful Termination
- [x] dynamic log level adjustment for each service.
- [x] auto-merging of main branch to a configurable list of special branches via a Github App
- [x] stopping the merging of restricted branch to default branch

### Helm commands
#### To render templates
```sh
CONTEXT_PREFIX='kind'
CLUSTER_NAME='sandbox'
helm --kube-context "${CONTEXT_PREFIX}-${CLUSTER_NAME}" template -v 5 \
    --namespace products \
    --logtostderr \
    --debug \
    --values charts/products/values-default.yaml \
    products \
    charts/products
```

#### To install
```sh
CONTEXT_PREFIX='kind'
CLUSTER_NAME='sandbox'
helm --kube-context "${CONTEXT_PREFIX}-${CLUSTER_NAME}" upgrade \
    --wait \
    --create-namespace \
    --namespace products \
    --logtostderr \
    --debug \
    --install \
    --timeout 300s \
    --values charts/products/values-default.yaml \
    products \
    charts/products
```

### To view upcoming changes
```sh
CONTEXT_PREFIX='kind'
CLUSTER_NAME='sandbox'
helm --kube-context "${CONTEXT_PREFIX}-${CLUSTER_NAME}" template \
    --namespace products \
    --values charts/products/values-default.yaml \
    products \
    charts/products 2>&1 | KUBECTL_EXTERNAL_DIFF="diff -u --color=always" kubectl --context "${CONTEXT_PREFIX}-${CLUSTER_NAME}" diff --namespace products -f - 2>&1
```
