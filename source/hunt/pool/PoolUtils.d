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
module hunt.pool.PoolUtils;

// import java.util.Collection;
// import java.util.Collections;
// import java.util.HashMap;
// import java.util.Iterator;
// import java.util.Map;
// import java.util.NoSuchElementException;
// import java.util.Timer;
// import java.util.TimerTask;
// import java.util.concurrent.locks.ReentrantReadWriteLock;
// import java.util.concurrent.locks.ReentrantReadWriteLock.ReadLock;
// import java.util.concurrent.locks.ReentrantReadWriteLock.WriteLock;

import hunt.collection;
import hunt.Exceptions;

import core.sync.rwmutex;

/**
 * This class consists exclusively of static methods that operate on or return
 * ObjectPool or KeyedObjectPool related interfaces.
 *
 */
class PoolUtils {

    private enum string MSG_FACTOR_NEGATIVE = "factor must be positive.";
    private enum string MSG_MIN_IDLE = "minIdle must be non-negative.";
    private enum string MSG_NULL_KEY = "key must not be null.";
    private enum string MSG_NULL_KEYED_POOL = "keyedPool must not be null.";
    private enum string MSG_NULL_KEYS = "keys must not be null.";
    private enum string MSG_NULL_POOL = "pool must not be null.";

    /**
     * Timer used to periodically check pools idle object count. Because a
     * {@link Timer} creates a {@link Thread}, an IODH is used.
     */
    // static class TimerHolder {
    //     static Timer MIN_IDLE_TIMER = new Timer(true);
    // }

    /**
     * PoolUtils instances should NOT be constructed in standard programming.
     * Instead, the class should be used procedurally: PoolUtils.adapt(aPool);.
     * This constructor is public to permit tools that require a JavaBean
     * instance to operate.
     */
    this() {
    }

    /**
     * Should the supplied Throwable be re-thrown (eg if it is an instance of
     * one of the Throwables that should never be swallowed). Used by the pool
     * error handling for operations that throw exceptions that normally need to
     * be ignored.
     *
     * @param t
     *            The Throwable to check
     * @throws ThreadDeath
     *             if that is passed in
     * @throws VirtualMachineError
     *             if that is passed in
     */
    static void checkRethrow(Throwable t) {
        ThreadDeath td = cast(ThreadDeath) t;
        if (td !is null) {
            throw td;
        }
        // if (t instanceof VirtualMachineError) {
        //     throw (VirtualMachineError) t;
        // }
        // All other instances of Throwable will be silently swallowed
    }

    /**
     * Periodically check the idle object count for the pool. At most one idle
     * object will be added per period. If there is an exception when calling
     * {@link ObjectPool#addObject()} then no more checks will be performed.
     *
     * @param pool
     *            the pool to check periodically.
     * @param minIdle
     *            if the {@link ObjectPool#getNumIdle()} is less than this then
     *            add an idle object.
     * @param period
     *            the frequency to check the number of idle objects in a pool,
     *            see {@link Timer#schedule(TimerTask, long, long)}.
     * @param <T> the type of objects in the pool
     * @return the {@link TimerTask} that will periodically check the pools idle
     *         object count.
     * @throws IllegalArgumentException
     *             when <code>pool</code> is <code>null</code> or when
     *             <code>minIdle</code> is negative or when <code>period</code>
     *             isn't valid for {@link Timer#schedule(TimerTask, long, long)}
     */
    static TimerTask checkMinIdle(T)(ObjectPool!(T) pool,
            int minIdle, long period) {
        if (pool is null) {
            throw new IllegalArgumentException(MSG_NULL_KEYED_POOL);
        }
        if (minIdle < 0) {
            throw new IllegalArgumentException(MSG_MIN_IDLE);
        }
        TimerTask task = new ObjectPoolMinIdleTimerTask!T(pool, minIdle);
        getMinIdleTimer().schedule(task, 0L, period);
        return task;
    }

    /**
     * Periodically check the idle object count for the key in the keyedPool. At
     * most one idle object will be added per period. If there is an exception
     * when calling {@link KeyedObjectPool#addObject(Object)} then no more
     * checks for that key will be performed.
     *
     * @param keyedPool
     *            the keyedPool to check periodically.
     * @param key
     *            the key to check the idle count of.
     * @param minIdle
     *            if the {@link KeyedObjectPool#getNumIdle(Object)} is less than
     *            this then add an idle object.
     * @param period
     *            the frequency to check the number of idle objects in a
     *            keyedPool, see {@link Timer#schedule(TimerTask, long, long)}.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return the {@link TimerTask} that will periodically check the pools idle
     *         object count.
     * @throws IllegalArgumentException
     *             when <code>keyedPool</code>, <code>key</code> is
     *             <code>null</code> or when <code>minIdle</code> is negative or
     *             when <code>period</code> isn't valid for
     *             {@link Timer#schedule(TimerTask, long, long)}.
     */
    static TimerTask checkMinIdle(K, V)(
            KeyedObjectPool!(K, V) keyedPool, K key,
            int minIdle, long period) {
        if (keyedPool is null) {
            throw new IllegalArgumentException(MSG_NULL_KEYED_POOL);
        }
        if (key is null) {
            throw new IllegalArgumentException(MSG_NULL_KEY);
        }
        if (minIdle < 0) {
            throw new IllegalArgumentException(MSG_MIN_IDLE);
        }
        TimerTask task = new KeyedObjectPoolMinIdleTimerTask!(K, V)(
                keyedPool, key, minIdle);
        getMinIdleTimer().schedule(task, 0L, period);
        return task;
    }

