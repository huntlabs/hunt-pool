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
module hunt.pool.BaseObjectPool;

/**
 * A simple base implementation of {@link ObjectPool}.
 * Optional operations are implemented to either do nothing, return a value
 * indicating it is unsupported or throw {@link UnsupportedOperationException}.
 * <p>
 * This class is intended to be thread-safe.
 *
 * @param <T> Type of element pooled in this pool.
 *
 */
abstract class BaseObjectPool(T) : BaseObject, ObjectPool!(T) {

    override
    abstract T borrowObject();

    override
    abstract void returnObject(T obj);

    override
    abstract void invalidateObject(T obj);

    /**
     * Not supported in this base implementation.
     *
     * @return a negative value.
     */
    override
    int getNumIdle() {
        return -1;
    }

    /**
     * Not supported in this base implementation.
     *
     * @return a negative value.
     */
    override
    int getNumActive() {
        return -1;
    }

    /**
     * Not supported in this base implementation.
     *
     * @throws UnsupportedOperationException if the pool does not implement this
     *          method
     */
    override
    void clear(){
        throw new UnsupportedOperationException();
    }

    /**
     * Not supported in this base implementation. Subclasses should override
     * this behavior.
     *
     * @throws UnsupportedOperationException if the pool does not implement this
     *          method
     */
    override
    void addObject(){
        throw new UnsupportedOperationException();
    }

    /**
     * {@inheritDoc}
     * <p>
     * This affects the behavior of <code>isClosed</code> and
     * <code>assertOpen</code>.
     * </p>
     */
    override
    void close() {
        closed = true;
    }

    /**
     * Has this pool instance been closed.
     *
     * @return <code>true</code> when this pool has been closed.
     */
    bool isClosed() {
        return closed;
    }

    /**
     *<code>IllegalStateException</code> when this pool has been
     * closed.
     *
     * @throws IllegalStateException when this pool has been closed.
     *
     * @see #isClosed()
     */
    protected void assertOpen(){
        if (isClosed()) {
            throw new IllegalStateException("Pool not open");
        }
    }

    private bool closed = false;

    override
    protected void toStringAppendFields(StringBuilder builder) {
        builder.append("closed=");
        builder.append(closed);
    }
}
