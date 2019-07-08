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
module hunt.pool.impl.BaseObjectPoolConfig;

import hunt.pool.BaseObject;

/**
 * Provides the implementation for the common attributes shared by the
 * sub-classes. New instances of this class will be created using the defaults
 * defined by the public constants.
 * <p>
 * This class is not thread-safe.
 * </p>
 *
 * @param <T> Type of element pooled.
 */
abstract class BaseObjectPoolConfig!(T) extends BaseObject implements Cloneable {

    /**
     * The default value for the {@code lifo} configuration attribute.
     * @see GenericObjectPool#getLifo()
     * @see GenericKeyedObjectPool#getLifo()
     */
    static final boolean DEFAULT_LIFO = true;

    /**
     * The default value for the {@code fairness} configuration attribute.
     * @see GenericObjectPool#getFairness()
     * @see GenericKeyedObjectPool#getFairness()
     */
    static final boolean DEFAULT_FAIRNESS = false;

    /**
     * The default value for the {@code maxWait} configuration attribute.
     * @see GenericObjectPool#getMaxWaitMillis()
     * @see GenericKeyedObjectPool#getMaxWaitMillis()
     */
    static final long DEFAULT_MAX_WAIT_MILLIS = -1L;

    /**
     * The default value for the {@code minEvictableIdleTimeMillis}
     * configuration attribute.
     * @see GenericObjectPool#getMinEvictableIdleTimeMillis()
     * @see GenericKeyedObjectPool#getMinEvictableIdleTimeMillis()
     */
    static final long DEFAULT_MIN_EVICTABLE_IDLE_TIME_MILLIS =
            1000L * 60L * 30L;

    /**
     * The default value for the {@code softMinEvictableIdleTimeMillis}
     * configuration attribute.
     * @see GenericObjectPool#getSoftMinEvictableIdleTimeMillis()
     * @see GenericKeyedObjectPool#getSoftMinEvictableIdleTimeMillis()
     */
    static final long DEFAULT_SOFT_MIN_EVICTABLE_IDLE_TIME_MILLIS = -1;

    /**
     * The default value for {@code evictorShutdownTimeoutMillis} configuration
     * attribute.
     * @see GenericObjectPool#getEvictorShutdownTimeoutMillis()
     * @see GenericKeyedObjectPool#getEvictorShutdownTimeoutMillis()
     */
    static final long DEFAULT_EVICTOR_SHUTDOWN_TIMEOUT_MILLIS =
            10L * 1000L;

    /**
     * The default value for the {@code numTestsPerEvictionRun} configuration
     * attribute.
     * @see GenericObjectPool#getNumTestsPerEvictionRun()
     * @see GenericKeyedObjectPool#getNumTestsPerEvictionRun()
     */
    enum int DEFAULT_NUM_TESTS_PER_EVICTION_RUN = 3;

    /**
     * The default value for the {@code testOnCreate} configuration attribute.
     * @see GenericObjectPool#getTestOnCreate()
     * @see GenericKeyedObjectPool#getTestOnCreate()
     *
     */
    static final boolean DEFAULT_TEST_ON_CREATE = false;

    /**
     * The default value for the {@code testOnBorrow} configuration attribute.
     * @see GenericObjectPool#getTestOnBorrow()
     * @see GenericKeyedObjectPool#getTestOnBorrow()
     */
    static final boolean DEFAULT_TEST_ON_BORROW = false;

    /**
     * The default value for the {@code testOnReturn} configuration attribute.
     * @see GenericObjectPool#getTestOnReturn()
     * @see GenericKeyedObjectPool#getTestOnReturn()
     */
    static final boolean DEFAULT_TEST_ON_RETURN = false;

    /**
     * The default value for the {@code testWhileIdle} configuration attribute.
     * @see GenericObjectPool#getTestWhileIdle()
     * @see GenericKeyedObjectPool#getTestWhileIdle()
     */
    static final boolean DEFAULT_TEST_WHILE_IDLE = false;

