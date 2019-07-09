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
module hunt.pool.impl.BaseGenericObjectPool;

// import java.io.PrintWriter;
// import java.io.StringWriter;
// import java.io.Writer;
// import java.lang.management.ManagementFactory;
// import java.lang.ref.WeakReference;
// import java.lang.reflect.InvocationTargetException;
// import java.util.Arrays;
// import java.util.Deque;
// import java.util.Iterator;
// import java.util.TimerTask;
import hunt.concurrency.Delayed;
import hunt.concurrency.Future;
// import java.util.concurrent.TimeUnit;
// import java.util.concurrent.atomic.AtomicLong;

// import javax.management.InstanceAlreadyExistsException;
// import javax.management.InstanceNotFoundException;
// import javax.management.MBeanRegistrationException;
// import javax.management.MBeanServer;
// import javax.management.MalformedObjectNameException;
// import javax.management.NotCompliantMBeanException;
// import javax.management.ObjectName;

import hunt.pool.BaseObject;
import hunt.pool.PooledObject;
import hunt.pool.PooledObjectState;
import hunt.pool.SwallowedExceptionListener;


import hunt.Exceptions;

/**
 * Base class that provides common functionality for {@link GenericObjectPool}
 * and {@link GenericKeyedObjectPool}. The primary reason this class exists is
 * reduce code duplication between the two pool implementations.
 *
 * @param <T> Type of element pooled in this pool.
 *
 * This class is intended to be thread-safe.
 *
 */
abstract class BaseGenericObjectPool(T) : BaseObject {

    // Constants
    /**
     * The size of the caches used to store historical data for some attributes
     * so that rolling means may be calculated.
     */
    enum int MEAN_TIMING_STATS_CACHE_SIZE = 100;

    private enum string EVICTION_POLICY_TYPE_NAME = EvictionPolicy.stringof;

    // Configuration attributes
    private shared int maxTotal =
            GenericKeyedObjectPoolConfig.DEFAULT_MAX_TOTAL;
    private shared bool blockWhenExhausted =
            BaseObjectPoolConfig.DEFAULT_BLOCK_WHEN_EXHAUSTED;
    private shared long maxWaitMillis =
            BaseObjectPoolConfig.DEFAULT_MAX_WAIT_MILLIS;
    private shared bool lifo = BaseObjectPoolConfig.DEFAULT_LIFO;
    private bool fairness;
    private shared bool testOnCreate =
            BaseObjectPoolConfig.DEFAULT_TEST_ON_CREATE;
    private shared bool testOnBorrow =
            BaseObjectPoolConfig.DEFAULT_TEST_ON_BORROW;
    private shared bool testOnReturn =
            BaseObjectPoolConfig.DEFAULT_TEST_ON_RETURN;
    private shared bool testWhileIdle =
            BaseObjectPoolConfig.DEFAULT_TEST_WHILE_IDLE;
    private shared long timeBetweenEvictionRunsMillis =
            BaseObjectPoolConfig.DEFAULT_TIME_BETWEEN_EVICTION_RUNS_MILLIS;
    private shared int numTestsPerEvictionRun =
            BaseObjectPoolConfig.DEFAULT_NUM_TESTS_PER_EVICTION_RUN;
    private shared long minEvictableIdleTimeMillis =
            BaseObjectPoolConfig.DEFAULT_MIN_EVICTABLE_IDLE_TIME_MILLIS;
    private shared long softMinEvictableIdleTimeMillis =
            BaseObjectPoolConfig.DEFAULT_SOFT_MIN_EVICTABLE_IDLE_TIME_MILLIS;
    private shared EvictionPolicy!(T) evictionPolicy;
    private shared long evictorShutdownTimeoutMillis =
            BaseObjectPoolConfig.DEFAULT_EVICTOR_SHUTDOWN_TIMEOUT_MILLIS;


    // Internal (primarily state) attributes
    Object closeLock = new Object();
    shared bool closed = false;
    Object evictionLock = new Object();
    private Evictor evictor = null; // @GuardedBy("evictionLock")
    EvictionIterator evictionIterator = null; // @GuardedBy("evictionLock")
    /*
     * Class loader for evictor thread to use since, in a JavaEE or similar
     * environment, the context class loader for the evictor thread may not have
     * visibility of the correct factory. See POOL-161. Uses a weak reference to
     * avoid potential memory leaks if the Pool is discarded rather than closed.
     */
    private WeakReference!(ClassLoader) factoryClassLoader;


    // Monitoring (primarily JMX) attributes
    private ObjectName objectName;
    private string creationStackTrace;
    private AtomicLong borrowedCount = new AtomicLong(0);
    private AtomicLong returnedCount = new AtomicLong(0);
    AtomicLong createdCount = new AtomicLong(0);
    AtomicLong destroyedCount = new AtomicLong(0);
    AtomicLong destroyedByEvictorCount = new AtomicLong(0);
    AtomicLong destroyedByBorrowValidationCount = new AtomicLong(0);
    private StatsStore activeTimes = new StatsStore(MEAN_TIMING_STATS_CACHE_SIZE);
    private StatsStore idleTimes = new StatsStore(MEAN_TIMING_STATS_CACHE_SIZE);
    private StatsStore waitTimes = new StatsStore(MEAN_TIMING_STATS_CACHE_SIZE);
    private AtomicLong maxBorrowWaitTimeMillis = new AtomicLong(0L);
    private shared SwallowedExceptionListener swallowedExceptionListener = null;