    /**
     * Periodically check the idle object count for each key in the
     * <code>Collection</code> <code>keys</code> in the keyedPool. At most one
     * idle object will be added per period.
     *
     * @param keyedPool
     *            the keyedPool to check periodically.
     * @param keys
     *            a collection of keys to check the idle object count.
     * @param minIdle
     *            if the {@link KeyedObjectPool#getNumIdle(Object)} is less than
     *            this then add an idle object.
     * @param period
     *            the frequency to check the number of idle objects in a
     *            keyedPool, see {@link Timer#schedule(TimerTask, long, long)}.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return a {@link Map} of key and {@link TimerTask} pairs that will
     *         periodically check the pools idle object count.
     * @throws IllegalArgumentException
     *             when <code>keyedPool</code>, <code>keys</code>, or any of the
     *             values in the collection is <code>null</code> or when
     *             <code>minIdle</code> is negative or when <code>period</code>
     *             isn't valid for {@link Timer#schedule(TimerTask, long, long)}
     *             .
     * @see #checkMinIdle(KeyedObjectPool, Object, int, long)
     */
    static Map!(K, TimerTask) checkMinIdle(K, V)(
            KeyedObjectPool!(K, V) keyedPool, Collection!(K) keys,
            int minIdle, long period)
{
        if (keys is null) {
            throw new IllegalArgumentException(MSG_NULL_KEYS);
        }
        Map!(K, TimerTask) tasks = new HashMap!(K, V)(keys.size());
        Iterator!(K) iter = keys.iterator();
        while (iter.hasNext()) {
            K key = iter.next();
            TimerTask task = checkMinIdle(keyedPool, key, minIdle, period);
            tasks.put(key, task);
        }
        return tasks;
    }

    /**
     * Calls {@link ObjectPool#addObject()} on <code>pool</code> <code>count</code>
     * number of times.
     *
     * @param pool
     *            the pool to prefill.
     * @param count
     *            the number of idle objects to add.
     * @param <T> the type of objects in the pool
     * @throws Exception
     *             when {@link ObjectPool#addObject()} fails.
     * @throws IllegalArgumentException
     *             when <code>pool</code> is <code>null</code>.
     */
    static void prefill(T)(ObjectPool!(T) pool, int count)
{
        if (pool is null) {
            throw new IllegalArgumentException(MSG_NULL_POOL);
        }
        for (int i = 0; i < count; i++) {
            pool.addObject();
        }
    }

    /**
     * Calls {@link KeyedObjectPool#addObject(Object)} on <code>keyedPool</code> with
     * <code>key</code> <code>count</code> number of times.
     *
     * @param keyedPool
     *            the keyedPool to prefill.
     * @param key
     *            the key to add objects for.
     * @param count
     *            the number of idle objects to add for <code>key</code>.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @throws Exception
     *             when {@link KeyedObjectPool#addObject(Object)} fails.
     * @throws IllegalArgumentException
     *             when <code>keyedPool</code> or <code>key</code> is
     *             <code>null</code>.
     */
    static void prefill(K, V)(KeyedObjectPool!(K, V) keyedPool,
            K key, int count) {
        if (keyedPool is null) {
            throw new IllegalArgumentException(MSG_NULL_KEYED_POOL);
        }
        if (key is null) {
            throw new IllegalArgumentException(MSG_NULL_KEY);
        }
        for (int i = 0; i < count; i++) {
            keyedPool.addObject(key);
        }
    }

    /**
     * Calls {@link KeyedObjectPool#addObject(Object)} on <code>keyedPool</code> with each
     * key in <code>keys</code> for <code>count</code> number of times. This has
     * the same effect as calling {@link #prefill(KeyedObjectPool, Object, int)}
     * for each key in the <code>keys</code> collection.
     *
     * @param keyedPool
     *            the keyedPool to prefill.
     * @param keys
     *            {@link Collection} of keys to add objects for.
     * @param count
     *            the number of idle objects to add for each <code>key</code>.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @throws Exception
     *             when {@link KeyedObjectPool#addObject(Object)} fails.
     * @throws IllegalArgumentException
     *             when <code>keyedPool</code>, <code>keys</code>, or any value
     *             in <code>keys</code> is <code>null</code>.
     * @see #prefill(KeyedObjectPool, Object, int)
     */
    static void prefill(K, V)(KeyedObjectPool!(K, V) keyedPool,
            Collection!(K) keys, int count) {
        if (keys is null) {
            throw new IllegalArgumentException(MSG_NULL_KEYS);
        }
        Iterator!(K) iter = keys.iterator();
        while (iter.hasNext()) {
            prefill(keyedPool, iter.next(), count);
        }
    }

    /**
     * Returns a synchronized (thread-safe) ObjectPool backed by the specified
     * ObjectPool.
     * <p>
     * <b>Note:</b> This should not be used on pool implementations that already
     * provide proper synchronization such as the pools provided in the Commons
     * Pool library. Wrapping a pool that {@link #wait() waits} for poolable
     * objects to be returned before allowing another one to be borrowed with
     * another layer of synchronization will cause liveliness issues or a
     * deadlock.
     * </p>
     *
     * @param pool
     *            the ObjectPool to be "wrapped" in a synchronized ObjectPool.
     * @param <T> the type of objects in the pool
     * @return a synchronized view of the specified ObjectPool.
     */
    static ObjectPool!(T) synchronizedPool(T)(ObjectPool!(T) pool) {
        if (pool is null) {
            throw new IllegalArgumentException(MSG_NULL_POOL);
        }
        /*
         * assert !(pool instanceof GenericObjectPool) :
         * "GenericObjectPool is already thread-safe"; assert !(pool instanceof
         * SoftReferenceObjectPool) :
         * "SoftReferenceObjectPool is already thread-safe"; assert !(pool
         * instanceof StackObjectPool) :
         * "StackObjectPool is already thread-safe"; assert
         * !"org.apache.commons.pool.composite.CompositeObjectPool"
         *  == typeid(pool).name :
         * "CompositeObjectPools are already thread-safe";
         */
        return new SynchronizedObjectPool!T(pool);
    }

