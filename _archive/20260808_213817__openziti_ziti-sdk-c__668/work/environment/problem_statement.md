# Controller failover for highly available deployments

The C SDK assumes there is exactly one Ziti controller. An identity's configuration carries a single controller URL, and the controller client is built from that one URL. In a highly available deployment an identity is served by several interchangeable controllers, and any one of them can stop answering at any moment. Today, once the SDK has latched onto a controller and that controller goes away, every request fails even though healthy peers are known.

The controller client needs to manage a set of endpoints and move between them on its own, so an application stays connected for as long as one controller is reachable.

## Configuration

`ziti_load_config` should treat the controller list as the source of truth.

- A config that supplies neither a controller list nor the legacy single controller URL is `ZITI_INVALID_CONFIG`.
- A config that supplies only the legacy `controller_url` is still valid. Move that value into `controllers` and leave `controller_url` unset, so everything downstream reads one field.
- A config that already supplies `controllers` loads as it stands.

`ziti_context_init` should accept a config that names its controllers either way, and reject only a config that names none.

## Controller client

`ziti_ctrl_init` takes a `model_list` of endpoint URLs where it takes a single `const char *url` today, and its other parameters are unchanged. A controller then answers for the whole set:

- an empty list is `ZITI_INVALID_CONFIG`, and the controller says it has no endpoints
- the endpoints it is working with are readable as a `model_map` on `ziti_controller` called `endpoints`, keyed by URL, so the same URL listed twice is one endpoint
- the endpoint currently in use is readable as `url`, and it is always one of the endpoints in that map
- the HTTP client underneath is talking to that endpoint, not to some other member of the set

Closing a controller releases the endpoints it was holding.

A controller can answer a request by naming a different address for itself. When it does, that address becomes the one in use, and it takes the superseded address's place in the endpoint set rather than being added beside it, so the set does not grow and `url` is still one of its members. The endpoint in use has to stay valid for as long as the controller does, through every one of these moves and through the refresh above, and it has to be released when the controller closes.

## Failover on the request path

How many requests a controller is waiting on is readable as `active_reqs`. Starting a request raises it and the response coming back lowers it, so it is at zero once the loop has drained and nothing is outstanding.

When a response comes back as a transport level failure, which is a negative response code other than a cancellation, and nothing else is in flight, the controller should move to another endpoint. Pick one from the endpoint set it knows about, make that the current `url`, and point the HTTP client at it. The request that failed still reports the failure to its own caller, and it reports it as the same error the SDK already gives today when a controller cannot be reached. That contract is in the code now and this change must not move it.

Choosing an endpoint should prefer the ones currently believed to be online. The endpoint that just failed is recorded as offline, so it is passed over while better options remain, and when none are believed online any known endpoint will do. With a single configured endpoint there is nothing else to move to, so the selection stays where it is.

## Learning about peers

The endpoint set should not stay frozen at whatever the configuration listed. Once the SDK holds a session with a controller, and again whenever it fetches the current edge routers, it should ask that controller for its peers and rebuild the endpoint map from each peer's v1 edge API address, carrying the online state the controller reports for each one. Whichever way a session is established, ask for peers only when the controller advertised the highly available controller capability in its version response, and only once there is a session to ask with, since a controller will not list its peers to a caller that has not authenticated. A refreshed set can leave out the endpoint currently in use, and when it does the controller moves to one the refreshed set does name.

## What a move invalidates

The version a controller reports, and the highly available capability read out of it, describe the endpoint that answered for them. They are not facts about the set. So whenever the endpoint in use changes, by any of the routes above, what the previous endpoint reported stops applying, and a caller asking afterwards gets an answer from the endpoint in use rather than one carried over from before the move.

Callers that used to hand `ziti_ctrl_init` a bare URL build the one-element list it now needs instead, and the library and the tests it builds today still build afterwards.