    /**
     * Handles JMX registration (if required) and the initialization required for
     * monitoring.
     *
     * @param config        Pool configuration
     * @param jmxNameBase   The default base JMX name for the new pool unless
     *                      overridden by the config
     * @param jmxNamePrefix Prefix to be used for JMX name for the new pool
     */
    this(BaseObjectPoolConfig!(T) config,
            string jmxNameBase, string jmxNamePrefix) {
        if (config.getJmxEnabled()) {
            this.objectName = jmxRegister(config, jmxNameBase, jmxNamePrefix);
        } else {
            this.objectName = null;
        }

        // Populate the creation stack trace
        this.creationStackTrace = getStackTrace(new Exception());

        // save the current TCCL (if any) to be used later by the evictor Thread
        // ClassLoader cl = Thread.getThis().getContextClassLoader();
        // if (cl is null) {
        //     factoryClassLoader = null;
        // } else {
        //     factoryClassLoader = new WeakReference<>(cl);
        // }
implementationMissing(false)        ;

        fairness = config.getFairness();
    }


    /**
     * Returns the maximum number of objects that can be allocated by the pool
     * (checked out to clients, or idle awaiting checkout) at a given time. When
     * negative, there is no limit to the number of objects that can be
     * managed by the pool at one time.
     *
     * @return the cap on the total number of object instances managed by the
     *         pool.
     *
     * @see #setMaxTotal
     */
    int getMaxTotal() {
        return maxTotal;
    }

    /**
     * Sets the cap on the number of objects that can be allocated by the pool
     * (checked out to clients, or idle awaiting checkout) at a given time. Use
     * a negative value for no limit.
     *
     * @param maxTotal  The cap on the total number of object instances managed
     *                  by the pool. Negative values mean that there is no limit
     *                  to the number of objects allocated by the pool.
     *
     * @see #getMaxTotal
     */
    void setMaxTotal(int maxTotal) {
        this.maxTotal = maxTotal;
    }

    /**
     * Returns whether to block when the <code>borrowObject()</code> method is
     * invoked when the pool is exhausted (the maximum number of "active"
     * objects has been reached).
     *
     * @return <code>true</code> if <code>borrowObject()</code> should block
     *         when the pool is exhausted
     *
     * @see #setBlockWhenExhausted
     */
    bool getBlockWhenExhausted() {
        return blockWhenExhausted;
    }

    /**
     * Sets whether to block when the <code>borrowObject()</code> method is
     * invoked when the pool is exhausted (the maximum number of "active"
     * objects has been reached).
     *
     * @param blockWhenExhausted    <code>true</code> if
     *                              <code>borrowObject()</code> should block
     *                              when the pool is exhausted
     *
     * @see #getBlockWhenExhausted
     */
    void setBlockWhenExhausted(bool blockWhenExhausted) {
        this.blockWhenExhausted = blockWhenExhausted;
    }

    protected void setConfig(BaseObjectPoolConfig!(T) conf) {
        setLifo(conf.getLifo());
        setMaxWaitMillis(conf.getMaxWaitMillis());
        setBlockWhenExhausted(conf.getBlockWhenExhausted());
        setTestOnCreate(conf.getTestOnCreate());
        setTestOnBorrow(conf.getTestOnBorrow());
        setTestOnReturn(conf.getTestOnReturn());
        setTestWhileIdle(conf.getTestWhileIdle());
        setNumTestsPerEvictionRun(conf.getNumTestsPerEvictionRun());
        setMinEvictableIdleTimeMillis(conf.getMinEvictableIdleTimeMillis());
        setTimeBetweenEvictionRunsMillis(conf.getTimeBetweenEvictionRunsMillis());
        setSoftMinEvictableIdleTimeMillis(conf.getSoftMinEvictableIdleTimeMillis());
        EvictionPolicy!(T) policy = conf.getEvictionPolicy();
        if (policy is null) {
            // Use the class name (pre-2.6.0 compatible)
            setEvictionPolicyClassName(conf.getEvictionPolicyClassName());
        } else {
            // Otherwise, use the class (2.6.0 feature)
            setEvictionPolicy(policy);
        }
        setEvictorShutdownTimeoutMillis(conf.getEvictorShutdownTimeoutMillis());
    }

    /**
     * Returns the maximum amount of time (in milliseconds) the
     * <code>borrowObject()</code> method should block before throwing an
     * exception when the pool is exhausted and
     * {@link #getBlockWhenExhausted} is true. When less than 0, the
     * <code>borrowObject()</code> method may block indefinitely.
     *
     * @return the maximum number of milliseconds <code>borrowObject()</code>
     *         will block.
     *
     * @see #setMaxWaitMillis
     * @see #setBlockWhenExhausted
     */
    long getMaxWaitMillis() {
        return maxWaitMillis;
    }

    /**
     * Sets the maximum amount of time (in milliseconds) the
     * <code>borrowObject()</code> method should block before throwing an
     * exception when the pool is exhausted and
     * {@link #getBlockWhenExhausted} is true. When less than 0, the
     * <code>borrowObject()</code> method may block indefinitely.
     *
     * @param maxWaitMillis the maximum number of milliseconds
     *                      <code>borrowObject()</code> will block or negative
     *                      for indefinitely.
     *
     * @see #getMaxWaitMillis
     * @see #setBlockWhenExhausted
     */
    void setMaxWaitMillis(long maxWaitMillis) {
        this.maxWaitMillis = maxWaitMillis;
    }

    /**
     * Returns whether the pool has LIFO (last in, first out) behaviour with
     * respect to idle objects - always returning the most recently used object
     * from the pool, or as a FIFO (first in, first out) queue, where the pool
     * always returns the oldest object in the idle object pool.
     *
     * @return <code>true</code> if the pool is configured with LIFO behaviour
     *         or <code>false</code> if the pool is configured with FIFO
     *         behaviour
     *
     * @see #setLifo
     */
    bool getLifo() {
        return lifo;
    }

    /**
     * Returns whether or not the pool serves threads waiting to borrow objects fairly.
     * True means that waiting threads are served as if waiting in a FIFO queue.
     *
     * @return <code>true</code> if waiting threads are to be served
     *             by the pool in arrival order
     */
    bool getFairness() {
        return fairness;
    }

