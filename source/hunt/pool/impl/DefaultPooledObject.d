/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module hunt.pool.impl.DefaultPooledObject;

import hunt.pool.PooledObject;
import hunt.pool.PooledObjectState;
import hunt.pool.TrackedUse;

import java.io.PrintWriter;
import java.util.Deque;

/**
 * This wrapper is used to track the additional information, such as state, for
 * the pooled objects.
 * <p>
 * This class is intended to be thread-safe.
 * </p>
 *
 * @param <T> the type of object in the pool
 *
 */
class DefaultPooledObject!(T) implements PooledObject!(T) {

    private final T object;
    private PooledObjectState state = PooledObjectState.IDLE; // @GuardedBy("this") to ensure transitions are valid
    private final long createTime = DateTimeHelper.currentTimeMillis()();
    private volatile long lastBorrowTime = createTime;
    private volatile long lastUseTime = createTime;
    private volatile long lastReturnTime = createTime;
    private volatile boolean logAbandoned = false;
    private volatile CallStack borrowedBy = NoOpCallStack.INSTANCE;
    private volatile CallStack usedBy = NoOpCallStack.INSTANCE;
    private volatile long borrowedCount = 0;

    /**
     * Create a new instance that wraps the provided object so that the pool can
     * track the state of the pooled object.
     *
     * @param object The object to wrap
     */
    DefaultPooledObject(final T object) {
        this.object = object;
    }

    override
    T getObject() {
        return object;
    }

    override
    long getCreateTime() {
        return createTime;
    }

    override
    long getActiveTimeMillis() {
        // Take copies to avoid threading issues
        final long rTime = lastReturnTime;
        final long bTime = lastBorrowTime;

        if (rTime > bTime) {
            return rTime - bTime;
        }
        return DateTimeHelper.currentTimeMillis()() - bTime;
    }

    override
    long getIdleTimeMillis() {
        final long elapsed = DateTimeHelper.currentTimeMillis()() - lastReturnTime;
        // elapsed may be negative if:
        // - another thread updates lastReturnTime during the calculation window
        // - DateTimeHelper.currentTimeMillis()() is not monotonic (e.g. system time is set back)
        return elapsed >= 0 ? elapsed : 0;
    }

    override
    long getLastBorrowTime() {
        return lastBorrowTime;
    }

    override
    long getLastReturnTime() {
        return lastReturnTime;
    }

    /**
     * Get the number of times this object has been borrowed.
     * @return The number of times this object has been borrowed.
     */
    long getBorrowedCount() {
        return borrowedCount;
    }

    /**
     * Return an estimate of the last time this object was used.  If the class
     * of the pooled object implements {@link TrackedUse}, what is returned is
     * the maximum of {@link TrackedUse#getLastUsed()} and
     * {@link #getLastBorrowTime()}; otherwise this method gives the same
     * value as {@link #getLastBorrowTime()}.
     *
     * @return the last time this object was used
     */
    override
    long getLastUsedTime() {
        if (object instanceof TrackedUse) {
            return Math.max(((TrackedUse) object).getLastUsed(), lastUseTime);
        }
        return lastUseTime;
    }

    override
    int compareTo(final PooledObject!(T) other) {
        final long lastActiveDiff = this.getLastReturnTime() - other.getLastReturnTime();
        if (lastActiveDiff == 0) {
            // Make sure the natural ordering is broadly consistent with equals
            // although this will break down if distinct objects have the same
            // identity hash code.
            // see java.lang.Comparable Javadocs
            return System.identityHashCode(this) - System.identityHashCode(other);
        }
        // handle int overflow
        return (int)Math.min(Math.max(lastActiveDiff, Integer.MIN_VALUE), Integer.MAX_VALUE);
    }

    override
    String toString() {
        final StringBuilder result = new StringBuilder();
        result.append("Object: ");
        result.append(object.toString());
        result.append(", State: ");
        synchronized (this) {
            result.append(state.toString());
        }
        return result.toString();
        // TODO add other attributes
    }