    /**
     * The default value for the {@code timeBetweenEvictionRunsMillis}
     * configuration attribute.
     * @see GenericObjectPool#getTimeBetweenEvictionRunsMillis()
     * @see GenericKeyedObjectPool#getTimeBetweenEvictionRunsMillis()
     */
    static final long DEFAULT_TIME_BETWEEN_EVICTION_RUNS_MILLIS = -1L;

    /**
     * The default value for the {@code blockWhenExhausted} configuration
     * attribute.
     * @see GenericObjectPool#getBlockWhenExhausted()
     * @see GenericKeyedObjectPool#getBlockWhenExhausted()
     */
    static final boolean DEFAULT_BLOCK_WHEN_EXHAUSTED = true;

    /**
     * The default value for enabling JMX for pools created with a configuration
     * instance.
     */
    static final boolean DEFAULT_JMX_ENABLE = true;

    /**
     * The default value for the prefix used to name JMX enabled pools created
     * with a configuration instance.
     * @see GenericObjectPool#getJmxName()
     * @see GenericKeyedObjectPool#getJmxName()
     */
    enum string DEFAULT_JMX_NAME_PREFIX = "pool";

    /**
     * The default value for the base name to use to name JMX enabled pools
     * created with a configuration instance. The default is <code>null</code>
     * which means the pool will provide the base name to use.
     * @see GenericObjectPool#getJmxName()
     * @see GenericKeyedObjectPool#getJmxName()
     */
    enum string DEFAULT_JMX_NAME_BASE = null;

    /**
     * The default value for the {@code evictionPolicyClassName} configuration
     * attribute.
     * @see GenericObjectPool#getEvictionPolicyClassName()
     * @see GenericKeyedObjectPool#getEvictionPolicyClassName()
     */
    enum string DEFAULT_EVICTION_POLICY_CLASS_NAME = typeid(DefaultEvictionPolicy).name;

    private boolean lifo = DEFAULT_LIFO;

    private boolean fairness = DEFAULT_FAIRNESS;

    private long maxWaitMillis = DEFAULT_MAX_WAIT_MILLIS;

    private long minEvictableIdleTimeMillis =
            DEFAULT_MIN_EVICTABLE_IDLE_TIME_MILLIS;

    private long evictorShutdownTimeoutMillis =
            DEFAULT_EVICTOR_SHUTDOWN_TIMEOUT_MILLIS;

    private long softMinEvictableIdleTimeMillis =
            DEFAULT_SOFT_MIN_EVICTABLE_IDLE_TIME_MILLIS;

    private int numTestsPerEvictionRun =
            DEFAULT_NUM_TESTS_PER_EVICTION_RUN;

    private EvictionPolicy!(T) evictionPolicy = null; // Only 2.6.0 applications set this

    private String evictionPolicyClassName = DEFAULT_EVICTION_POLICY_CLASS_NAME;

    private boolean testOnCreate = DEFAULT_TEST_ON_CREATE;

    private boolean testOnBorrow = DEFAULT_TEST_ON_BORROW;

    private boolean testOnReturn = DEFAULT_TEST_ON_RETURN;

    private boolean testWhileIdle = DEFAULT_TEST_WHILE_IDLE;

    private long timeBetweenEvictionRunsMillis =
            DEFAULT_TIME_BETWEEN_EVICTION_RUNS_MILLIS;

    private boolean blockWhenExhausted = DEFAULT_BLOCK_WHEN_EXHAUSTED;

    private boolean jmxEnabled = DEFAULT_JMX_ENABLE;

    // TODO Consider changing this to a single property for 3.x
    private String jmxNamePrefix = DEFAULT_JMX_NAME_PREFIX;

    private String jmxNameBase = DEFAULT_JMX_NAME_BASE;


    /**
     * Get the value for the {@code lifo} configuration attribute for pools
     * created with this configuration instance.
     *
     * @return  The current setting of {@code lifo} for this configuration
     *          instance
     *
     * @see GenericObjectPool#getLifo()
     * @see GenericKeyedObjectPool#getLifo()
     */
    boolean getLifo() {
        return lifo;
    }

    /**
     * Get the value for the {@code fairness} configuration attribute for pools
     * created with this configuration instance.
     *
     * @return  The current setting of {@code fairness} for this configuration
     *          instance
     *
     * @see GenericObjectPool#getFairness()
     * @see GenericKeyedObjectPool#getFairness()
     */
    boolean getFairness() {
        return fairness;
    }