    /**
     * Sets whether the pool has LIFO (last in, first out) behaviour with
     * respect to idle objects - always returning the most recently used object
     * from the pool, or as a FIFO (first in, first out) queue, where the pool
     * always returns the oldest object in the idle object pool.
     *
     * @param lifo  <code>true</code> if the pool is to be configured with LIFO
     *              behaviour or <code>false</code> if the pool is to be
     *              configured with FIFO behaviour
     *
     * @see #getLifo()
     */
    void setLifo(bool lifo) {
        this.lifo = lifo;
    }

    /**
     * Returns whether objects created for the pool will be validated before
     * being returned from the <code>borrowObject()</code> method. Validation is
     * performed by the <code>validateObject()</code> method of the factory
     * associated with the pool. If the object fails to validate, then
     * <code>borrowObject()</code> will fail.
     *
     * @return <code>true</code> if newly created objects are validated before
     *         being returned from the <code>borrowObject()</code> method
     *
     * @see #setTestOnCreate
     *
     */
    bool getTestOnCreate() {
        return testOnCreate;
    }

    /**
     * Sets whether objects created for the pool will be validated before
     * being returned from the <code>borrowObject()</code> method. Validation is
     * performed by the <code>validateObject()</code> method of the factory
     * associated with the pool. If the object fails to validate, then
     * <code>borrowObject()</code> will fail.
     *
     * @param testOnCreate  <code>true</code> if newly created objects should be
     *                      validated before being returned from the
     *                      <code>borrowObject()</code> method
     *
     * @see #getTestOnCreate
     *
     */
    void setTestOnCreate(bool testOnCreate) {
        this.testOnCreate = testOnCreate;
    }

    /**
     * Returns whether objects borrowed from the pool will be validated before
     * being returned from the <code>borrowObject()</code> method. Validation is
     * performed by the <code>validateObject()</code> method of the factory
     * associated with the pool. If the object fails to validate, it will be
     * removed from the pool and destroyed, and a new attempt will be made to
     * borrow an object from the pool.
     *
     * @return <code>true</code> if objects are validated before being returned
     *         from the <code>borrowObject()</code> method
     *
     * @see #setTestOnBorrow
     */
    bool getTestOnBorrow() {
        return testOnBorrow;
    }

    /**
     * Sets whether objects borrowed from the pool will be validated before
     * being returned from the <code>borrowObject()</code> method. Validation is
     * performed by the <code>validateObject()</code> method of the factory
     * associated with the pool. If the object fails to validate, it will be
     * removed from the pool and destroyed, and a new attempt will be made to
     * borrow an object from the pool.
     *
     * @param testOnBorrow  <code>true</code> if objects should be validated
     *                      before being returned from the
     *                      <code>borrowObject()</code> method
     *
     * @see #getTestOnBorrow
     */
    void setTestOnBorrow(bool testOnBorrow) {
        this.testOnBorrow = testOnBorrow;
    }

    /**
     * Returns whether objects borrowed from the pool will be validated when
     * they are returned to the pool via the <code>returnObject()</code> method.
     * Validation is performed by the <code>validateObject()</code> method of
     * the factory associated with the pool. Returning objects that fail validation
     * are destroyed rather then being returned the pool.
     *
     * @return <code>true</code> if objects are validated on return to
     *         the pool via the <code>returnObject()</code> method
     *
     * @see #setTestOnReturn
     */
    bool getTestOnReturn() {
        return testOnReturn;
    }

    /**
     * Sets whether objects borrowed from the pool will be validated when
     * they are returned to the pool via the <code>returnObject()</code> method.
     * Validation is performed by the <code>validateObject()</code> method of
     * the factory associated with the pool. Returning objects that fail validation
     * are destroyed rather then being returned the pool.
     *
     * @param testOnReturn <code>true</code> if objects are validated on
     *                     return to the pool via the
     *                     <code>returnObject()</code> method
     *
     * @see #getTestOnReturn
     */
    void setTestOnReturn(bool testOnReturn) {
        this.testOnReturn = testOnReturn;
    }

    /**
     * Returns whether objects sitting idle in the pool will be validated by the
     * idle object evictor (if any - see
     * {@link #setTimeBetweenEvictionRunsMillis(long)}). Validation is performed
     * by the <code>validateObject()</code> method of the factory associated
     * with the pool. If the object fails to validate, it will be removed from
     * the pool and destroyed.
     *
     * @return <code>true</code> if objects will be validated by the evictor
     *
     * @see #setTestWhileIdle
     * @see #setTimeBetweenEvictionRunsMillis
     */
    bool getTestWhileIdle() {
        return testWhileIdle;
    }

    /**
     * Returns whether objects sitting idle in the pool will be validated by the
     * idle object evictor (if any - see
     * {@link #setTimeBetweenEvictionRunsMillis(long)}). Validation is performed
     * by the <code>validateObject()</code> method of the factory associated
     * with the pool. If the object fails to validate, it will be removed from
     * the pool and destroyed.  Note that setting this property has no effect
     * unless the idle object evictor is enabled by setting
     * <code>timeBetweenEvictionRunsMillis</code> to a positive value.
     *
     * @param testWhileIdle
     *            <code>true</code> so objects will be validated by the evictor
     *
     * @see #getTestWhileIdle
     * @see #setTimeBetweenEvictionRunsMillis
     */
    void setTestWhileIdle(bool testWhileIdle) {
        this.testWhileIdle = testWhileIdle;
    }

    /**
     * Returns the number of milliseconds to sleep between runs of the idle
     * object evictor thread. When non-positive, no idle object evictor thread
     * will be run.
     *
     * @return number of milliseconds to sleep between evictor runs
     *
     * @see #setTimeBetweenEvictionRunsMillis
     */
    long getTimeBetweenEvictionRunsMillis() {
        return timeBetweenEvictionRunsMillis;
    }