    override
    synchronized boolean startEvictionTest() {
        if (state == PooledObjectState.IDLE) {
            state = PooledObjectState.EVICTION;
            return true;
        }

        return false;
    }

    override
    synchronized boolean endEvictionTest(
            final Deque!(PooledObject!(T)) idleQueue) {
        if (state == PooledObjectState.EVICTION) {
            state = PooledObjectState.IDLE;
            return true;
        } else if (state == PooledObjectState.EVICTION_RETURN_TO_HEAD) {
            state = PooledObjectState.IDLE;
            if (!idleQueue.offerFirst(this)) {
                // TODO - Should never happen
            }
        }

        return false;
    }

    /**
     * Allocates the object.
     *
     * @return {@code true} if the original state was {@link PooledObjectState#IDLE IDLE}
     */
    override
    synchronized boolean allocate() {
        if (state == PooledObjectState.IDLE) {
            state = PooledObjectState.ALLOCATED;
            lastBorrowTime = DateTimeHelper.currentTimeMillis()();
            lastUseTime = lastBorrowTime;
            borrowedCount++;
            if (logAbandoned) {
                borrowedBy.fillInStackTrace();
            }
            return true;
        } else if (state == PooledObjectState.EVICTION) {
            // TODO Allocate anyway and ignore eviction test
            state = PooledObjectState.EVICTION_RETURN_TO_HEAD;
            return false;
        }
        // TODO if validating and testOnBorrow == true then pre-allocate for
        // performance
        return false;
    }

    /**
     * Deallocates the object and sets it {@link PooledObjectState#IDLE IDLE}
     * if it is currently {@link PooledObjectState#ALLOCATED ALLOCATED}.
     *
     * @return {@code true} if the state was {@link PooledObjectState#ALLOCATED ALLOCATED}
     */
    override
    synchronized boolean deallocate() {
        if (state == PooledObjectState.ALLOCATED ||
                state == PooledObjectState.RETURNING) {
            state = PooledObjectState.IDLE;
            lastReturnTime = DateTimeHelper.currentTimeMillis()();
            borrowedBy.clear();
            return true;
        }

        return false;
    }

    /**
     * Sets the state to {@link PooledObjectState#INVALID INVALID}
     */
    override
    synchronized void invalidate() {
        state = PooledObjectState.INVALID;
    }

    override
    void use() {
        lastUseTime = DateTimeHelper.currentTimeMillis()();
        usedBy.fillInStackTrace();
    }

    override
    void printStackTrace(final PrintWriter writer) {
        boolean written = borrowedBy.printStackTrace(writer);
        written |= usedBy.printStackTrace(writer);
        if (written) {
            writer.flush();
        }
    }

    /**
     * Returns the state of this object.
     * @return state
     */
    override
    synchronized PooledObjectState getState() {
        return state;
    }

    /**
     * Marks the pooled object as abandoned.
     */
    override
    synchronized void markAbandoned() {
        state = PooledObjectState.ABANDONED;
    }

    /**
     * Marks the object as returning to the pool.
     */
    override
    synchronized void markReturning() {
        state = PooledObjectState.RETURNING;
    }

    override
    void setLogAbandoned(final boolean logAbandoned) {
        this.logAbandoned = logAbandoned;
    }

    /**
     * Configures the stack trace generation strategy based on whether or not fully
     * detailed stack traces are required. When set to false, abandoned logs may
     * only include caller class information rather than method names, line numbers,
     * and other normal metadata available in a full stack trace.
     *
     * @param requireFullStackTrace the new configuration setting for abandoned object
     *                              logging
     */
    // TODO: uncomment below in 3.0
    // override
    void setRequireFullStackTrace(final boolean requireFullStackTrace) {
        borrowedBy = CallStackUtils.newCallStack("'Pooled object created' " +
            "yyyy-MM-dd HH:mm:ss Z 'by the following code has not been returned to the pool:'",
            true, requireFullStackTrace);
        usedBy = CallStackUtils.newCallStack("The last code to use this object was:",
            false, requireFullStackTrace);
    }

}
