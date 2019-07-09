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
module hunt.pool.impl.GenericObjectPoolMXBean;

import hunt.pool.impl.DefaultPooledObjectInfo;

import hunt.collection.Set;

/**
 * Defines the methods that will be made available via JMX.
 *
 * NOTE: This interface exists only to define those attributes and methods that
 *       will be made available via JMX. It must not be implemented by clients
 *       as it is subject to change between major, minor and patch version
 *       releases of commons pool. Clients that implement this interface may
 *       not, therefore, be able to upgrade to a new minor or patch release
 *       without requiring code changes.
 *
 */
interface GenericObjectPoolMXBean {

    // Getters for basic configuration settings

    /**
     * See {@link GenericObjectPool#getBlockWhenExhausted()}
     * @return See {@link GenericObjectPool#getBlockWhenExhausted()}
     */
    bool getBlockWhenExhausted();

    /**
     * See {@link GenericObjectPool#getLifo()}
     * @return See {@link GenericObjectPool#getLifo()}
     */
    bool getFairness();

    /**
     * See {@link GenericObjectPool#getFairness()}
     * @return See {@link GenericObjectPool#getFairness()}
     */
    bool getLifo();

    /**
     * See {@link GenericObjectPool#getMaxIdle()}
     * @return See {@link GenericObjectPool#getMaxIdle()}
     */
    int getMaxIdle();

    /**
     * See {@link GenericObjectPool#getMaxTotal()}
     * @return See {@link GenericObjectPool#getMaxTotal()}
     */
    int getMaxTotal();

    /**
     * See {@link GenericObjectPool#getMaxWaitMillis()}
     * @return See {@link GenericObjectPool#getMaxWaitMillis()}
     */
    long getMaxWaitMillis();

    /**
     * See {@link GenericObjectPool#getMinEvictableIdleTimeMillis()}
     * @return See {@link GenericObjectPool#getMinEvictableIdleTimeMillis()}
     */
    long getMinEvictableIdleTimeMillis();

    /**
     * See {@link GenericObjectPool#getMinIdle()}
     * @return See {@link GenericObjectPool#getMinIdle()}
     */
    int getMinIdle();

    /**
     * See {@link GenericObjectPool#getNumActive()}
     * @return See {@link GenericObjectPool#getNumActive()}
     */
    int getNumActive();

    /**
     * See {@link GenericObjectPool#getNumIdle()}
     * @return See {@link GenericObjectPool#getNumIdle()}
     */
    int getNumIdle();

    /**
     * See {@link GenericObjectPool#getNumTestsPerEvictionRun()}
     * @return See {@link GenericObjectPool#getNumTestsPerEvictionRun()}
     */
    int getNumTestsPerEvictionRun();

    /**
     * See {@link GenericObjectPool#getTestOnCreate()}
     * @return See {@link GenericObjectPool#getTestOnCreate()}
     */
    bool getTestOnCreate();

    /**
     * See {@link GenericObjectPool#getTestOnBorrow()}
     * @return See {@link GenericObjectPool#getTestOnBorrow()}
     */
    bool getTestOnBorrow();

    /**
     * See {@link GenericObjectPool#getTestOnReturn()}
     * @return See {@link GenericObjectPool#getTestOnReturn()}
     */
    bool getTestOnReturn();

    /**
     * See {@link GenericObjectPool#getTestWhileIdle()}
     * @return See {@link GenericObjectPool#getTestWhileIdle()}
     */
    bool getTestWhileIdle();

    /**
     * See {@link GenericObjectPool#getTimeBetweenEvictionRunsMillis()}
     * @return See {@link GenericObjectPool#getTimeBetweenEvictionRunsMillis()}
     */
    long getTimeBetweenEvictionRunsMillis();

    /**
     * See {@link GenericObjectPool#isClosed()}
     * @return See {@link GenericObjectPool#isClosed()}
     */
    bool isClosed();

    // Getters for monitoring attributes