    /**
     * Sets the number of milliseconds to sleep between runs of the idle object evictor thread.
     * <ul>
     * <li>When positive, the idle object evictor thread starts.</li>
     * <li>When non-positive, no idle object evictor thread runs.</li>
     * </ul>
     *
     * @param timeBetweenEvictionRunsMillis
     *            number of milliseconds to sleep between evictor runs
     *
     * @see #getTimeBetweenEvictionRunsMillis
     */
    void setTimeBetweenEvictionRunsMillis(
            long timeBetweenEvictionRunsMillis) {
        this.timeBetweenEvictionRunsMillis = timeBetweenEvictionRunsMillis;
        startEvictor(timeBetweenEvictionRunsMillis);
    }

    /**
     * Returns the maximum number of objects to examine during each run (if any)
     * of the idle object evictor thread. When positive, the number of tests
     * performed for a run will be the minimum of the configured value and the
     * number of idle instances in the pool. When negative, the number of tests
     * performed will be <code>ceil({@link #getNumIdle}/
     * abs({@link #getNumTestsPerEvictionRun}))</code> which means that when the
     * value is <code>-n</code> roughly one nth of the idle objects will be
     * tested per run.
     *
     * @return max number of objects to examine during each evictor run
     *
     * @see #setNumTestsPerEvictionRun
     * @see #setTimeBetweenEvictionRunsMillis
     */
    int getNumTestsPerEvictionRun() {
        return numTestsPerEvictionRun;
    }

    /**
     * Sets the maximum number of objects to examine during each run (if any)
     * of the idle object evictor thread. When positive, the number of tests
     * performed for a run will be the minimum of the configured value and the
     * number of idle instances in the pool. When negative, the number of tests
     * performed will be <code>ceil({@link #getNumIdle}/
     * abs({@link #getNumTestsPerEvictionRun}))</code> which means that when the
     * value is <code>-n</code> roughly one nth of the idle objects will be
     * tested per run.
     *
     * @param numTestsPerEvictionRun
     *            max number of objects to examine during each evictor run
     *
     * @see #getNumTestsPerEvictionRun
     * @see #setTimeBetweenEvictionRunsMillis
     */
    void setNumTestsPerEvictionRun(int numTestsPerEvictionRun) {
        this.numTestsPerEvictionRun = numTestsPerEvictionRun;
    }

    /**
     * Returns the minimum amount of time an object may sit idle in the pool
     * before it is eligible for eviction by the idle object evictor (if any -
     * see {@link #setTimeBetweenEvictionRunsMillis(long)}). When non-positive,
     * no objects will be evicted from the pool due to idle time alone.
     *
     * @return minimum amount of time an object may sit idle in the pool before
     *         it is eligible for eviction
     *
     * @see #setMinEvictableIdleTimeMillis
     * @see #setTimeBetweenEvictionRunsMillis
     */
    long getMinEvictableIdleTimeMillis() {
        return minEvictableIdleTimeMillis;
    }

    /**
     * Sets the minimum amount of time an object may sit idle in the pool
     * before it is eligible for eviction by the idle object evictor (if any -
     * see {@link #setTimeBetweenEvictionRunsMillis(long)}). When non-positive,
     * no objects will be evicted from the pool due to idle time alone.
     *
     * @param minEvictableIdleTimeMillis
     *            minimum amount of time an object may sit idle in the pool
     *            before it is eligible for eviction
     *
     * @see #getMinEvictableIdleTimeMillis
     * @see #setTimeBetweenEvictionRunsMillis
     */
    void setMinEvictableIdleTimeMillis(
            long minEvictableIdleTimeMillis) {
        this.minEvictableIdleTimeMillis = minEvictableIdleTimeMillis;
    }

    /**
     * Returns the minimum amount of time an object may sit idle in the pool
     * before it is eligible for eviction by the idle object evictor (if any -
     * see {@link #setTimeBetweenEvictionRunsMillis(long)}),
     * with the extra condition that at least <code>minIdle</code> object
     * instances remain in the pool. This setting is overridden by
     * {@link #getMinEvictableIdleTimeMillis} (that is, if
     * {@link #getMinEvictableIdleTimeMillis} is positive, then
     * {@link #getSoftMinEvictableIdleTimeMillis} is ignored).
     *
     * @return minimum amount of time an object may sit idle in the pool before
     *         it is eligible for eviction if minIdle instances are available
     *
     * @see #setSoftMinEvictableIdleTimeMillis
     */
    long getSoftMinEvictableIdleTimeMillis() {
        return softMinEvictableIdleTimeMillis;
    }

    /**
     * Sets the minimum amount of time an object may sit idle in the pool
     * before it is eligible for eviction by the idle object evictor (if any -
     * see {@link #setTimeBetweenEvictionRunsMillis(long)}),
     * with the extra condition that at least <code>minIdle</code> object
     * instances remain in the pool. This setting is overridden by
     * {@link #getMinEvictableIdleTimeMillis} (that is, if
     * {@link #getMinEvictableIdleTimeMillis} is positive, then
     * {@link #getSoftMinEvictableIdleTimeMillis} is ignored).
     *
     * @param softMinEvictableIdleTimeMillis
     *            minimum amount of time an object may sit idle in the pool
     *            before it is eligible for eviction if minIdle instances are
     *            available
     *
     * @see #getSoftMinEvictableIdleTimeMillis
     */
    void setSoftMinEvictableIdleTimeMillis(
            long softMinEvictableIdleTimeMillis) {
        this.softMinEvictableIdleTimeMillis = softMinEvictableIdleTimeMillis;
    }

    /**
     * Returns the name of the {@link EvictionPolicy} implementation that is
     * used by this pool.
     *
     * @return  The fully qualified class name of the {@link EvictionPolicy}
     *
     * @see #setEvictionPolicyClassName(string)
     */
    string getEvictionPolicyClassName() {
        return typeid(evictionPolicy).name;
    }

