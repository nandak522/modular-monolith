# Modular Monolith

This monolithic repo hosts two independent Golang services, `products` and `payments`, as separate modules for independent deployments.
* `main` is the default branch. Treated as trunk/integration branch. Doesn't need to be stable all the time.
* `release` is the release branch on which releases are made. Have to be stable all the time.

## Notable features

- [x] `products` service runs at `8080`.
    - [x] Graceful Termination
- [x] `payments` service runs at `9090`
    - [x] Graceful Termination
- [x] dynamic log level adjustment for each service.
- [x] auto-merging of main branch to a configurable list of special branches via a Github App
- [x] stopping the merging of restricted branch to default branch
