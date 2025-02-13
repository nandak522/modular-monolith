# Modular Monolith

This monolithic repo hosts two independent Golang services, `products` and `payments`, as separate modules for independent deployments.


## Notable features

- [x] `products` service runs at `8080`.
    - [x] Graceful Termination
- [x] `payments` service runs at `9090`
    - [x] Graceful Termination
- [x] dynamic log level adjustment for each service.
- [x] auto-merging of main branch to a configurable list of special branches via a Github App
