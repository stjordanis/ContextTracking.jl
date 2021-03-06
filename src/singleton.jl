# Singleton implementation that is thread-safe unique per async tasks

const context_store = Dict{UInt, Context}()
const context_store_lock = Base.Threads.SpinLock()

"""
    context([id::UInt], [container])

Get a new context object.  If `id` is not passed, then return a global
context for the current thread/task.  The `container` must be an object that
supports `push!`, `getindex`, `empty!`, and `length` functions.
The default is `Dict{Any,Any}`.
"""
function context(; id = default_context_id(), container = Dict())
    try
        lock(context_store_lock)
        return get!(context_store, id) do
            Context(id, container)
        end
    finally
        unlock(context_store_lock)
    end
end

"""
    default_context_id()

Return a context name for the current thread.
"""
function default_context_id()
    # This id must be task/thread-unique.
    # Current method reuse the most significant byte from the current task's pointer address.
    # Limitations are:
    # 1. Up to 256 threads are supported
    # 2. Current task's pointer address may spill over to the MSB.
    return convert(UInt, Base.Threads.threadid()) << 56 +
           convert(UInt, pointer_from_objref(current_task()))
end