    /**
     * Set the value for the {@code lifo} configuration attribute for pools
     * created with this configuration instance.
     *
     * @param lifo The new setting of {@code lifo}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getLifo()
     * @see GenericKeyedObjectPool#getLifo()
     */
    void setLifo(final boolean lifo) {
        this.lifo = lifo;
    }

    /**
     * Set the value for the {@code fairness} configuration attribute for pools
     * created with this configuration instance.
     *
     * @param fairness The new setting of {@code fairness}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getFairness()
     * @see GenericKeyedObjectPool#getFairness()
     */
    void setFairness(final boolean fairness) {
        this.fairness = fairness;
    }

    /**
     * Get the value for the {@code maxWait} configuration attribute for pools
     * created with this configuration instance.
     *
     * @return  The current setting of {@code maxWait} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getMaxWaitMillis()
     * @see GenericKeyedObjectPool#getMaxWaitMillis()
     */
    long getMaxWaitMillis() {
        return maxWaitMillis;
    }

    /**
     * Set the value for the {@code maxWait} configuration attribute for pools
     * created with this configuration instance.
     *
     * @param maxWaitMillis The new setting of {@code maxWaitMillis}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getMaxWaitMillis()
     * @see GenericKeyedObjectPool#getMaxWaitMillis()
     */
    void setMaxWaitMillis(final long maxWaitMillis) {
        this.maxWaitMillis = maxWaitMillis;
    }

    /**
     * Get the value for the {@code minEvictableIdleTimeMillis} configuration
     * attribute for pools created with this configuration instance.
     *
     * @return  The current setting of {@code minEvictableIdleTimeMillis} for
     *          this configuration instance
     *
     * @see GenericObjectPool#getMinEvictableIdleTimeMillis()
     * @see GenericKeyedObjectPool#getMinEvictableIdleTimeMillis()
     */
    long getMinEvictableIdleTimeMillis() {
        return minEvictableIdleTimeMillis;
    }

    /**
     * Set the value for the {@code minEvictableIdleTimeMillis} configuration
     * attribute for pools created with this configuration instance.
     *
     * @param minEvictableIdleTimeMillis The new setting of
     *        {@code minEvictableIdleTimeMillis} for this configuration instance
     *
     * @see GenericObjectPool#getMinEvictableIdleTimeMillis()
     * @see GenericKeyedObjectPool#getMinEvictableIdleTimeMillis()
     */
    void setMinEvictableIdleTimeMillis(final long minEvictableIdleTimeMillis) {
        this.minEvictableIdleTimeMillis = minEvictableIdleTimeMillis;
    }

    /**
     * Get the value for the {@code softMinEvictableIdleTimeMillis}
     * configuration attribute for pools created with this configuration
     * instance.
     *
     * @return  The current setting of {@code softMinEvictableIdleTimeMillis}
     *          for this configuration instance
     *
     * @see GenericObjectPool#getSoftMinEvictableIdleTimeMillis()
     * @see GenericKeyedObjectPool#getSoftMinEvictableIdleTimeMillis()
     */
    long getSoftMinEvictableIdleTimeMillis() {
        return softMinEvictableIdleTimeMillis;
    }

    /**
     * Set the value for the {@code softMinEvictableIdleTimeMillis}
     * configuration attribute for pools created with this configuration
     * instance.
     *
     * @param softMinEvictableIdleTimeMillis The new setting of
     *        {@code softMinEvictableIdleTimeMillis} for this configuration
     *        instance
     *
     * @see GenericObjectPool#getSoftMinEvictableIdleTimeMillis()
     * @see GenericKeyedObjectPool#getSoftMinEvictableIdleTimeMillis()
     */
    void setSoftMinEvictableIdleTimeMillis(
            final long softMinEvictableIdleTimeMillis) {
        this.softMinEvictableIdleTimeMillis = softMinEvictableIdleTimeMillis;
    }