    /**
     * Returns a synchronized (thread-safe) KeyedObjectPool backed by the
     * specified KeyedObjectPool.
     * <p>
     * <b>Note:</b> This should not be used on pool implementations that already
     * provide proper synchronization such as the pools provided in the Commons
     * Pool library. Wrapping a pool that {@link #wait() waits} for poolable
     * objects to be returned before allowing another one to be borrowed with
     * another layer of synchronization will cause liveliness issues or a
     * deadlock.
     * </p>
     *
     * @param keyedPool
     *            the KeyedObjectPool to be "wrapped" in a synchronized
     *            KeyedObjectPool.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return a synchronized view of the specified KeyedObjectPool.
     */
    static KeyedObjectPool!(K, V) synchronizedPool(K, V)(
            KeyedObjectPool!(K, V) keyedPool) {
        /*
         * assert !(keyedPool instanceof GenericKeyedObjectPool) :
         * "GenericKeyedObjectPool is already thread-safe"; assert !(keyedPool
         * instanceof StackKeyedObjectPool) :
         * "StackKeyedObjectPool is already thread-safe"; assert
         * !"org.apache.commons.pool.composite.CompositeKeyedObjectPool"
         *  == typeid(keyedPool).name :
         * "CompositeKeyedObjectPools are already thread-safe";
         */
        return new SynchronizedKeyedObjectPool!(K, V)(keyedPool);
    }

    /**
     * Returns a synchronized (thread-safe) PooledObjectFactory backed by the
     * specified PooledObjectFactory.
     *
     * @param factory
     *            the PooledObjectFactory to be "wrapped" in a synchronized
     *            PooledObjectFactory.
     * @param <T> the type of objects in the pool
     * @return a synchronized view of the specified PooledObjectFactory.
     */
    static PooledObjectFactory!(T) synchronizedPooledFactory(T)(
            PooledObjectFactory!(T) factory) {
        return new SynchronizedPooledObjectFactory!T(factory);
    }

    /**
     * Returns a synchronized (thread-safe) KeyedPooledObjectFactory backed by
     * the specified KeyedPoolableObjectFactory.
     *
     * @param keyedFactory
     *            the KeyedPooledObjectFactory to be "wrapped" in a
     *            synchronized KeyedPooledObjectFactory.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return a synchronized view of the specified KeyedPooledObjectFactory.
     */
    static KeyedPooledObjectFactory!(K, V) synchronizedKeyedPooledFactory(K, V)(
            KeyedPooledObjectFactory!(K, V) keyedFactory) {
        return new SynchronizedKeyedPooledObjectFactory!(K, V)(keyedFactory);
    }

    /**
     * Returns a pool that adaptively decreases its size when idle objects are
     * no longer needed. This is intended as an always thread-safe alternative
     * to using an idle object evictor provided by many pool implementations.
     * This is also an effective way to shrink FIFO ordered pools that
     * experience load spikes.
     *
     * @param pool
     *            the ObjectPool to be decorated so it shrinks its idle count
     *            when possible.
     * @param <T> the type of objects in the pool
     * @return a pool that adaptively decreases its size when idle objects are
     *         no longer needed.
     * @see #erodingPool(ObjectPool, float)
     */
    static ObjectPool!(T) erodingPool(T)(ObjectPool!(T) pool) {
        return erodingPool(pool, 1f);
    }

    /**
     * Returns a pool that adaptively decreases its size when idle objects are
     * no longer needed. This is intended as an always thread-safe alternative
     * to using an idle object evictor provided by many pool implementations.
     * This is also an effective way to shrink FIFO ordered pools that
     * experience load spikes.
     * <p>
     * The factor parameter provides a mechanism to tweak the rate at which the
     * pool tries to shrink its size. Values between 0 and 1 cause the pool to
     * try to shrink its size more often. Values greater than 1 cause the pool
     * to less frequently try to shrink its size.
     * </p>
     *
     * @param pool
     *            the ObjectPool to be decorated so it shrinks its idle count
     *            when possible.
     * @param factor
     *            a positive value to scale the rate at which the pool tries to
     *            reduce its size. If 0 &lt; factor &lt; 1 then the pool
     *            shrinks more aggressively. If 1 &lt; factor then the pool
     *            shrinks less aggressively.
     * @param <T> the type of objects in the pool
     * @return a pool that adaptively decreases its size when idle objects are
     *         no longer needed.
     * @see #erodingPool(ObjectPool)
     */
    static ObjectPool!(T) erodingPool(T)(ObjectPool!(T) pool,
            float factor) {
        if (pool is null) {
            throw new IllegalArgumentException(MSG_NULL_POOL);
        }
        if (factor <= 0f) {
            throw new IllegalArgumentException(MSG_FACTOR_NEGATIVE);
        }
        return new ErodingObjectPool!T(pool, factor);
    }

