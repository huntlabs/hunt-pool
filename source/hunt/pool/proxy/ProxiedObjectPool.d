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
module hunt.pool.proxy.ProxiedObjectPool;

import java.util.NoSuchElementException;

import hunt.pool.ObjectPool;
import hunt.pool.UsageTracking;

/**
 * Create a new object pool where the pooled objects are wrapped in proxies
 * allowing better control of pooled objects and in particular the prevention
 * of the continued use of an object by a client after that client returns the
 * object to the pool.
 *
 * @param <T> type of the pooled object
 *
 */
class ProxiedObjectPool!(T) implements ObjectPool!(T) {

    private final ObjectPool!(T) pool;
    private final ProxySource!(T) proxySource;


    /**
     * Create a new proxied object pool.
     *
     * @param pool  The object pool to wrap
     * @param proxySource The source of the proxy objects
     */
    ProxiedObjectPool(final ObjectPool!(T) pool, final ProxySource!(T) proxySource) {
        this.pool = pool;
        this.proxySource = proxySource;
    }


    // --------------------------------------------------- ObjectPool!(T) methods

    @SuppressWarnings("unchecked")
    override
    T borrowObject()NoSuchElementException,
            IllegalStateException {
        UsageTracking!(T) usageTracking = null;
        if (pool instanceof UsageTracking) {
            usageTracking = (UsageTracking!(T)) pool;
        }
        final T pooledObject = pool.borrowObject();
        final T proxy = proxySource.createProxy(pooledObject, usageTracking);
        return proxy;
    }


    override
    void returnObject(final T proxy){
        final T pooledObject = proxySource.resolveProxy(proxy);
        pool.returnObject(pooledObject);
    }


    override
    void invalidateObject(final T proxy){
        final T pooledObject = proxySource.resolveProxy(proxy);
        pool.invalidateObject(pooledObject);
    }


    override
    void addObject()IllegalStateException,
            UnsupportedOperationException {
        pool.addObject();
    }


    override
    int getNumIdle() {
        return pool.getNumIdle();
    }


    override
    int getNumActive() {
        return pool.getNumActive();
    }


    override
    void clear(){
        pool.clear();
    }


    override
    void close() {
        pool.close();
    }


    /**
     */
    override
    String toString() {
        final StringBuilder builder = new StringBuilder();
        builder.append("ProxiedObjectPool [pool=");
        builder.append(pool);
        builder.append(", proxySource=");
        builder.append(proxySource);
        builder.append("]");
        return builder.toString();
    }
}