    /**
     * Get the value for the {@code numTestsPerEvictionRun} configuration
     * attribute for pools created with this configuration instance.
     *
     * @return  The current setting of {@code numTestsPerEvictionRun} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getNumTestsPerEvictionRun()
     * @see GenericKeyedObjectPool#getNumTestsPerEvictionRun()
     */
    int getNumTestsPerEvictionRun() {
        return numTestsPerEvictionRun;
    }

    /**
     * Set the value for the {@code numTestsPerEvictionRun} configuration
     * attribute for pools created with this configuration instance.
     *
     * @param numTestsPerEvictionRun The new setting of
     *        {@code numTestsPerEvictionRun} for this configuration instance
     *
     * @see GenericObjectPool#getNumTestsPerEvictionRun()
     * @see GenericKeyedObjectPool#getNumTestsPerEvictionRun()
     */
    void setNumTestsPerEvictionRun(final int numTestsPerEvictionRun) {
        this.numTestsPerEvictionRun = numTestsPerEvictionRun;
    }

    /**
     * Get the value for the {@code evictorShutdownTimeoutMillis} configuration
     * attribute for pools created with this configuration instance.
     *
     * @return  The current setting of {@code evictorShutdownTimeoutMillis} for
     *          this configuration instance
     *
     * @see GenericObjectPool#getEvictorShutdownTimeoutMillis()
     * @see GenericKeyedObjectPool#getEvictorShutdownTimeoutMillis()
     */
    long getEvictorShutdownTimeoutMillis() {
        return evictorShutdownTimeoutMillis;
    }

    /**
     * Set the value for the {@code evictorShutdownTimeoutMillis} configuration
     * attribute for pools created with this configuration instance.
     *
     * @param evictorShutdownTimeoutMillis The new setting of
     *        {@code evictorShutdownTimeoutMillis} for this configuration
     *        instance
     *
     * @see GenericObjectPool#getEvictorShutdownTimeoutMillis()
     * @see GenericKeyedObjectPool#getEvictorShutdownTimeoutMillis()
     */
    void setEvictorShutdownTimeoutMillis(
            final long evictorShutdownTimeoutMillis) {
        this.evictorShutdownTimeoutMillis = evictorShutdownTimeoutMillis;
    }

    /**
     * Get the value for the {@code testOnCreate} configuration attribute for
     * pools created with this configuration instance.
     *
     * @return  The current setting of {@code testOnCreate} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getTestOnCreate()
     * @see GenericKeyedObjectPool#getTestOnCreate()
     *
     */
    boolean getTestOnCreate() {
        return testOnCreate;
    }

    /**
     * Set the value for the {@code testOnCreate} configuration attribute for
     * pools created with this configuration instance.
     *
     * @param testOnCreate The new setting of {@code testOnCreate}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getTestOnCreate()
     * @see GenericKeyedObjectPool#getTestOnCreate()
     *
     */
    void setTestOnCreate(final boolean testOnCreate) {
        this.testOnCreate = testOnCreate;
    }

    /**
     * Get the value for the {@code testOnBorrow} configuration attribute for
     * pools created with this configuration instance.
     *
     * @return  The current setting of {@code testOnBorrow} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getTestOnBorrow()
     * @see GenericKeyedObjectPool#getTestOnBorrow()
     */
    boolean getTestOnBorrow() {
        return testOnBorrow;
    }

    /**
     * Set the value for the {@code testOnBorrow} configuration attribute for
     * pools created with this configuration instance.
     *
     * @param testOnBorrow The new setting of {@code testOnBorrow}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getTestOnBorrow()
     * @see GenericKeyedObjectPool#getTestOnBorrow()
     */
    void setTestOnBorrow(final boolean testOnBorrow) {
        this.testOnBorrow = testOnBorrow;
    }

    /**
     * Get the value for the {@code testOnReturn} configuration attribute for
     * pools created with this configuration instance.
     *
     * @return  The current setting of {@code testOnReturn} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getTestOnReturn()
     * @see GenericKeyedObjectPool#getTestOnReturn()
     */
    boolean getTestOnReturn() {
        return testOnReturn;
    }

    /**
     * Set the value for the {@code testOnReturn} configuration attribute for
     * pools created with this configuration instance.
     *
     * @param testOnReturn The new setting of {@code testOnReturn}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getTestOnReturn()
     * @see GenericKeyedObjectPool#getTestOnReturn()
     */
    void setTestOnReturn(final boolean testOnReturn) {
        this.testOnReturn = testOnReturn;
    }

