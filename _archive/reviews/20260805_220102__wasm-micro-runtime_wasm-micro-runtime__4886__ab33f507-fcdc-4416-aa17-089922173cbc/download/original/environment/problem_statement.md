WAMR exposes `wasm_runtime_malloc` for runtime allocations, but there is no way to ask for memory on a particular alignment boundary. Callers that need an aligned buffer, say for SIMD data or a hardware DMA region, have to over-allocate and align by hand today. We want aligned allocation handled properly inside the EMS pool allocator and exposed as a public runtime API.

Add a public entry point `wasm_runtime_aligned_alloc(unsigned int size, unsigned int alignment)`, exported with `WASM_RUNTIME_API_EXTERN` linkage like the runtime's other public allocation functions so an embedder can call it. It hands back a pointer to at least `size` bytes whose address is a multiple of `alignment`, or `NULL` when the request cannot be met.

Underneath it the memory-allocator layer needs a matching entry point `mem_allocator_malloc_aligned(mem_allocator_t allocator, uint32 size, uint32 alignment)`, which is what the public function calls in POOL mode. It belongs to the same allocator API that ordinary allocation already goes through, so anything that can already reach `mem_allocator_malloc` can reach this too.

Getting an aligned block back means the pointer no longer sits where the allocator's own bookkeeping would normally put it, so the allocator has to be able to tell an aligned block from an ordinary one when that block later comes back to be freed or reallocated. How you record that is up to you.

Acceptance criteria:

1. Valid requests at the allocator layer. For a power-of-two alignment from 8 bytes up to the system page size, with `size` an integral multiple of that alignment, `mem_allocator_malloc_aligned` returns a non-NULL pointer aligned to `alignment`.

2. Small alignments. An alignment of 1, 2 or 4 is raised to the 8-byte minimum rather than rejected, and the request then succeeds on the same terms as any other alignment, meaning the size has to be a multiple of that 8-byte minimum.

3. Rejected requests. An alignment of 0, an alignment that is not a power of two, or a `size` that is not an integral multiple of the alignment all return NULL.

4. Ordinary allocation is untouched. `mem_allocator_malloc` still returns an 8-byte-aligned block, and `mem_allocator_realloc` on such a block still works and preserves the existing contents.

5. Realloc tells the two apart. Reallocation cannot preserve alignment, so `mem_allocator_realloc` refuses any block that came from `mem_allocator_malloc_aligned`, returning NULL and leaving the original block valid and freeable, while a block from `mem_allocator_malloc` reallocates normally. That difference has to hold no matter how the two kinds are interleaved. `wasm_runtime_realloc` behaves the same way.

6. Both kinds are ordinary value objects. `obj_to_hmu` resolves a pointer from either path to its header, the header type is `HMU_VO`, and the recorded size is at least the size that was asked for.

7. Freeing is safe and repeatable. `mem_allocator_free` handles an aligned pointer, and calling it again on a pointer that has already been freed, ordinary or aligned, does not crash the process.

8. Interleaving works. Ordinary and aligned allocations can be interleaved, each keeps its own alignment, and they can be freed in any order.

9. Public API, valid case. In POOL memory-allocator mode `wasm_runtime_aligned_alloc` returns a pointer aligned as asked for alignments from 8 to 256 bytes, and `wasm_runtime_free` releases it.

10. Public API, zero alignment. The call returns NULL.

11. Public API, zero size. The call allocates the smallest multiple of the alignment, so it still returns an aligned and usable block.

12. Public API, memory mode. Aligned allocation is only supported in POOL mode. Both of the other allocator modes, the system allocator and a user-supplied allocator, return NULL, while ordinary allocation through them keeps working.

13. Absurd sizes fail cleanly. A request far larger than the pool could ever satisfy, up to sizes near the limit of `size_t`, returns NULL rather than crashing or wrapping around, for both ordinary and aligned allocation.

14. Exhaustion and recovery. Allocating repeatedly until the pool runs dry returns NULL at that point rather than crashing, for ordinary, aligned and mixed sequences, and aligned blocks stay aligned right up to exhaustion. Once those blocks are freed the allocator is usable again and further allocations of either kind succeed.
