Lambda Web Adapter talks to the app it wraps over cleartext HTTP, and only cleartext HTTP. That leaves out anyone whose app terminates TLS itself — a uvicorn process handed its own key and certificate at startup, say, or any server that simply refuses a plaintext connection. The adapter never gets a usable response out of those apps.

We want TLS to the upstream app, opt-in, off unless someone asks for it.

Operators drive it with environment variables, three to begin with: `AWS_LWA_ENABLE_TLS`, `AWS_LWA_TLS_SERVER_NAME` and `AWS_LWA_TLS_CERT_FILE`. The first of those is the switch, and it reads the way the adapter's other on/off variables already read — unset, empty, or anything that is not a valid bool leaves TLS off.

Switch it on and the adapter has to reach the app over `https`: the proxied request, and the readiness probe wherever that probe speaks HTTP. Those two are not obliged to share a port. What leaves the adapter is a real handshake, so a plaintext server on the other end stops being reachable — going quiet is not the same thing as speaking TLS. Nothing but the transport changes; paths, query strings, base-path stripping, request methods, headers and gzip compression all behave exactly as they do today.

`AWS_LWA_TLS_SERVER_NAME` is the name the adapter uses for that session. It travels in the handshake, and it is what the app's certificate gets checked against. This starts to matter once the certificate no longer covers the loopback address. Leave it unset and the session is opened for `localhost`, which is what an app serving a certificate issued to that name expects.

Then there are apps whose certificate chains to nothing the platform already trusts, and `AWS_LWA_TLS_CERT_FILE` names a bundle for those. Naming it has to be enough: with the bundle set, that app's certificate verifies and the request goes through, and with it unset the same app is out of reach. Verification is real either way. A certificate chaining to nothing trusted is refused, and so is one issued to a name other than the one configured.

Some apps go further than presenting a certificate: they will not talk to a caller that has not presented one of its own. `AWS_LWA_TLS_CLIENT_CERT_FILE` and `AWS_LWA_TLS_CLIENT_KEY_FILE` name what the adapter shows and the key that goes with it. Name both, with TLS on, and the door opens. It opens on the readiness port as well, because an app that insists on knowing who is calling does not make an exception for the probe that checks whether it is awake.

With TLS on, an identity that cannot be used is a different thing from no identity at all. A certificate named without its key, a key named without its certificate, a file that holds nothing usable: in each case somebody asked for something the adapter cannot deliver, and the answer is not to carry on as a stranger. Those requests fail. An anonymous connection is the one outcome nobody configured.

Leave the switch off and nothing moves. Same scheme, same readiness behaviour, same handling of headers, paths, query strings, request methods and gzip compression. Every deployment out there runs with the flag off. That path cannot regress.