    /**
     * Get the value for the {@code testWhileIdle} configuration attribute for
     * pools created with this configuration instance.
     *
     * @return  The current setting of {@code testWhileIdle} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getTestWhileIdle()
     * @see GenericKeyedObjectPool#getTestWhileIdle()
     */
    boolean getTestWhileIdle() {
        return testWhileIdle;
    }

    /**
     * Set the value for the {@code testWhileIdle} configuration attribute for
     * pools created with this configuration instance.
     *
     * @param testWhileIdle The new setting of {@code testWhileIdle}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getTestWhileIdle()
     * @see GenericKeyedObjectPool#getTestWhileIdle()
     */
    void setTestWhileIdle(final boolean testWhileIdle) {
        this.testWhileIdle = testWhileIdle;
    }

    /**
     * Get the value for the {@code timeBetweenEvictionRunsMillis} configuration
     * attribute for pools created with this configuration instance.
     *
     * @return  The current setting of {@code timeBetweenEvictionRunsMillis} for
     *          this configuration instance
     *
     * @see GenericObjectPool#getTimeBetweenEvictionRunsMillis()
     * @see GenericKeyedObjectPool#getTimeBetweenEvictionRunsMillis()
     */
    long getTimeBetweenEvictionRunsMillis() {
        return timeBetweenEvictionRunsMillis;
    }

    /**
     * Set the value for the {@code timeBetweenEvictionRunsMillis} configuration
     * attribute for pools created with this configuration instance.
     *
     * @param timeBetweenEvictionRunsMillis The new setting of
     *        {@code timeBetweenEvictionRunsMillis} for this configuration
     *        instance
     *
     * @see GenericObjectPool#getTimeBetweenEvictionRunsMillis()
     * @see GenericKeyedObjectPool#getTimeBetweenEvictionRunsMillis()
     */
    void setTimeBetweenEvictionRunsMillis(
            final long timeBetweenEvictionRunsMillis) {
        this.timeBetweenEvictionRunsMillis = timeBetweenEvictionRunsMillis;
    }

    /**
     * Get the value for the {@code evictionPolicyClass} configuration
     * attribute for pools created with this configuration instance.
     *
     * @return  The current setting of {@code evictionPolicyClass} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getEvictionPolicy()
     * @see GenericKeyedObjectPool#getEvictionPolicy()
     */
    EvictionPolicy!(T) getEvictionPolicy() {
        return evictionPolicy;
    }

    /**
     * Get the value for the {@code evictionPolicyClassName} configuration
     * attribute for pools created with this configuration instance.
     *
     * @return  The current setting of {@code evictionPolicyClassName} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getEvictionPolicyClassName()
     * @see GenericKeyedObjectPool#getEvictionPolicyClassName()
     */
    String getEvictionPolicyClassName() {
        return evictionPolicyClassName;
    }

    /**
     * Set the value for the {@code evictionPolicyClass} configuration
     * attribute for pools created with this configuration instance.
     *
     * @param evictionPolicy The new setting of
     *        {@code evictionPolicyClass} for this configuration instance
     *
     * @see GenericObjectPool#getEvictionPolicy()
     * @see GenericKeyedObjectPool#getEvictionPolicy()
     */
    void setEvictionPolicy(final EvictionPolicy!(T) evictionPolicy) {
        this.evictionPolicy = evictionPolicy;
    }

    /**
     * Set the value for the {@code evictionPolicyClassName} configuration
     * attribute for pools created with this configuration instance.
     *
     * @param evictionPolicyClassName The new setting of
     *        {@code evictionPolicyClassName} for this configuration instance
     *
     * @see GenericObjectPool#getEvictionPolicyClassName()
     * @see GenericKeyedObjectPool#getEvictionPolicyClassName()
     */
    void setEvictionPolicyClassName(final String evictionPolicyClassName) {
        this.evictionPolicyClassName = evictionPolicyClassName;
    }