    /**
     * Returns a pool that adaptively decreases its size when idle objects are
     * no longer needed. This is intended as an always thread-safe alternative
     * to using an idle object evictor provided by many pool implementations.
     * This is also an effective way to shrink FIFO ordered pools that
     * experience load spikes.
     *
     * @param keyedPool
     *            the KeyedObjectPool to be decorated so it shrinks its idle
     *            count when possible.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return a pool that adaptively decreases its size when idle objects are
     *         no longer needed.
     * @see #erodingPool(KeyedObjectPool, float)
     * @see #erodingPool(KeyedObjectPool, float, bool)
     */
    static KeyedObjectPool!(K, V) erodingPool(K, V)(
            KeyedObjectPool!(K, V) keyedPool) {
        return erodingPool(keyedPool, 1f);
    }

    /**
     * Returns a pool that adaptively decreases its size when idle objects are
     * no longer needed. This is intended as an always thread-safe alternative
     * to using an idle object evictor provided by many pool implementations.
     * This is also an effective way to shrink FIFO ordered pools that
     * experience load spikes.
     * <p>
     * The factor parameter provides a mechanism to tweak the rate at which the
     * pool tries to shrink its size. Values between 0 and 1 cause the pool to
     * try to shrink its size more often. Values greater than 1 cause the pool
     * to less frequently try to shrink its size.
     * </p>
     *
     * @param keyedPool
     *            the KeyedObjectPool to be decorated so it shrinks its idle
     *            count when possible.
     * @param factor
     *            a positive value to scale the rate at which the pool tries to
     *            reduce its size. If 0 &lt; factor &lt; 1 then the pool
     *            shrinks more aggressively. If 1 &lt; factor then the pool
     *            shrinks less aggressively.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return a pool that adaptively decreases its size when idle objects are
     *         no longer needed.
     * @see #erodingPool(KeyedObjectPool, float, bool)
     */
    static KeyedObjectPool!(K, V) erodingPool(K, V)(
            KeyedObjectPool!(K, V) keyedPool, float factor) {
        return erodingPool(keyedPool, factor, false);
    }

    /**
     * Returns a pool that adaptively decreases its size when idle objects are
     * no longer needed. This is intended as an always thread-safe alternative
     * to using an idle object evictor provided by many pool implementations.
     * This is also an effective way to shrink FIFO ordered pools that
     * experience load spikes.
     * <p>
     * The factor parameter provides a mechanism to tweak the rate at which the
     * pool tries to shrink its size. Values between 0 and 1 cause the pool to
     * try to shrink its size more often. Values greater than 1 cause the pool
     * to less frequently try to shrink its size.
     * </p>
     * <p>
     * The perKey parameter determines if the pool shrinks on a whole pool basis
     * or a per key basis. When perKey is false, the keys do not have an effect
     * on the rate at which the pool tries to shrink its size. When perKey is
     * true, each key is shrunk independently.
     * </p>
     *
     * @param keyedPool
     *            the KeyedObjectPool to be decorated so it shrinks its idle
     *            count when possible.
     * @param factor
     *            a positive value to scale the rate at which the pool tries to
     *            reduce its size. If 0 &lt; factor &lt; 1 then the pool
     *            shrinks more aggressively. If 1 &lt; factor then the pool
     *            shrinks less aggressively.
     * @param perKey
     *            when true, each key is treated independently.
     * @param <K> the type of the pool key
     * @param <V> the type of pool entries
     * @return a pool that adaptively decreases its size when idle objects are
     *         no longer needed.
     * @see #erodingPool(KeyedObjectPool)
     * @see #erodingPool(KeyedObjectPool, float)
     */
    static KeyedObjectPool!(K, V) erodingPool(K, V)(
            KeyedObjectPool!(K, V) keyedPool, float factor, bool perKey) {
        if (keyedPool is null) {
            throw new IllegalArgumentException(MSG_NULL_KEYED_POOL);
        }
        if (factor <= 0f) {
            throw new IllegalArgumentException(MSG_FACTOR_NEGATIVE);
        }
        if (perKey) {
            return new ErodingPerKeyKeyedObjectPool!(K, V)(keyedPool, factor);
        }
        return new ErodingKeyedObjectPool!(K, V)(keyedPool, factor);
    }

    /**
     * Gets the <code>Timer</code> for checking keyedPool's idle count.
     *
     * @return the {@link Timer} for checking keyedPool's idle count.
     */
    private static Timer getMinIdleTimer() {
        return TimerHolder.MIN_IDLE_TIMER;
    }

    /**
     * Timer task that adds objects to the pool until the number of idle
     * instances reaches the configured minIdle. Note that this is not the same
     * as the pool's minIdle setting.
     *
     * @param <T> type of objects in the pool
     */
    private static class ObjectPoolMinIdleTimerTask(T) : TimerTask {

        /** Minimum number of idle instances. Not the same as pool.getMinIdle(). */
        private int minIdle;

        /** Object pool */
        private ObjectPool!(T) pool;

        /**
         * Create a new ObjectPoolMinIdleTimerTask for the given pool with the
         * given minIdle setting.
         *
         * @param pool
         *            object pool
         * @param minIdle
         *            number of idle instances to maintain
         * @throws IllegalArgumentException
         *             if the pool is null
         */
        this(ObjectPool!(T) pool, int minIdle) {
            if (pool is null) {
                throw new IllegalArgumentException(MSG_NULL_POOL);
            }
            this.pool = pool;
            this.minIdle = minIdle;
        }

