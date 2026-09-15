OpenWhispr lets people bring their own key for a growing list of cloud LLM providers. Right now each provider's secret plumbing is spelled out several times over. The environment and secret manager has a getter and a setter for it, the main process IPC layer has a channel pair, the sandboxed renderer bridge has its own pair of functions, and the settings store has a key and a setter. Those copies drift apart. Onboarding OpenRouter made that obvious. Miss one and you get a key that saves but never loads, or a renderer bridge calling a channel the main process never registered.

The secret manager, the main process channels and the renderer bridge should all come from one shared definition of the providers, and OpenRouter should be onboarded through that definition as a first-class secret with storage of its own.

Put the shared definition in a new CommonJS module at `src/config/secretKeys.js` that exports a `BYOK_API_KEYS` array through `module.exports`, so the Electron main process and the Vite renderer can both require it. Each entry describes one provider through five non-empty string fields. `base` is the lowercase provider slug, and it yields the IPC channel pair `get-<base>-key` and `save-<base>-key`. `env` is the process environment variable holding the secret. `get` and `save` are the accessor method names. `storeKey` is the key the renderer's settings store persists that provider's secret under.

No two entries may share a `base`, an `env`, a `storeKey`, a `get` or a `save`. The array covers exactly eight providers and no others: OpenAI, Anthropic, Gemini, Groq, xAI, Mistral, OpenRouter and Tinfoil. What order they sit in is up to you. Name every field the way the seven providers already in the codebase are named, and let OpenRouter follow the same patterns.

Adding a provider has to become a one entry change. Once an entry is present, the secret manager has to expose that provider's `get` and `save` methods and the main process has to answer both of its channels, with no further per provider edit in either place. A ninth entry added to the array should work end to end on its own. That property is the whole point of the change, because it is what stops the copies drifting again.

For every entry the manager exposes the `get` named and `save` named methods, both functions. Saving a secret makes the matching getter return it and writes it to that provider's environment variable, and saving returns the same success object the hand written accessors returned. Saving an empty string clears the secret, so the getter returns an empty string and the environment variable is removed rather than left behind with a stale value.

The manifest's environment variables also count as secrets the manager tracks, the same way the non-BYOK ones already do, so a saved BYOK key is persisted with the rest of them rather than living only in memory.

Each registered channel delegates to that provider's accessor on the manager, so every channel the renderer bridge calls is one the main process really answers.

The settings store is the fourth copy and it has to stay honest too. It keeps every provider's secret under that provider's `storeKey` and offers a setter for it, named the way the existing ones are, and saving through that setter has to reach the same provider's `save` accessor rather than some other provider's.

The dictation overlay, notification and transcription-preview windows load a sandboxed `preload.js` that cannot import a local module at all, so it has to keep working without importing the shared definition. It still has to expose one getter and one setter per entry, under the manifest's own method names, each invoking that provider's channel.

Everything that works today has to keep working. The seven existing providers keep the accessor names, environment variables and IPC channels they use now, generated rather than renamed, and the secret accessors that are not part of this manifest are left alone.