    /**
     * See {@link GenericObjectPool#getBorrowedCount()}
     * @return See {@link GenericObjectPool#getBorrowedCount()}
     */
    long getBorrowedCount();

    /**
     * See {@link GenericObjectPool#getReturnedCount()}
     * @return See {@link GenericObjectPool#getReturnedCount()}
     */
    long getReturnedCount();

    /**
     * See {@link GenericObjectPool#getCreatedCount()}
     * @return See {@link GenericObjectPool#getCreatedCount()}
     */
    long getCreatedCount();

    /**
     * See {@link GenericObjectPool#getDestroyedCount()}
     * @return See {@link GenericObjectPool#getDestroyedCount()}
     */
    long getDestroyedCount();

    /**
     * See {@link GenericObjectPool#getDestroyedByEvictorCount()}
     * @return See {@link GenericObjectPool#getDestroyedByEvictorCount()}
     */
    long getDestroyedByEvictorCount();

    /**
     * See {@link GenericObjectPool#getDestroyedByBorrowValidationCount()}
     * @return See {@link GenericObjectPool#getDestroyedByBorrowValidationCount()}
     */
    long getDestroyedByBorrowValidationCount();

    /**
     * See {@link GenericObjectPool#getMeanActiveTimeMillis()}
     * @return See {@link GenericObjectPool#getMeanActiveTimeMillis()}
     */
    long getMeanActiveTimeMillis();

    /**
     * See {@link GenericObjectPool#getMeanIdleTimeMillis()}
     * @return See {@link GenericObjectPool#getMeanIdleTimeMillis()}
     */
    long getMeanIdleTimeMillis();

    /**
     * See {@link GenericObjectPool#getMeanBorrowWaitTimeMillis()}
     * @return See {@link GenericObjectPool#getMeanBorrowWaitTimeMillis()}
     */
    long getMeanBorrowWaitTimeMillis();

    /**
     * See {@link GenericObjectPool#getMaxBorrowWaitTimeMillis()}
     * @return See {@link GenericObjectPool#getMaxBorrowWaitTimeMillis()}
     */
    long getMaxBorrowWaitTimeMillis();

    /**
     * See {@link GenericObjectPool#getCreationStackTrace()}
     * @return See {@link GenericObjectPool#getCreationStackTrace()}
     */
    string getCreationStackTrace();

    /**
     * See {@link GenericObjectPool#getNumWaiters()}
     * @return See {@link GenericObjectPool#getNumWaiters()}
     */
    int getNumWaiters();

    // Getters for abandoned object removal configuration

    /**
     * See {@link GenericObjectPool#isAbandonedConfig()}
     * @return See {@link GenericObjectPool#isAbandonedConfig()}
     */
    bool isAbandonedConfig();

    /**
     * See {@link GenericObjectPool#getLogAbandoned()}
     * @return See {@link GenericObjectPool#getLogAbandoned()}
     */
    bool getLogAbandoned();

    /**
     * See {@link GenericObjectPool#getRemoveAbandonedOnBorrow()}
     * @return See {@link GenericObjectPool#getRemoveAbandonedOnBorrow()}
     */
    bool getRemoveAbandonedOnBorrow();

    /**
     * See {@link GenericObjectPool#getRemoveAbandonedOnMaintenance()}
     * @return See {@link GenericObjectPool#getRemoveAbandonedOnMaintenance()}
     */
    bool getRemoveAbandonedOnMaintenance();

    /**
     * See {@link GenericObjectPool#getRemoveAbandonedTimeout()}
     * @return See {@link GenericObjectPool#getRemoveAbandonedTimeout()}
     */
    int getRemoveAbandonedTimeout();

    /**
     * See {@link GenericObjectPool#getFactoryType()}
     * @return See {@link GenericObjectPool#getFactoryType()}
     */
    string getFactoryType();

    /**
     * See {@link GenericObjectPool#listAllObjects()}
     * @return See {@link GenericObjectPool#listAllObjects()}
     */
    Set!(DefaultPooledObjectInfo) listAllObjects();
}
