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

import hunt.pool.impl.CallStack;
import hunt.pool.impl.CallStackUtils;
import hunt.pool.impl.NoOpCallStack;

import hunt.pool.PooledObject;
import hunt.pool.PooledObjectState;
import hunt.pool.TrackedUse;

import hunt.collection;
import hunt.concurrency.atomic.AtomicHelper;
import hunt.Exceptions;
import hunt.text.StringBuilder;
import hunt.util.DateTime;



import std.algorithm;
import std.conv;

// import java.io.PrintWriter;
// import java.util.Deque;

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
class DefaultPooledObject(T) : PooledObject!(T) {

    private T object;
    private PooledObjectState state = PooledObjectState.IDLE; // @GuardedBy("this") to ensure transitions are valid
    private long createTime; // = DateTimeHelper.currentTimeMillis();
    private shared long lastBorrowTime; 
    private shared long lastUseTime;
    private shared long lastReturnTime;
    private shared bool logAbandoned = false;
    private CallStack borrowedBy;
    private CallStack usedBy;
    private shared long borrowedCount = 0;

    /**
     * Create a new instance that wraps the provided object so that the pool can
     * track the state of the pooled object.
     *
     * @param object The object to wrap
     */
    this(T object) {
        createTime = DateTimeHelper.currentTimeMillis();
        lastBorrowTime = createTime;
        lastUseTime = createTime;
        lastReturnTime = createTime;
        borrowedBy = NoOpCallStack.INSTANCE;    
        usedBy = NoOpCallStack.INSTANCE;    
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
        long rTime = lastReturnTime;
        long bTime = lastBorrowTime;

        if (rTime > bTime) {
            return rTime - bTime;
        }
        return DateTimeHelper.currentTimeMillis() - bTime;
    }

    override
    long getIdleTimeMillis() {
        long elapsed = DateTimeHelper.currentTimeMillis() - lastReturnTime;
        // elapsed may be negative if:
        // - another thread updates lastReturnTime during the calculation window
        // - DateTimeHelper.currentTimeMillis() is not monotonic (e.g. system time is set back)
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
        TrackedUse tu = cast(TrackedUse) object;
        if (tu !is null) {
            return max(tu.getLastUsed(), lastUseTime);
        }
        return lastUseTime;
    }

    override
    int opCmp(IPooledObject other) {
        long lastActiveDiff = this.getLastReturnTime() - other.getLastReturnTime();
        if (lastActiveDiff == 0) {
            // Make sure the natural ordering is broadly consistent with equals
            // although this will break down if distinct objects have the same
            // identity hash code.
            // see java.lang.Comparable Javadocs
            // return System.identityHashCode(this) - System.identityHashCode(other);
            return cast(int)(this.toHash() - other.toHash());
        }
        // handle int overflow
        return cast(int)min(max(lastActiveDiff, int.min), int.max);
    }

    override
    string toString() {
        StringBuilder result = new StringBuilder();
        result.append("Object: ");
        result.append(object.toString());
        result.append(", State: ");
        synchronized (this) {
            result.append(state.to!string());
        }
        return result.toString();
        // TODO add other attributes
    }

    override
    bool startEvictionTest() { // synchronized 
        if (state == PooledObjectState.IDLE) {
            state = PooledObjectState.EVICTION;
            return true;
        }

        return false;
    }

    override
    bool endEvictionTest( // synchronized 
            Deque!(IPooledObject) idleQueue) {
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
    bool allocate() { // synchronized
        if (state == PooledObjectState.IDLE) {
            state = PooledObjectState.ALLOCATED;
            lastBorrowTime = DateTimeHelper.currentTimeMillis();
            lastUseTime = lastBorrowTime;
            borrowedCount.increment();
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
    bool deallocate() { // synchronized
        if (state == PooledObjectState.ALLOCATED ||
                state == PooledObjectState.RETURNING) {
            state = PooledObjectState.IDLE;
            lastReturnTime = DateTimeHelper.currentTimeMillis();
            borrowedBy.clear();
            return true;
        }

        return false;
    }

    /**
     * Sets the state to {@link PooledObjectState#INVALID INVALID}
     */
    override
    void invalidate() { // synchronized
        state = PooledObjectState.INVALID;
    }

    override
    void use() {
        lastUseTime = DateTimeHelper.currentTimeMillis();
        usedBy.fillInStackTrace();
    }

    // override
    // void printStackTrace(PrintWriter writer) {
    //     bool written = borrowedBy.printStackTrace(writer);
    //     written |= usedBy.printStackTrace(writer);
    //     if (written) {
    //         writer.flush();
    //     }
    // }

    /**
     * Returns the state of this object.
     * @return state
     */
    override
    PooledObjectState getState() { // synchronized
        return state;
    }

    /**
     * Marks the pooled object as abandoned.
     */
    override
    void markAbandoned() { // synchronized
        state = PooledObjectState.ABANDONED;
    }

    /**
     * Marks the object as returning to the pool.
     */
    override
    void markReturning() { // synchronized
        state = PooledObjectState.RETURNING;
    }

    override
    void setLogAbandoned(bool logAbandoned) {
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
    void setRequireFullStackTrace(bool requireFullStackTrace) {
        implementationMissing(false);
        // borrowedBy = CallStackUtils.newCallStack("'Pooled object created' " ~
        //     "yyyy-MM-dd HH:mm:ss Z 'by the following code has not been returned to the pool:'",
        //     true, requireFullStackTrace);
        // usedBy = CallStackUtils.newCallStack("The last code to use this object was:",
        //     false, requireFullStackTrace);
    }

    
    bool opEquals(IPooledObject obj) {
        return opEquals(cast(Object) obj);
    }

    override bool opEquals(Object obj) {
        return super.opEquals(obj);
    }

}
