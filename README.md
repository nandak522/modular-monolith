# Modular Monolith

This monolithic repo hosts two independent Golang services, `products` and `payments`, as separate modules for independent deployments.
| Branch | Default | Requirements |
| --- | --- | --- |
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
