# Modular Monolith

This monolithic repo hosts independent Golang services like `products` and `payments`, treated as separate modules for independent deployment.
### Notable features

- [x] `products` service runs at `8080`.
    - [x] Graceful Termination
- [x] `payments` service runs at `9090`
    - [x] Graceful Termination
- [x] dynamic log level adjustment for each service.