    /**
     * Sets the eviction policy for this pool.
     *
     * @param evictionPolicy
     *            the eviction policy for this pool.
     */
    void setEvictionPolicy(EvictionPolicy!(T) evictionPolicy) {
        this.evictionPolicy = evictionPolicy;
    }

    /**
     * Sets the name of the {@link EvictionPolicy} implementation that is used by this pool. The Pool will attempt to
     * load the class using the given class loader. If that fails, use the class loader for the {@link EvictionPolicy}
     * interface.
     *
     * @param evictionPolicyClassName
     *            the fully qualified class name of the new eviction policy
     * @param classLoader
     *            the class loader to load the given {@code evictionPolicyClassName}.
     *
     * @see #getEvictionPolicyClassName() If loading the class using the given class loader fails, use the class loader for the
     *        {@link EvictionPolicy} interface.
     */
    // void setEvictionPolicyClassName(string evictionPolicyClassName, ClassLoader classLoader) {
    //     // Getting epClass here and now best matches the caller's environment
    //     Class<?> epClass = EvictionPolicy.class;
    //     ClassLoader epClassLoader = epClass.getClassLoader();
    //     try {
    //         try {
    //             setEvictionPolicy(evictionPolicyClassName, classLoader);
    //         } catch (ClassCastException | ClassNotFoundException e) {
    //             setEvictionPolicy(evictionPolicyClassName, epClassLoader);
    //         }
    //     } catch (ClassCastException e) {
    //         throw new IllegalArgumentException("Class " ~ evictionPolicyClassName ~ " from class loaders ["
    //                 + classLoader ~ ", " ~ epClassLoader ~ "] do not implement " ~ EVICTION_POLICY_TYPE_NAME);
    //     } catch (ClassNotFoundException | InstantiationException | IllegalAccessException
    //             | InvocationTargetException | NoSuchMethodException e) {
    //         string exMessage = "Unable to create " ~ EVICTION_POLICY_TYPE_NAME ~ " instance of type "
    //                 + evictionPolicyClassName;
    //         throw new IllegalArgumentException(exMessage, e);
    //     }
    // }

    // private void setEvictionPolicy(string className, ClassLoader classLoader) {
    //     Class<?> clazz = Class.forName(className, true, classLoader);
    //     Object policy = clazz.getConstructor().newInstance();
    //     this.evictionPolicy = (EvictionPolicy!(T)) policy;
    // }

    /**
     * Sets the name of the {@link EvictionPolicy} implementation that is used by this pool. The Pool will attempt to
     * load the class using the thread context class loader. If that fails, the use the class loader for the
     * {@link EvictionPolicy} interface.
     *
     * @param evictionPolicyClassName
     *            the fully qualified class name of the new eviction policy
     *ctionPolicyClassName()
     * @since 2.6.0 If loading the class using the thread context class loader fails, use the class loader for the
     *        {@link EvictionPolicy} interface.
     */
    void setEvictionPolicyClassName(string evictionPolicyClassName) {
        // setEvictionPolicyClassName(evictionPolicyClassName, Thread.getThis()().getContextClassLoader());
        implementationMissing(false);
    }

    /**
     * Gets the timeout that will be used when waiting for the Evictor to
     * shutdown if this pool is closed and it is the only pool still using the
     * the value for the Evictor.
     *
     * @return  The timeout in milliseconds that will be used while waiting for
     *          the Evictor to shut down.
     */
    long getEvictorShutdownTimeoutMillis() {
        return evictorShutdownTimeoutMillis;
    }

    /**
     * Sets the timeout that will be used when waiting for the Evictor to
     * shutdown if this pool is closed and it is the only pool still using the
     * the value for the Evictor.
     *
     * @param evictorShutdownTimeoutMillis  the timeout in milliseconds that
     *                                      will be used while waiting for the
     *                                      Evictor to shut down.
     */
    void setEvictorShutdownTimeoutMillis(
            long evictorShutdownTimeoutMillis) {
        this.evictorShutdownTimeoutMillis = evictorShutdownTimeoutMillis;
    }

    /**
     * Closes the pool, destroys the remaining idle objects and, if registered
     * in JMX, deregisters it.
     */
    abstract void close();

    /**
     * Has this pool instance been closed.
     * @return <code>true</code> when this pool has been closed.
     */
    bool isClosed() {
        return closed;
    }

    /**
     * <p>Perform <code>numTests</code> idle object eviction tests, evicting
     * examined objects that meet the criteria for eviction. If
     * <code>testWhileIdle</code> is true, examined objects are validated
     * when visited (and removed if invalid); otherwise only objects that
     * have been idle for more than <code>minEvicableIdleTimeMillis</code>
     * are removed.</p>
     *
     * @throws Exception when there is a problem evicting idle objects.
     */
    abstract void evict();

    /**
     * Returns the {@link EvictionPolicy} defined for this pool.
     *
     * @since 2.6.0 Changed access from protected to public.
     */
    EvictionPolicy!(T) getEvictionPolicy() {
        return evictionPolicy;
    }

    /**
     * Verifies that the pool is open.
     * @throws IllegalStateException if the pool is closed.
     */
    void assertOpen(){
        if (isClosed()) {
            throw new IllegalStateException("Pool not open");
        }
    }

    /**
     * <p>Starts the evictor with the given delay. If there is an evictor
     * running when this method is called, it is stopped and replaced with a
     * new evictor with the specified delay.</p>
     *
     * <p>This method needs to be final, since it is called from a constructor.
     * See POOL-195.</p>
     *
     * @param delay time in milliseconds before start and between eviction runs
     */
    void startEvictor(long delay) {
        synchronized (evictionLock) {
            EvictionTimer.cancel(evictor, evictorShutdownTimeoutMillis, TimeUnit.MILLISECONDS);
            evictor = null;
            evictionIterator = null;
            if (delay > 0) {
                evictor = new Evictor();
                EvictionTimer.schedule(evictor, delay, delay);
            }
        }
    }

