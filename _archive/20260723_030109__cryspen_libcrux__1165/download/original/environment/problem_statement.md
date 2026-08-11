**Summary.** The `libcrux-ml-kem` crate exposes idiomatic Rust ML-KEM APIs, but integrators who target the Post-Quantum Cryptography Project (PQCP) common API surface — the byte-array-oriented `crypto_kem_*` functions modeled on the reference C interface from mlkem-native — have nothing to call. Provide that common API for ML-KEM so downstream code written against the PQCP naming and calling conventions can generate keys, encapsulate, and decapsulate against this implementation without adopting the crate's native types.

**User story.** As a developer wiring ML-KEM into a system that already speaks the PQCP `crypto_kem_*` conventions, I want a set of functions with the reference names, argument order, and byte-array signatures — plus an "unpacked"/struct variant that operates on the crate's in-memory key types — so that a keypair → encapsulate → decapsulate round-trip produces matching shared secrets on both key representations.

**Feature gate.** The entire API is additive and must live behind a new, off-by-default Cargo feature named `pqcp` declared in `libcrux-ml-kem/Cargo.toml`. When `pqcp` is not enabled the crate must build and behave exactly as before. The API is generated for each parameter set (ML-KEM 512, 768, and 1024) and is reachable at the module path `<crate>::mlkem<variant>::pqcp` — concretely `libcrux_ml_kem::mlkem768::pqcp` for the 768 parameter set (and the analogous `mlkem512`/`mlkem1024` paths). The feature composes with the existing `rand` feature: the randomness-sampling entry points are only compiled when both `pqcp` and `rand` are enabled.

Length constants. Each `pqcp` module must publish these `usize` constants, sized to the parameter set, so callers can allocate fixed-size buffers: `PK_LEN` (public key bytes), `SK_LEN` (private key bytes), `KEYGEN_SEED_LEN` (key-generation seed bytes), `ENCAPS_SEED_LEN` (encapsulation seed bytes), `CT_LEN` (ciphertext bytes), and `SS_LEN` (shared secret bytes).

Error type. Failures are reported through a single public enum `PQCPError` with the variants `KeyGeneration`, `Encapsulation`, `Decapsulation`, `InvalidPublicKey`, and `InvalidPrivateKey`. It must derive `Debug`. Following the reference convention, the fallible functions take `&mut` output buffers and return `Result<(), PQCPError>` rather than returning values by move; the `Ok` payload is `()`.

Packed (byte-array) API. In `mlkem<variant>::pqcp`, provide:

1. `crypto_kem_keypair_derand(pk: &mut [u8; PK_LEN], sk: &mut [u8; SK_LEN], coins: [u8; KEYGEN_SEED_LEN]) -> Result<(), PQCPError>` — generate a keypair from caller-supplied randomness, writing the serialized public and private keys into `pk`/`sk`; on internal failure return `Err(PQCPError::KeyGeneration)`.
2. `crypto_kem_keypair(pk: &mut [u8; PK_LEN], sk: &mut [u8; SK_LEN], rng: &mut impl rand::CryptoRng) -> Result<(), PQCPError>` — as above but sampling the seed internally from `rng`. Only compiled under the `rand` feature.
3. `crypto_kem_enc_derand(ct: &mut [u8; CT_LEN], ss: &mut [u8; SS_LEN], pk: &[u8; PK_LEN], coins: [u8; ENCAPS_SEED_LEN]) -> Result<(), PQCPError>` — encapsulate to the serialized public key using caller-supplied randomness, writing ciphertext and shared secret; return `Err(PQCPError::Encapsulation)` on failure. This function does not perform public-key validation.
4. `crypto_kem_enc(ct: &mut [u8; CT_LEN], ss: &mut [u8; SS_LEN], pk: &[u8; PK_LEN], rng: &mut impl rand::CryptoRng) -> Result<(), PQCPError>` — as above but sampling the encapsulation seed internally. Only compiled under the `rand` feature.
5. `crypto_kem_dec(ss: &mut [u8; SS_LEN], ct: &[u8; CT_LEN], sk: &[u8; SK_LEN]) -> Result<(), PQCPError>` — decapsulate the ciphertext with the serialized private key, writing the shared secret; return `Err(PQCPError::Decapsulation)` on failure. This function does not perform private-key validation.

The observable contract: for a keypair produced by `crypto_kem_keypair_derand`, encapsulating with `crypto_kem_enc_derand` and then decapsulating the resulting ciphertext with `crypto_kem_dec` must yield a shared secret identical to the one produced during encapsulation.

