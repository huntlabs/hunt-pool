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
module hunt.pool.BasePooledObjectFactory;

/**
 * A base implementation of <code>PoolableObjectFactory</code>.
 * <p>
 * All operations defined here are essentially no-op's.
 * <p>
 * This class is immutable, and therefore thread-safe
 *
 * @param <T> Type of element managed in this factory.
 *
 * @see PooledObjectFactory
 * @see BaseKeyedPooledObjectFactory
 *
 */
abstract class BasePooledObjectFactory(T) : BaseObject, PooledObjectFactory!(T) {
    /**
     * Creates an object instance, to be wrapped in a {@link PooledObject}.
     * <p>This method <strong>must</strong> support concurrent, multi-threaded
     * activation.</p>
     *
     * @return an instance to be served by the pool
     *
     * @throws Exception if there is a problem creating a new instance,
     *    this will be propagated to the code requesting an object.
     */
    abstract T create();

    /**
     * Wrap the provided instance with an implementation of
     * {@link PooledObject}.
     *
     * @param obj the instance to wrap
     *
     * @return The provided instance, wrapped by a {@link PooledObject}
     */
    abstract PooledObject!(T) wrap(T obj);

    override
    PooledObject!(T) makeObject(){
        return wrap(create());
    }

    /**
     *  No-op.
     *
     *  @param p ignored
     */
    override
    void destroyObject(PooledObject!(T) p)
{
        // The default implementation is a no-op.
    }

    /**
     * This implementation always returns {@code true}.
     *
     * @param p ignored
     *
     * @return {@code true}
     */
    override
    bool validateObject(PooledObject!(T) p) {
        return true;
    }

    /**
     *  No-op.
     *
     *  @param p ignored
     */
    override
    void activateObject(PooledObject!(T) p){
        // The default implementation is a no-op.
    }

    /**
     *  No-op.
     *
     * @param p ignored
     */
    override
    void passivateObject(PooledObject!(T) p)
{
        // The default implementation is a no-op.
    }
}