    /**
     * Stops the evictor.
     */
    void stopEvitor() {
        startEvictor(-1L);
    }
    /**
     * Tries to ensure that the configured minimum number of idle instances are
     * available in the pool.
     * @throws Exception if an error occurs creating idle instances
     */
    abstract void ensureMinIdle();


    // Monitoring (primarily JMX) related methods

    /**
     * Provides the name under which the pool has been registered with the
     * platform MBean server or <code>null</code> if the pool has not been
     * registered.
     * @return the JMX name
     */
    ObjectName getJmxName() {
        return objectName;
    }

    /**
     * Provides the stack trace for the call that created this pool. JMX
     * registration may trigger a memory leak so it is important that pools are
     * deregistered when no longer used by calling the {@link #close()} method.
     * This method is provided to assist with identifying code that creates but
     * does not close it thereby creating a memory leak.
     * @return pool creation stack trace
     */
    string getCreationStackTrace() {
        return creationStackTrace;
    }

    /**
     * The total number of objects successfully borrowed from this pool over the
     * lifetime of the pool.
     * @return the borrowed object count
     */
    long getBorrowedCount() {
        return borrowedCount.get();
    }

    /**
     * The total number of objects returned to this pool over the lifetime of
     * the pool. This excludes attempts to return the same object multiple
     * times.
     * @return the returned object count
     */
    long getReturnedCount() {
        return returnedCount.get();
    }

    /**
     * The total number of objects created for this pool over the lifetime of
     * the pool.
     * @return the created object count
     */
    long getCreatedCount() {
        return createdCount.get();
    }

    /**
     * The total number of objects destroyed by this pool over the lifetime of
     * the pool.
     * @return the destroyed object count
     */
    long getDestroyedCount() {
        return destroyedCount.get();
    }

    /**
     * The total number of objects destroyed by the evictor associated with this
     * pool over the lifetime of the pool.
     * @return the evictor destroyed object count
     */
    long getDestroyedByEvictorCount() {
        return destroyedByEvictorCount.get();
    }

    /**
     * The total number of objects destroyed by this pool as a result of failing
     * validation during <code>borrowObject()</code> over the lifetime of the
     * pool.
     * @return validation destroyed object count
     */
    long getDestroyedByBorrowValidationCount() {
        return destroyedByBorrowValidationCount.get();
    }

    /**
     * The mean time objects are active for based on the last {@link
     * #MEAN_TIMING_STATS_CACHE_SIZE} objects returned to the pool.
     * @return mean time an object has been checked out from the pool among
     * recently returned objects
     */
    long getMeanActiveTimeMillis() {
        return activeTimes.getMean();
    }

    /**
     * The mean time objects are idle for based on the last {@link
     * #MEAN_TIMING_STATS_CACHE_SIZE} objects borrowed from the pool.
     * @return mean time an object has been idle in the pool among recently
     * borrowed objects
     */
    long getMeanIdleTimeMillis() {
        return idleTimes.getMean();
    }

    /**
     * The mean time threads wait to borrow an object based on the last {@link
     * #MEAN_TIMING_STATS_CACHE_SIZE} objects borrowed from the pool.
     * @return mean time in milliseconds that a recently served thread has had
     * to wait to borrow an object from the pool
     */
    long getMeanBorrowWaitTimeMillis() {
        return waitTimes.getMean();
    }

    /**
     * The maximum time a thread has waited to borrow objects from the pool.
     * @return maximum wait time in milliseconds since the pool was created
     */
    long getMaxBorrowWaitTimeMillis() {
        return maxBorrowWaitTimeMillis.get();
    }

    /**
     * The number of instances currently idle in this pool.
     * @return count of instances available for checkout from the pool
     */
    abstract int getNumIdle();

    /**
     * The listener used (if any) to receive notifications of exceptions
     * unavoidably swallowed by the pool.
     *
     * @return The listener or <code>null</code> for no listener
     */
    SwallowedExceptionListener getSwallowedExceptionListener() {
        return swallowedExceptionListener;
    }

    /**
     * The listener used (if any) to receive notifications of exceptions
     * unavoidably swallowed by the pool.
     *
     * @param swallowedExceptionListener    The listener or <code>null</code>
     *                                      for no listener
     */
    void setSwallowedExceptionListener(
            SwallowedExceptionListener swallowedExceptionListener) {
        this.swallowedExceptionListener = swallowedExceptionListener;
    }

    /**
     * Swallows an exception and notifies the configured listener for swallowed
     * exceptions queue.
     *
     * @param swallowException exception to be swallowed
     */
    void swallowException(Exception swallowException) {
        SwallowedExceptionListener listener = getSwallowedExceptionListener();

        if (listener is null) {
            return;
        }

        try {
            listener.onSwallowException(swallowException);
        } catch (VirtualMachineError e) {
            throw e;
        } catch (Throwable t) {
            // Ignore. Enjoy the irony.
        }
    }

    /**
     * Updates statistics after an object is borrowed from the pool.
     * @param p object borrowed from the pool
     * @param waitTime time (in milliseconds) that the borrowing thread had to wait
     */
    void updateStatsBorrow(PooledObject!(T) p, long waitTime) {
        borrowedCount.incrementAndGet();
        idleTimes.add(p.getIdleTimeMillis());
        waitTimes.add(waitTime);

        // lock-free optimistic-locking maximum
        long currentMax;
        do {
            currentMax = maxBorrowWaitTimeMillis.get();
            if (currentMax >= waitTime) {
                break;
            }
        } while (!maxBorrowWaitTimeMillis.compareAndSet(currentMax, waitTime));
    }

    /**
     * Updates statistics after an object is returned to the pool.
     * @param activeTime the amount of time (in milliseconds) that the returning
     * object was checked out
     */
    void updateStatsReturn(long activeTime) {
        returnedCount.incrementAndGet();
        activeTimes.add(activeTime);
    }