Unpacked (struct) API. The crate exposes "unpacked" in-memory key types via `mlkem<variant>::unpacked` (with `init_key_pair()` and `init_public_key()` constructors, and a `public_key()` accessor on the key pair). Provide, in the same `mlkem<variant>::pqcp` module, functions that operate on those types. The length constants above are shared/re-exported so the struct API sees the same `PK_LEN`, `SK_LEN`, etc.:

1. `crypto_kem_keypair_derand_struct(key_pair: &mut <KeyPairUnpacked>, coins: [u8; KEYGEN_SEED_LEN])` — populate an unpacked key pair in place from a caller-supplied seed. Because the crate does not expose a standalone unpacked private-key type, the unpacked key pair stands in for the private key throughout this API.
2. `crypto_kem_keypair_struct(key_pair: &mut <KeyPairUnpacked>, rng: &mut impl rand::CryptoRng)` — as above, sampling the seed internally. Only under the `rand` feature.
3. `crypto_kem_marshal_pk(pk: &mut [u8; PK_LEN], pks: &<PublicKeyUnpacked>) -> Result<(), PQCPError>` — serialize an unpacked public key into the byte buffer.
4. `crypto_kem_marshal_sk(sk: &mut [u8; SK_LEN], sks: &<KeyPairUnpacked>) -> Result<(), PQCPError>` — serialize the private key held by an unpacked key pair into the byte buffer.
5. `crypto_kem_parse_pk(pk: &[u8; PK_LEN], pks: &mut <PublicKeyUnpacked>) -> Result<(), PQCPError>` — validate and deserialize a serialized public key into an unpacked public key; return `Err(PQCPError::InvalidPublicKey)` when validation fails.
6. `crypto_kem_parse_sk(sk: &[u8; SK_LEN], sks: &mut <KeyPairUnpacked>) -> Result<(), PQCPError>` — validate and deserialize a serialized private key into an unpacked key pair; return `Err(PQCPError::InvalidPrivateKey)` when validation fails.
7. `crypto_kem_enc_derand_struct(ct: &mut [u8; CT_LEN], ss: &mut [u8; SS_LEN], pk: &<PublicKeyUnpacked>, coins: [u8; ENCAPS_SEED_LEN]) -> Result<(), PQCPError>` — encapsulate against an unpacked public key with caller-supplied randomness. No public-key validation (the key was validated at parse time).
8. `crypto_kem_enc_struct(ct: &mut [u8; CT_LEN], ss: &mut [u8; SS_LEN], pk: &<PublicKeyUnpacked>, rng: &mut impl rand::CryptoRng) -> Result<(), PQCPError>` — as above, sampling internally. Only under the `rand` feature.
9. `crypto_kem_dec_struct(ss: &mut [u8; SS_LEN], ct: &[u8; CT_LEN], sk: &<KeyPairUnpacked>) -> Result<(), PQCPError>` — decapsulate against an unpacked key pair. No key validation.
10. `crypto_kem_sk_from_seed(key_pair: &mut <KeyPairUnpacked>, randomness: [u8; KEYGEN_SEED_LEN])` — an alias for `crypto_kem_keypair_derand_struct`.
11. `crypto_kem_pk_from_sk(pk: &mut <PublicKeyUnpacked>, sk: &<KeyPairUnpacked>)` — derive the unpacked public key from an unpacked key pair.

The observable contract for the struct API: generate an unpacked key pair with `crypto_kem_keypair_struct`; serialize its public key with `crypto_kem_marshal_pk` and re-parse the bytes with `crypto_kem_parse_pk`; encapsulate to the parsed unpacked public key with `crypto_kem_enc_derand_struct`; then decapsulate the ciphertext with `crypto_kem_dec_struct` against the original key pair — the decapsulated shared secret must equal the one produced during encapsulation.

Key validation policy. Per FIPS 203, per-operation key validation is not performed on encapsulation or decapsulation. Validation happens only when deserializing an unpacked key: `crypto_kem_parse_pk` validates the public key and `crypto_kem_parse_sk` validates the private key, each returning the corresponding `Invalid*` error on failure. The encapsulation and decapsulation entry points (packed and struct) assume already-validated inputs.

Naming and argument order. Function names, parameter names, and argument order follow the PQCP/mlkem-native reference C API. Do not rename or reorder them; the module path and the identifiers above are the integration surface callers compile against.

Constraints:
1. Introduce the `pqcp` Cargo feature; with the feature disabled the crate builds and behaves unchanged.
2. The randomness-sampling functions (`crypto_kem_keypair`, `crypto_kem_enc`, `crypto_kem_keypair_struct`, `crypto_kem_enc_struct`) are gated on the `rand` feature in addition to `pqcp`.
3. Do not modify the test files.
