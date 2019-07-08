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
module hunt.pool.proxy.ProxiedKeyedObjectPool;

import java.util.NoSuchElementException;

import hunt.pool.KeyedObjectPool;
import hunt.pool.UsageTracking;

/**
 * Create a new keyed object pool where the pooled objects are wrapped in
 * proxies allowing better control of pooled objects and in particular the
 * prevention of the continued use of an object by a client after that client
 * returns the object to the pool.
 *
 * @param <K> type of the key
 * @param <V> type of the pooled object
 *
 */
class ProxiedKeyedObjectPool!(K, V) implements KeyedObjectPool!(K, V) {

    private final KeyedObjectPool!(K, V) pool;
    private final ProxySource!(V) proxySource;


    /**
     * Create a new proxied object pool.
     *
     * @param pool  The object pool to wrap
     * @param proxySource The source of the proxy objects
     */
    ProxiedKeyedObjectPool(final KeyedObjectPool!(K, V) pool,
            final ProxySource!(V) proxySource) {
        this.pool = pool;
        this.proxySource = proxySource;
    }


    @SuppressWarnings("unchecked")
    override
    V borrowObject(final K key)NoSuchElementException,
            IllegalStateException {
        UsageTracking!(V) usageTracking = null;
        if (pool instanceof UsageTracking) {
            usageTracking = (UsageTracking!(V)) pool;
        }
        final V pooledObject = pool.borrowObject(key);
        final V proxy = proxySource.createProxy(pooledObject, usageTracking);
        return proxy;
    }

    override
    void returnObject(final K key, final V proxy){
        final V pooledObject = proxySource.resolveProxy(proxy);
        pool.returnObject(key, pooledObject);
    }

    override
    void invalidateObject(final K key, final V proxy){
        final V pooledObject = proxySource.resolveProxy(proxy);
        pool.invalidateObject(key, pooledObject);
    }

    override
    void addObject(final K key)IllegalStateException,
            UnsupportedOperationException {
        pool.addObject(key);
    }

    override
    int getNumIdle(final K key) {
        return pool.getNumIdle(key);
    }

    override
    int getNumActive(final K key) {
        return pool.getNumActive(key);
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
    void clear(final K key){
        pool.clear(key);
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
        builder.append("ProxiedKeyedObjectPool [pool=");
        builder.append(pool);
        builder.append(", proxySource=");
        builder.append(proxySource);
        builder.append("]");
        return builder.toString();
    }
}