    /**
     * Marks the object as returning to the pool.
     * @param pooledObject instance to return to the keyed pool
     */
    protected void markReturningState(PooledObject!(T) pooledObject) {
        synchronized(pooledObject) {
            PooledObjectState state = pooledObject.getState();
            if (state != PooledObjectState.ALLOCATED) {
                throw new IllegalStateException(
                        "Object has already been returned to this pool or is invalid");
            }
            pooledObject.markReturning(); // Keep from being marked abandoned
        }
    }

    /**
     * Unregisters this pool's MBean.
     */
    void jmxUnregister() {
        // if (objectName !is null) {
        //     try {
        //         ManagementFactory.getPlatformMBeanServer().unregisterMBean(
        //                 objectName);
        //     } catch (MBeanRegistrationException | InstanceNotFoundException e) {
        //         swallowException(e);
        //     }
        // }
        implementationMissing(false);
    }

    /**
     * Registers the pool with the platform MBean server.
     * The registered name will be
     * <code>jmxNameBase + jmxNamePrefix + i</code> where i is the least
     * integer greater than or equal to 1 such that the name is not already
     * registered. Swallows MBeanRegistrationException, NotCompliantMBeanException
     * returning null.
     *
     * @param config Pool configuration
     * @param jmxNameBase default base JMX name for this pool
     * @param jmxNamePrefix name prefix
     * @return registered ObjectName, null if registration fails
     */
    private ObjectName jmxRegister(BaseObjectPoolConfig!(T) config,
            string jmxNameBase, string jmxNamePrefix) {
        // ObjectName newObjectName = null;
        // MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
        // int i = 1;
        // bool registered = false;
        // string base = config.getJmxNameBase();
        // if (base is null) {
        //     base = jmxNameBase;
        // }
        // while (!registered) {
        //     try {
        //         ObjectName objName;
        //         // Skip the numeric suffix for the first pool in case there is
        //         // only one so the names are cleaner.
        //         if (i == 1) {
        //             objName = new ObjectName(base + jmxNamePrefix);
        //         } else {
        //             objName = new ObjectName(base + jmxNamePrefix + i);
        //         }
        //         mbs.registerMBean(this, objName);
        //         newObjectName = objName;
        //         registered = true;
        //     } catch (MalformedObjectNameException e) {
        //         if (BaseObjectPoolConfig.DEFAULT_JMX_NAME_PREFIX.equals(
        //                 jmxNamePrefix) && jmxNameBase == base) {
        //             // Shouldn't happen. Skip registration if it does.
        //             registered = true;
        //         } else {
        //             // Must be an invalid name. Use the defaults instead.
        //             jmxNamePrefix =
        //                     BaseObjectPoolConfig.DEFAULT_JMX_NAME_PREFIX;
        //             base = jmxNameBase;
        //         }
        //     } catch (InstanceAlreadyExistsException e) {
        //         // Increment the index and try again
        //         i++;
        //     } catch (MBeanRegistrationException | NotCompliantMBeanException e) {
        //         // Shouldn't happen. Skip registration if it does.
        //         registered = true;
        //     }
        // }
        // return newObjectName;
        implementationMissing(false);
        return null;
    }

    /**
     * Gets the stack trace of an exception as a string.
     * @param e exception to trace
     * @return exception stack trace as a string
     */
    private string getStackTrace(Exception e) {
        // Need the exception in string form to prevent the retention of
        // references to classes in the stack trace that could trigger a memory
        // leak in a container environment.
        Writer w = new StringWriter();
        PrintWriter pw = new PrintWriter(w);
        e.printStackTrace(pw);
        return w.toString();
    }

    // Inner classes

    /**
     * The idle object evictor {@link TimerTask}.
     *
     * @see GenericKeyedObjectPool#setTimeBetweenEvictionRunsMillis
     */
    class Evictor : Runnable {

        private IFuture scheduledFuture;

        /**
         * Run pool maintenance.  Evict objects qualifying for eviction and then
         * ensure that the minimum number of idle instances are available.
         * Since the Timer that invokes Evictors is shared for all Pools but
         * pools may exist in different class loaders, the Evictor ensures that
         * any actions taken are under the class loader of the factory
         * associated with the pool.
         */
        override
        void run() {
            ClassLoader savedClassLoader =
                    Thread.getThis()().getContextClassLoader();
            try {
                if (factoryClassLoader !is null) {
                    // Set the class loader for the factory
                    ClassLoader cl = factoryClassLoader.get();
                    if (cl is null) {
                        // The pool has been dereferenced and the class loader
                        // GC'd. Cancel this timer so the pool can be GC'd as
                        // well.
                        cancel();
                        return;
                    }
                    Thread.getThis()().setContextClassLoader(cl);
                }

                // Evict from the pool
                try {
                    evict();
                } catch(Exception e) {
                    swallowException(e);
                } catch(OutOfMemoryError oome) {
                    // Log problem but give evictor thread a chance to continue
                    // in case error is recoverable
                    oome.printStackTrace(System.err);
                }
                // Re-create idle instances.
                try {
                    ensureMinIdle();
                } catch (Exception e) {
                    swallowException(e);
                }
            } finally {
                // Restore the previous CCL
                Thread.getThis()().setContextClassLoader(savedClassLoader);
            }
        }


        void setScheduledFuture(IFuture scheduledFuture) {
            this.scheduledFuture = scheduledFuture;
        }


        void cancel() {
            scheduledFuture.cancel(false);
        }
    }

    /**
     * Maintains a cache of values for a single metric and reports
     * statistics on the cached values.
     */
    private class StatsStore {

        private long[] values;
        private int size;
        private int index;

        /**
         * Create a StatsStore with the given cache size.
         *
         * @param size number of values to maintain in the cache.
         */
        this(int size) {
            this.size = size;
            values = new long[size];
            for (int i = 0; i < size; i++) {
                values[i] = -1;
            }
        }