        /**
         * {@inheritDoc}
         */
        override
        void run() {
            bool success = false;
            try {
                if (pool.getNumIdle() < minIdle) {
                    pool.addObject();
                }
                success = true;

            } catch (Exception e) {
                cancel();
            } finally {
                // detect other types of Throwable and cancel this Timer
                if (!success) {
                    cancel();
                }
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("ObjectPoolMinIdleTimerTask");
            sb.append("{minIdle=").append(minIdle);
            sb.append(", pool=").append(pool);
            sb.append('}');
            return sb.toString();
        }
    }

    /**
     * Timer task that adds objects to the pool until the number of idle
     * instances for the given key reaches the configured minIdle. Note that
     * this is not the same as the pool's minIdle setting.
     *
     * @param <K> object pool key type
     * @param <V> object pool value type
     */
    private static class KeyedObjectPoolMinIdleTimerTask(K, V) : TimerTask {

        /** Minimum number of idle instances. Not the same as pool.getMinIdle(). */
        private int minIdle;

        /** Key to ensure minIdle for */
        private K key;

        /** Keyed object pool */
        private KeyedObjectPool!(K, V) keyedPool;

        /**
         * Creates a new KeyedObjecPoolMinIdleTimerTask.
         *
         * @param keyedPool
         *            keyed object pool
         * @param key
         *            key to ensure minimum number of idle instances
         * @param minIdle
         *            minimum number of idle instances
         * @throws IllegalArgumentException
         *             if the key is null
         */
        this(KeyedObjectPool!(K, V) keyedPool,
                K key, int minIdle){
            if (keyedPool is null) {
                throw new IllegalArgumentException(
                        MSG_NULL_KEYED_POOL);
            }
            this.keyedPool = keyedPool;
            this.key = key;
            this.minIdle = minIdle;
        }

        /**
         * {@inheritDoc}
         */
        override
        void run() {
            bool success = false;
            try {
                if (keyedPool.getNumIdle(key) < minIdle) {
                    keyedPool.addObject(key);
                }
                success = true;

            } catch (Exception e) {
                cancel();

            } finally {
                // detect other types of Throwable and cancel this Timer
                if (!success) {
                    cancel();
                }
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("KeyedObjectPoolMinIdleTimerTask");
            sb.append("{minIdle=").append(minIdle);
            sb.append(", key=").append(key);
            sb.append(", keyedPool=").append(keyedPool);
            sb.append('}');
            return sb.toString();
        }
    }

    /**
     * A synchronized (thread-safe) ObjectPool backed by the specified
     * ObjectPool.
     * <p>
     * <b>Note:</b> This should not be used on pool implementations that already
     * provide proper synchronization such as the pools provided in the Commons
     * Pool library. Wrapping a pool that {@link #wait() waits} for poolable
     * objects to be returned before allowing another one to be borrowed with
     * another layer of synchronization will cause liveliness issues or a
     * deadlock.
     * </p>
     *
     * @param <T> type of objects in the pool
     */
    private static class SynchronizedObjectPool(T) : ObjectPool!(T) {

        /**
         * Object whose monitor is used to synchronize methods on the wrapped
         * pool.
         */
        private ReentrantReadWriteLock readWriteLock = new ReentrantReadWriteLock();

        /** the underlying object pool */
        private ObjectPool!(T) pool;

        /**
         * Creates a new SynchronizedObjectPool wrapping the given pool.
         *
         * @param pool
         *            the ObjectPool to be "wrapped" in a synchronized
         *            ObjectPool.
         * @throws IllegalArgumentException
         *             if the pool is null
         */
        this(ObjectPool!(T) pool) {
            if (pool is null) {
                throw new IllegalArgumentException(MSG_NULL_POOL);
            }
            this.pool = pool;
        }