    /**
     * Get the value for the {@code blockWhenExhausted} configuration attribute
     * for pools created with this configuration instance.
     *
     * @return  The current setting of {@code blockWhenExhausted} for this
     *          configuration instance
     *
     * @see GenericObjectPool#getBlockWhenExhausted()
     * @see GenericKeyedObjectPool#getBlockWhenExhausted()
     */
    boolean getBlockWhenExhausted() {
        return blockWhenExhausted;
    }

    /**
     * Set the value for the {@code blockWhenExhausted} configuration attribute
     * for pools created with this configuration instance.
     *
     * @param blockWhenExhausted The new setting of {@code blockWhenExhausted}
     *        for this configuration instance
     *
     * @see GenericObjectPool#getBlockWhenExhausted()
     * @see GenericKeyedObjectPool#getBlockWhenExhausted()
     */
    void setBlockWhenExhausted(final boolean blockWhenExhausted) {
        this.blockWhenExhausted = blockWhenExhausted;
    }

    /**
     * Gets the value of the flag that determines if JMX will be enabled for
     * pools created with this configuration instance.
     *
     * @return  The current setting of {@code jmxEnabled} for this configuration
     *          instance
     */
    boolean getJmxEnabled() {
        return jmxEnabled;
    }

    /**
     * Sets the value of the flag that determines if JMX will be enabled for
     * pools created with this configuration instance.
     *
     * @param jmxEnabled The new setting of {@code jmxEnabled}
     *        for this configuration instance
     */
    void setJmxEnabled(final boolean jmxEnabled) {
        this.jmxEnabled = jmxEnabled;
    }

    /**
     * Gets the value of the JMX name base that will be used as part of the
     * name assigned to JMX enabled pools created with this configuration
     * instance. A value of <code>null</code> means that the pool will define
     * the JMX name base.
     *
     * @return  The current setting of {@code jmxNameBase} for this
     *          configuration instance
     */
    String getJmxNameBase() {
        return jmxNameBase;
    }

    /**
     * Sets the value of the JMX name base that will be used as part of the
     * name assigned to JMX enabled pools created with this configuration
     * instance. A value of <code>null</code> means that the pool will define
     * the JMX name base.
     *
     * @param jmxNameBase The new setting of {@code jmxNameBase}
     *        for this configuration instance
     */
    void setJmxNameBase(final String jmxNameBase) {
        this.jmxNameBase = jmxNameBase;
    }

    /**
     * Gets the value of the JMX name prefix that will be used as part of the
     * name assigned to JMX enabled pools created with this configuration
     * instance.
     *
     * @return  The current setting of {@code jmxNamePrefix} for this
     *          configuration instance
     */
    String getJmxNamePrefix() {
        return jmxNamePrefix;
    }

    /**
     * Sets the value of the JMX name prefix that will be used as part of the
     * name assigned to JMX enabled pools created with this configuration
     * instance.
     *
     * @param jmxNamePrefix The new setting of {@code jmxNamePrefix}
     *        for this configuration instance
     */
    void setJmxNamePrefix(final String jmxNamePrefix) {
        this.jmxNamePrefix = jmxNamePrefix;
    }

    override
    protected void toStringAppendFields(final StringBuilder builder) {
        builder.append("lifo=");
        builder.append(lifo);
        builder.append(", fairness=");
        builder.append(fairness);
        builder.append(", maxWaitMillis=");
        builder.append(maxWaitMillis);
        builder.append(", minEvictableIdleTimeMillis=");
        builder.append(minEvictableIdleTimeMillis);
        builder.append(", softMinEvictableIdleTimeMillis=");
        builder.append(softMinEvictableIdleTimeMillis);
        builder.append(", numTestsPerEvictionRun=");
        builder.append(numTestsPerEvictionRun);
        builder.append(", evictionPolicyClassName=");
        builder.append(evictionPolicyClassName);
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
        builder.append(", blockWhenExhausted=");
        builder.append(blockWhenExhausted);
        builder.append(", jmxEnabled=");
        builder.append(jmxEnabled);
        builder.append(", jmxNamePrefix=");
        builder.append(jmxNamePrefix);
        builder.append(", jmxNameBase=");
        builder.append(jmxNameBase);
    }
}