        /**
         * Adds a value to the cache.  If the cache is full, one of the
         * existing values is replaced by the new value.
         *
         * @param value new value to add to the cache.
         */
        void add(long value) { // synchronized
            values[index].set(value);
            index++;
            if (index == size) {
                index = 0;
            }
        }

        /**
         * Returns the mean of the cached values.
         *
         * @return the mean of the cache, truncated to long
         */
        long getMean() {
            double result = 0;
            int counter = 0;
            for (int i = 0; i < size; i++) {
                long value = values[i].get();
                if (value != -1) {
                    counter++;
                    result = result * ((counter - 1) / cast(double) counter) +
                            value/cast(double) counter;
                }
            }
            return cast(long) result;
        }

        override
        string toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("StatsStore [values=");
            builder.append(Arrays.toString(values));
            builder.append(", size=");
            builder.append(size);
            builder.append(", index=");
            builder.append(index);
            builder.append("]");
            return builder.toString();
        }
    }

    /**
     * The idle object eviction iterator. Holds a reference to the idle objects.
     */
    class EvictionIterator : Iterator!(PooledObject!(T)) {

        private Deque!(PooledObject!(T)) idleObjects;
        private Iterator!(PooledObject!(T)) idleObjectIterator;

        /**
         * Create an EvictionIterator for the provided idle instance deque.
         * @param idleObjects underlying deque
         */
        this(Deque!(PooledObject!(T)) idleObjects) {
            this.idleObjects = idleObjects;

            if (getLifo()) {
                idleObjectIterator = idleObjects.descendingIterator();
            } else {
                idleObjectIterator = idleObjects.iterator();
            }
        }

        /**
         * Returns the idle object deque referenced by this iterator.
         * @return the idle object deque
         */
        Deque!(PooledObject!(T)) getIdleObjects() {
            return idleObjects;
        }

        /** {@inheritDoc} */
        override
        bool hasNext() {
            return idleObjectIterator.hasNext();
        }

        /** {@inheritDoc} */
        override
        PooledObject!(T) next() {
            return idleObjectIterator.next();
        }

        /** {@inheritDoc} */
        override
        void remove() {
            idleObjectIterator.remove();
        }

    }

    /**
     * Wrapper for objects under management by the pool.
     *
     * GenericObjectPool and GenericKeyedObjectPool maintain references to all
     * objects under management using maps keyed on the objects. This wrapper
     * class ensures that objects can work as hash keys.
     *
     * @param <T> type of objects in the pool
     */
    static class IdentityWrapper(T) {
        /** Wrapped object */
        private T instance;

        /**
         * Create a wrapper for an instance.
         *
         * @param instance object to wrap
         */
        this(T instance) {
            this.instance = instance;
        }

        override
        size_t toHash() @trusted nothrow {
            return System.identityHashCode(instance);
        }

        override
        bool opEquals(Object other) {
            IdentityWrapper iw = cast(IdentityWrapper)other;
            if(iw is null) return false;

            return iw.instance == instance;
        }

        /**
         * @return the wrapped object
         */
        T getObject() {
            return instance;
        }

        override
        string toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("IdentityWrapper [instance=");
            builder.append(instance);
            builder.append("]");
            return builder.toString();
        }
    }

    override
    protected void toStringAppendFields(StringBuilder builder) {
        builder.append("maxTotal=");
        builder.append(maxTotal);
        builder.append(", blockWhenExhausted=");
        builder.append(blockWhenExhausted);
        builder.append(", maxWaitMillis=");
        builder.append(maxWaitMillis);
        builder.append(", lifo=");
        builder.append(lifo);
        builder.append(", fairness=");
        builder.append(fairness);
        builder.append(", testOnCreate=");
        builder.append(testOnCreate);
        builder.append(", testOnBorrow=");
        builder.append(testOnBorrow);
        builder.append(", testOnReturn=");
        builder.append(testOnReturn);
        builder.append(", testWhileIdle=");
        builder.append(testWhileIdle);
        builder.append(", timeBetweenEvictionRunsMillis=");
        builder.append(timeBetweenEvictionRunsMillis);
        builder.append(", numTestsPerEvictionRun=");
        builder.append(numTestsPerEvictionRun);
        builder.append(", minEvictableIdleTimeMillis=");
        builder.append(minEvictableIdleTimeMillis);
        builder.append(", softMinEvictableIdleTimeMillis=");
        builder.append(softMinEvictableIdleTimeMillis);
        builder.append(", evictionPolicy=");
        builder.append(evictionPolicy);
        builder.append(", closeLock=");
        builder.append(closeLock);
        builder.append(", closed=");
        builder.append(closed);
        builder.append(", evictionLock=");
        builder.append(evictionLock);
        builder.append(", evictor=");
        builder.append(evictor);
        builder.append(", evictionIterator=");
        builder.append(evictionIterator);
        builder.append(", factoryClassLoader=");
        builder.append(factoryClassLoader);
        builder.append(", oname=");
        builder.append(objectName);
        builder.append(", creationStackTrace=");
        builder.append(creationStackTrace);
        builder.append(", borrowedCount=");
        builder.append(borrowedCount);
        builder.append(", returnedCount=");
        builder.append(returnedCount);
        builder.append(", createdCount=");
        builder.append(createdCount);
        builder.append(", destroyedCount=");
        builder.append(destroyedCount);
        builder.append(", destroyedByEvictorCount=");
        builder.append(destroyedByEvictorCount);
        builder.append(", destroyedByBorrowValidationCount=");
        builder.append(destroyedByBorrowValidationCount);
        builder.append(", activeTimes=");
        builder.append(activeTimes);
        builder.append(", idleTimes=");
        builder.append(idleTimes);
        builder.append(", waitTimes=");
        builder.append(waitTimes);
        builder.append(", maxBorrowWaitTimeMillis=");
        builder.append(maxBorrowWaitTimeMillis);
        builder.append(", swallowedExceptionListener=");
        builder.append(swallowedExceptionListener);
    }


}
