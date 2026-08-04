We are cutting a 3.0 release of kvdex and the headline change is replacing the `serialize` collection option with a real pluggable encoder.

Today a collection picks its storage format through `serialize`, which takes one of four preset strings (`"json"`, `"json-uncompressed"`, `"v8"`, `"v8-uncompressed"`) or a partial serializer object whose unset functions quietly fall back to the JSON defaults. That partial form is an awkward escape hatch rather than a real extension point. The presets weld serialization and compression together, so you cannot pair the JSON serializer with a compression backend of your own choosing. The silent fallback merging makes it hard to tell which functions are actually in play. And the serialization helpers have no importable home of their own, so nobody can reuse them outside a collection.

The 3.0 API should make encoding a first-class object that a caller builds and hands to a collection.

## The encoder contract

An `Encoder` is `{ serializer: Serializer; compressor?: Compressor }`.

A `Serializer` is `{ serialize, deserialize }`. `serialize` takes a value and returns a `Uint8Array`, either directly or as a `Promise<Uint8Array>`. `deserialize` takes a `Uint8Array` and reconstructs the original value, and may likewise be async.

A `Compressor` is `{ compress, decompress }`, both taking and returning `Uint8Array` payloads.

Collection options drop `serialize` and gain an optional `encoder?: Encoder`. When a collection has an encoder, writing a value serializes it and then compresses the result if a compressor is present; reading decompresses and then deserializes. Values must round-trip unchanged, with or without a compressor attached.

## Database factory

While we are making breaking changes, `kvdex()` should take a single options object instead of two positional arguments. `kvdex(kv, schemaDefinition)` becomes `kvdex({ kv, schema })`, where the object carries the `DenoKv` instance under `kv` and the schema definition under an optional `schema`. Export a `KvdexOptions` type for that shape and have `kvdex()` read `options.kv` and `options.schema`, defaulting to an empty schema when `schema` is left out. The returned instance type is otherwise unchanged, just derived from `options.schema`.

## The encoding modules

Serialization moves into a new `src/ext/encoding` module tree. Each of the three encoders lives in its own directory with a `mod.ts` barrel, and a top-level `src/ext/encoding/mod.ts` re-exports all of them.

**JSON.** A `jsonEncoder(options?)` factory returning an `Encoder` whose serializer is `{ serialize: jsonSerialize, deserialize: jsonDeserialize }` and whose optional `compressor` comes from `options.compressor`. Export `jsonSerialize` (value to `Uint8Array`) and `jsonDeserialize` (`Uint8Array` back to value). They have to cover the value types the library stores today, including `bigint`, `Date`, `Map`, `Set`, `RegExp`, `Uint8Array` and the other typed arrays it already handles, and deeply nested objects and arrays. Where the existing helpers have a gap for a value type, that gap carries over rather than being closed here.

**V8.** A `v8Encoder(options?)` factory returning an `Encoder` whose serializer is `{ serialize: v8Serialize, deserialize: v8Deserialize }`, again taking an optional `options.compressor`. `v8Serialize` and `v8Deserialize` produce a `Uint8Array` and cover the same range of value types. This one is a structured binary format rather than JSON, so it should carry the richer value types natively instead of encoding them by hand.

**Brotli.** A `brotliCompressor(options?)` factory returning a `Compressor` that brotli-compresses its input. It takes an optional `quality` level defaulting to `1`. `compress` returns a `Uint8Array` and `decompress` inverts it exactly.

## Public API surface

These are the supported import paths once the migration lands:

- `jsonEncoder`, `jsonSerialize`, `jsonDeserialize`, `v8Encoder`, `v8Serialize`, `v8Deserialize` and `brotliCompressor` all resolve from the top-level `src/ext/encoding/mod.ts`.
- Each encoder's own `mod.ts` barrel exports that encoder's pieces, so the JSON barrel gives you `jsonEncoder`, `jsonSerialize` and `jsonDeserialize`, the V8 barrel gives you `v8Encoder`, `v8Serialize` and `v8Deserialize`, and the brotli barrel gives you `brotliCompressor`.

Add the matching entries to the package export map so consumers get `./encoding`, `./encoding/json`, `./encoding/v8` and `./encoding/brotli`.

## What has to keep working

A collection configured with `encoder: jsonEncoder()` or `encoder: jsonEncoder({ compressor: brotliCompressor() })` must support everything an unencoded collection does: adding one or many documents, finding one or many by id, retrieving many, counting, mapping over documents, updating one, many or by id, and deleting many. Indexable collections need all of that plus the secondary index and secondary order operations the library ships working today, such as retrieving many entries in secondary order. In every case the values read back must equal the values written. JSON plus brotli is the configuration we expect people to reach for first, so it needs to round-trip correctly for every document shape we store.

## Constraints

- The serialization helpers the library already ships move into the new encoding modules; those are their supported locations from now on, and the old ones stop being exported from where they live today.
- Serialization returns `Uint8Array`, not `ArrayBuffer`, `Buffer` or a string, and deserialization reconstructs values deep-equal to the originals.
