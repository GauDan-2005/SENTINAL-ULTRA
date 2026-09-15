Lambda Web Adapter can only talk to the wrapped web app over plain `http` today. That's a blocker for anyone whose app terminates TLS itself and only listens on `https` — think a FastAPI/uvicorn app started with `--ssl-keyfile`/`--ssl-certfile`, or any server that refuses cleartext. Right now the adapter always builds `http://host:port` URLs for both the readiness check and the proxied request, so those apps are unreachable. We need the adapter to optionally speak HTTPS to the upstream app.

Add opt-in TLS support to the `lambda_web_adapter` crate, driven by three new environment variables, surfaced as three new public fields on `AdapterOptions`:

- `enable_tls: bool` — read from `AWS_LWA_ENABLE_TLS`. Parse it as a bool; default to `false` when the var is unset or unparseable. When true, the adapter should reach the app over `https` instead of `http`.
- `tls_server_name: Option<String>` — read from `AWS_LWA_TLS_SERVER_NAME`. `Some(..)` when the var is set, `None` otherwise. This is the server name used for certificate verification (e.g. `api.example.com`) — useful when the app's cert CN doesn't match `localhost`/the loopback address.
- `tls_cert_file: Option<String>` — read from `AWS_LWA_TLS_CERT_FILE`. `Some(..)` when set, `None` otherwise. Points at a CA/cert bundle file so a self-signed or custom cert can be trusted.

`AdapterOptions::from_env()` must populate all three from those env vars with the semantics above. These fields sit alongside the existing ones (`host`, `port`, `readiness_check_port`, `readiness_check_path`, `readiness_check_protocol`, `base_path`, `async_init`, `compression`) and are constructed directly in tests, so they must be public struct fields.

Behavior when `enable_tls` is on:
- Both the healthcheck URL and the upstream app URL must use the `https` scheme instead of `http`. When `enable_tls` is false the scheme stays `http` — existing plain-HTTP behavior must be completely unchanged (all the current readiness/basic/headers/path-encoding/query-param/POST-PUT-DELETE/compression behavior keeps working exactly as before when TLS is off).
- The HTTP client the adapter uses must support HTTPS connections while still handling plain `http` too — an HTTPS-capable client should be used regardless, and only the scheme flips based on `enable_tls`.
- If `tls_server_name` is set, use it as the expected server name for certificate verification; otherwise fall back to `localhost`.
- If `tls_cert_file` is set, make that cert bundle trusted when constructing the adapter.

Keep `AdapterOptions` and `Protocol` deriving what they already derive (they're built with `..` struct-update and `Default` in places). Don't break the existing public API beyond the additive field/type changes described here.

Do not modify any files under `tests/` — the test suite is fixed and will be restored before grading.