        /**
         * {@inheritDoc}
         */
        override
        T borrowObject() {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                return pool.borrowObject();
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void returnObject(T obj) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                pool.returnObject(obj);
            } catch (Exception e) {
                // swallowed as of Pool 2
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void invalidateObject(T obj) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                pool.invalidateObject(obj);
            } catch (Exception e) {
                // swallowed as of Pool 2
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void addObject() {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                pool.addObject();
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumIdle() {
            ReadLock readLock = readWriteLock.readLock();
            readLock.lock();
            try {
                return pool.getNumIdle();
            } finally {
                readLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumActive() {
            ReadLock readLock = readWriteLock.readLock();
            readLock.lock();
            try {
                return pool.getNumActive();
            } finally {
                readLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void clear(){
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                pool.clear();
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void close() {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                pool.close();
            } catch (Exception e) {
                // swallowed as of Pool 2
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("SynchronizedObjectPool");
            sb.append("{pool=").append(pool);
            sb.append('}');
            return sb.toString();
        }
    }

    /**
     * A synchronized (thread-safe) KeyedObjectPool backed by the specified
     * KeyedObjectPool.
     * <p>
     * <b>Note:</b> This should not be used on pool implementations that already
     * provide proper synchronization such as the pools provided in the Commons
     * Pool library. Wrapping a pool that {@link #wait() waits} for poolable
     * objects to be returned before allowing another one to be borrowed with
     * another layer of synchronization will cause liveliness issues or a
     * deadlock.
     * </p>
     *
     * @param <K> object pool key type
     * @param <V> object pool value type
     */
    private static class SynchronizedKeyedObjectPool(K, V) :
            KeyedObjectPool!(K, V) {

        /**
         * Object whose monitor is used to synchronize methods on the wrapped
         * pool.
         */
        private ReentrantReadWriteLock readWriteLock = new ReentrantReadWriteLock();

        /** Underlying object pool */
        private KeyedObjectPool!(K, V) keyedPool;

        /**
         * Creates a new SynchronizedKeyedObjectPool wrapping the given pool
         *
         * @param keyedPool
         *            KeyedObjectPool to wrap
         * @throws IllegalArgumentException
         *             if keyedPool is null
         */
        this(KeyedObjectPool!(K, V) keyedPool) {
            if (keyedPool is null) {
                throw new IllegalArgumentException(
                        MSG_NULL_KEYED_POOL);
            }
            this.keyedPool = keyedPool;
        }

        /**
         * {@inheritDoc}
         */
        override
        V borrowObject(K key) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                return keyedPool.borrowObject(key);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void returnObject(K key, V obj) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                keyedPool.returnObject(key, obj);
            } catch (Exception e) {
                // swallowed
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void invalidateObject(K key, V obj) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                keyedPool.invalidateObject(key, obj);
            } catch (Exception e) {
                // swallowed as of Pool 2
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void addObject(K key) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                keyedPool.addObject(key);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumIdle(K key) {
            ReadLock readLock = readWriteLock.readLock();
            readLock.lock();
            try {
                return keyedPool.getNumIdle(key);
            } finally {
                readLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumActive(K key) {
            ReadLock readLock = readWriteLock.readLock();
            readLock.lock();
            try {
                return keyedPool.getNumActive(key);
            } finally {
                readLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumIdle() {
            ReadLock readLock = readWriteLock.readLock();
            readLock.lock();
            try {
                return keyedPool.getNumIdle();
            } finally {
                readLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumActive() {
            ReadLock readLock = readWriteLock.readLock();
            readLock.lock();
            try {
                return keyedPool.getNumActive();
            } finally {
                readLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void clear(){
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                keyedPool.clear();
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void clear(K key) {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                keyedPool.clear(key);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void close() {
            WriteLock writeLock = readWriteLock.writeLock();
            writeLock.lock();
            try {
                keyedPool.close();
            } catch (Exception e) {
                // swallowed as of Pool 2
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("SynchronizedKeyedObjectPool");
            sb.append("{keyedPool=").append(keyedPool);
            sb.append('}');
            return sb.toString();
        }
    }

    /**
     * A fully synchronized PooledObjectFactory that wraps a
     * PooledObjectFactory and synchronizes access to the wrapped factory
     * methods.
     * <p>
     * <b>Note:</b> This should not be used on pool implementations that already
     * provide proper synchronization such as the pools provided in the Commons
     * Pool library.
     * </p>
     *
     * @param <T> pooled object factory type
     */
    private static class SynchronizedPooledObjectFactory(T) : PooledObjectFactory!(T) {

        /** Synchronization lock */
        private WriteLock writeLock = new ReentrantReadWriteLock().writeLock();

        /** Wrapped factory */
        private PooledObjectFactory!(T) factory;

        /**
         * Creates a SynchronizedPoolableObjectFactory wrapping the given
         * factory.
         *
         * @param factory
         *            underlying factory to wrap
         * @throws IllegalArgumentException
         *             if the factory is null
         */
        this(PooledObjectFactory!(T) factory) {
            if (factory is null) {
                throw new IllegalArgumentException("factory must not be null.");
            }
            this.factory = factory;
        }

        /**
         * {@inheritDoc}
         */
        override
        PooledObject!(T) makeObject(){
            writeLock.lock();
            try {
                return factory.makeObject();
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void destroyObject(PooledObject!(T) p){
            writeLock.lock();
            try {
                factory.destroyObject(p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        bool validateObject(PooledObject!(T) p) {
            writeLock.lock();
            try {
                return factory.validateObject(p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void activateObject(PooledObject!(T) p){
            writeLock.lock();
            try {
                factory.activateObject(p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void passivateObject(PooledObject!(T) p){
            writeLock.lock();
            try {
                factory.passivateObject(p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("SynchronizedPoolableObjectFactory");
            sb.append("{factory=").append(factory);
            sb.append('}');
            return sb.toString();
        }
    }

    /**
     * A fully synchronized KeyedPooledObjectFactory that wraps a
     * KeyedPooledObjectFactory and synchronizes access to the wrapped factory
     * methods.
     * <p>
     * <b>Note:</b> This should not be used on pool implementations that already
     * provide proper synchronization such as the pools provided in the Commons
     * Pool library.
     * </p>
     *
     * @param <K> pooled object factory key type
     * @param <V> pooled object factory key value
     */
    private static class SynchronizedKeyedPooledObjectFactory(K, V) : KeyedPooledObjectFactory!(K, V) {

        /** Synchronization lock */
        private WriteLock writeLock = new ReentrantReadWriteLock().writeLock();

        /** Wrapped factory */
        private KeyedPooledObjectFactory!(K, V) keyedFactory;

        /**
         * Creates a SynchronizedKeyedPoolableObjectFactory wrapping the given
         * factory.
         *
         * @param keyedFactory
         *            underlying factory to wrap
         * @throws IllegalArgumentException
         *             if the factory is null
         */
        this(KeyedPooledObjectFactory!(K, V) keyedFactory) {
            if (keyedFactory is null) {
                throw new IllegalArgumentException(
                        "keyedFactory must not be null.");
            }
            this.keyedFactory = keyedFactory;
        }

        /**
         * {@inheritDoc}
         */
        override
        PooledObject!(V) makeObject(K key){
            writeLock.lock();
            try {
                return keyedFactory.makeObject(key);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void destroyObject(K key, PooledObject!(V) p){
            writeLock.lock();
            try {
                keyedFactory.destroyObject(key, p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        bool validateObject(K key, PooledObject!(V) p) {
            writeLock.lock();
            try {
                return keyedFactory.validateObject(key, p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void activateObject(K key, PooledObject!(V) p){
            writeLock.lock();
            try {
                keyedFactory.activateObject(key, p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void passivateObject(K key, PooledObject!(V) p){
            writeLock.lock();
            try {
                keyedFactory.passivateObject(key, p);
            } finally {
                writeLock.unlock();
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("SynchronizedKeyedPoolableObjectFactory");
            sb.append("{keyedFactory=").append(keyedFactory);
            sb.append('}');
            return sb.toString();
        }
    }

    /**
     * Encapsulate the logic for when the next poolable object should be
     * discarded. Each time update is called, the next time to shrink is
     * recomputed, based on the float factor, number of idle instances in the
     * pool and high water mark. Float factor is assumed to be between 0 and 1.
     * Values closer to 1 cause less frequent erosion events. Erosion event
     * timing also depends on numIdle. When this value is relatively high (close
     * to previously established high water mark), erosion occurs more
     * frequently.
     */
    private static class ErodingFactor {
        /** Determines frequency of "erosion" events */
        private float factor;

        /** Time of next shrink event */
        private shared long nextShrink;

        /** High water mark - largest numIdle encountered */
        private shared int idleHighWaterMark;

        /**
         * Creates a new ErodingFactor with the given erosion factor.
         *
         * @param factor
         *            erosion factor
         */
        this(float factor) {
            this.factor = factor;
            nextShrink = DateTimeHelper.currentTimeMillis()() + cast(long) (900000 * factor); // now
                                                                                // +
                                                                                // 15
                                                                                // min
                                                                                // *
                                                                                // factor
            idleHighWaterMark = 1;
        }

        /**
         * Updates internal state using the supplied time and numIdle.
         *
         * @param now
         *            current time
         * @param numIdle
         *            number of idle elements in the pool
         */
        void update(long now, int numIdle) {
            int idle = Math.max(0, numIdle);
            idleHighWaterMark = Math.max(idle, idleHighWaterMark);
            float maxInterval = 15f;
            float minutes = maxInterval +
                    ((1f - maxInterval) / idleHighWaterMark) * idle;
            nextShrink = now + cast(long) (minutes * 60000f * factor);
        }

        /**
         * Returns the time of the next erosion event.
         *
         * @return next shrink time
         */
        long getNextShrink() {
            return nextShrink;
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            return "ErodingFactor{" ~ "factor=" ~ factor +
                    ", idleHighWaterMark=" ~ idleHighWaterMark + '}';
        }
    }

    /**
     * Decorates an object pool, adding "eroding" behavior. Based on the
     * configured {@link #factor erosion factor}, objects returning to the pool
     * may be invalidated instead of being added to idle capacity.
     *
     * @param <T> type of objects in the pool
     */
    private static class ErodingObjectPool(T) : ObjectPool!(T) {

        /** Underlying object pool */
        private ObjectPool!(T) pool;

        /** Erosion factor */
        private ErodingFactor factor;

        /**
         * Creates an ErodingObjectPool wrapping the given pool using the
         * specified erosion factor.
         *
         * @param pool
         *            underlying pool
         * @param factor
         *            erosion factor - determines the frequency of erosion
         *            events
         * @see #factor
         */
        this(ObjectPool!(T) pool, float factor) {
            this.pool = pool;
            this.factor = new ErodingFactor(factor);
        }

        /**
         * {@inheritDoc}
         */
        override
        T borrowObject() {
            return pool.borrowObject();
        }

        /**
         * Returns obj to the pool, unless erosion is triggered, in which case
         * obj is invalidated. Erosion is triggered when there are idle
         * instances in the pool and more than the {@link #factor erosion
         * factor}-determined time has elapsed since the last returnObject
         * activation.
         *
         * @param obj
         *            object to return or invalidate
         * @see #factor
         */
        override
        void returnObject(T obj) {
            bool discard = false;
            long now = DateTimeHelper.currentTimeMillis()();
            synchronized (pool) {
                if (factor.getNextShrink() < now) { // XXX: Pool 3: move test
                                                    // out of sync block
                    int numIdle = pool.getNumIdle();
                    if (numIdle > 0) {
                        discard = true;
                    }

                    factor.update(now, numIdle);
                }
            }
            try {
                if (discard) {
                    pool.invalidateObject(obj);
                } else {
                    pool.returnObject(obj);
                }
            } catch (Exception e) {
                // swallowed
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void invalidateObject(T obj) {
            try {
                pool.invalidateObject(obj);
            } catch (Exception e) {
                // swallowed
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void addObject() {
            pool.addObject();
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumIdle() {
            return pool.getNumIdle();
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumActive() {
            return pool.getNumActive();
        }

        /**
         * {@inheritDoc}
         */
        override
        void clear(){
            pool.clear();
        }

        /**
         * {@inheritDoc}
         */
        override
        void close() {
            try {
                pool.close();
            } catch (Exception e) {
                // swallowed
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            return "ErodingObjectPool{" ~ "factor=" ~ factor ~ ", pool=" ~
                    pool + '}';
        }
    }

    /**
     * Decorates a keyed object pool, adding "eroding" behavior. Based on the
     * configured erosion factor, objects returning to the pool
     * may be invalidated instead of being added to idle capacity.
     *
     * @param <K> object pool key type
     * @param <V> object pool value type
     */
    private static class ErodingKeyedObjectPool(K, V) : KeyedObjectPool!(K, V) {

        /** Underlying pool */
        private KeyedObjectPool!(K, V) keyedPool;

        /** Erosion factor */
        private ErodingFactor erodingFactor;

        /**
         * Creates an ErodingObjectPool wrapping the given pool using the
         * specified erosion factor.
         *
         * @param keyedPool
         *            underlying pool
         * @param factor
         *            erosion factor - determines the frequency of erosion
         *            events
         * @see #erodingFactor
         */
        this(KeyedObjectPool!(K, V) keyedPool, float factor) {
            this(keyedPool, new ErodingFactor(factor));
        }

        /**
         * Creates an ErodingObjectPool wrapping the given pool using the
         * specified erosion factor.
         *
         * @param keyedPool
         *            underlying pool - must not be null
         * @param erodingFactor
         *            erosion factor - determines the frequency of erosion
         *            events
         * @see #erodingFactor
         */
        protected this(KeyedObjectPool!(K, V) keyedPool,
                ErodingFactor erodingFactor) {
            if (keyedPool is null) {
                throw new IllegalArgumentException(
                        MSG_NULL_KEYED_POOL);
            }
            this.keyedPool = keyedPool;
            this.erodingFactor = erodingFactor;
        }

        /**
         * {@inheritDoc}
         */
        override
        V borrowObject(K key) {
            return keyedPool.borrowObject(key);
        }

        /**
         * Returns obj to the pool, unless erosion is triggered, in which case
         * obj is invalidated. Erosion is triggered when there are idle
         * instances in the pool associated with the given key and more than the
         * configured {@link #erodingFactor erosion factor} time has elapsed
         * since the last returnObject activation.
         *
         * @param obj
         *            object to return or invalidate
         * @param key
         *            key
         * @see #erodingFactor
         */
        override
        void returnObject(K key, V obj){
            bool discard = false;
            long now = DateTimeHelper.currentTimeMillis()();
            ErodingFactor factor = getErodingFactor(key);
            synchronized (keyedPool) {
                if (factor.getNextShrink() < now) {
                    int numIdle = getNumIdle(key);
                    if (numIdle > 0) {
                        discard = true;
                    }

                    factor.update(now, numIdle);
                }
            }
            try {
                if (discard) {
                    keyedPool.invalidateObject(key, obj);
                } else {
                    keyedPool.returnObject(key, obj);
                }
            } catch (Exception e) {
                // swallowed
            }
        }

        /**
         * Returns the eroding factor for the given key
         *
         * @param key
         *            key
         * @return eroding factor for the given keyed pool
         */
        protected ErodingFactor getErodingFactor(K key) {
            return erodingFactor;
        }

        /**
         * {@inheritDoc}
         */
        override
        void invalidateObject(K key, V obj) {
            try {
                keyedPool.invalidateObject(key, obj);
            } catch (Exception e) {
                // swallowed
            }
        }

        /**
         * {@inheritDoc}
         */
        override
        void addObject(K key) {
            keyedPool.addObject(key);
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumIdle() {
            return keyedPool.getNumIdle();
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumIdle(K key) {
            return keyedPool.getNumIdle(key);
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumActive() {
            return keyedPool.getNumActive();
        }

        /**
         * {@inheritDoc}
         */
        override
        int getNumActive(K key) {
            return keyedPool.getNumActive(key);
        }

        /**
         * {@inheritDoc}
         */
        override
        void clear(){
            keyedPool.clear();
        }

        /**
         * {@inheritDoc}
         */
        override
        void clear(K key) {
            keyedPool.clear(key);
        }

        /**
         * {@inheritDoc}
         */
        override
        void close() {
            try {
                keyedPool.close();
            } catch (Exception e) {
                // swallowed
            }
        }

        /**
         * Returns the underlying pool
         *
         * @return the keyed pool that this ErodingKeyedObjectPool wraps
         */
        protected KeyedObjectPool!(K, V) getKeyedPool() {
            return keyedPool;
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            return "ErodingKeyedObjectPool{" ~ "factor=" ~
                    erodingFactor ~ ", keyedPool=" ~ keyedPool + '}';
        }
    }

    /**
     * Extends ErodingKeyedObjectPool to allow erosion to take place on a
     * per-key basis. Timing of erosion events is tracked separately for
     * separate keyed pools.
     *
     * @param <K> object pool key type
     * @param <V> object pool value type
     */
    private static class ErodingPerKeyKeyedObjectPool(K, V) : ErodingKeyedObjectPool!(K, V) {

        /** Erosion factor - same for all pools */
        private float factor;

        /** Map of ErodingFactor instances keyed on pool keys */
        private Map!(K, ErodingFactor) factors = Collections.synchronizedMap(new HashMap!(K, ErodingFactor)());

        /**
         * Creates a new ErordingPerKeyKeyedObjectPool decorating the given keyed
         * pool with the specified erosion factor.
         *
         * @param keyedPool
         *            underlying keyed pool
         * @param factor
         *            erosion factor
         */
        this(KeyedObjectPool!(K, V) keyedPool, float factor) {
            super(keyedPool, null);
            this.factor = factor;
        }

        /**
         * {@inheritDoc}
         */
        override
        protected ErodingFactor getErodingFactor(K key) {
            ErodingFactor eFactor = factors.get(key);
            // this may result in two ErodingFactors being created for a key
            // since they are small and cheap this is okay.
            if (eFactor is null) {
                eFactor = new ErodingFactor(this.factor);
                factors.put(key, eFactor);
            }
            return eFactor;
        }

        /**
         * {@inheritDoc}
         */
        override
        string toString() {
            return "ErodingPerKeyKeyedObjectPool{" ~ "factor=" ~ factor ~
                    ", keyedPool=" ~ getKeyedPool() + "}";
        }
    }
}
