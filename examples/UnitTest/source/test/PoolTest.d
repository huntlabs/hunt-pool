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

module test.PoolTest;

import hunt.pool.PooledObject;
import hunt.pool.PooledObjectFactory;

import hunt.pool.impl.DefaultPooledObject;
import hunt.pool.impl.GenericObjectPool;
import hunt.pool.impl.GenericObjectPoolConfig;
// import org.junit.Ignore;
// import org.junit.Test;

import hunt.concurrency.thread;
import hunt.Exceptions;

import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.UnitTest;

import core.thread;
import core.time;


class PoolTest {
    private enum string COMMONS_POOL_EVICTIONS_TIMER_THREAD_NAME = "commons-pool-EvictionTimer";
    private enum long EVICTION_PERIOD_IN_MILLIS = 100;


    @Test
    void testPool(){
        GenericObjectPoolConfig poolConfig = new GenericObjectPoolConfig();
        poolConfig.setTestWhileIdle(true /* testWhileIdle */);
        PooledFooFactory pooledFooFactory = new PooledFooFactory();

        GenericObjectPool!(Foo) pool = new GenericObjectPool!(Foo)(pooledFooFactory, poolConfig); 
        pool.setTimeBetweenEvictionRunsMillis(EVICTION_PERIOD_IN_MILLIS);
        pool.addObject();

        trace("running here");
        try {
            Thread.sleep(EVICTION_PERIOD_IN_MILLIS.msecs);
        } catch (InterruptedException e) {
            ThreadEx.interrupted();
        }
        trace("running here");

        Thread[] threads = Thread.getAll(); //new Thread[Thread.activeCount()];
        // Thread.enumerate(threads);
        foreach(Thread thread ; threads) {
            if (thread is null) {
                continue;
            }
            string name = thread.name();
            // assertFalse(name, name.contains(COMMONS_POOL_EVICTIONS_TIMER_THREAD_NAME));
            tracef("name: %s, isRunning: %s, isDaemon: %s", 
                name, thread.isRunning(), thread.isDaemon());
        }
    }
}



private class Foo {
}

private class PooledFooFactory : PooledObjectFactory!(Foo) {
    private enum long VALIDATION_WAIT_IN_MILLIS = 1000;

    override
    IPooledObject makeObject(){
        return new DefaultPooledObject!(Foo)(new Foo());
    }

    override
    void destroyObject(IPooledObject pooledObject){
    }

    override
    bool validateObject(IPooledObject pooledObject) {
        info("running here");
        try {
            Thread.sleep(VALIDATION_WAIT_IN_MILLIS.msecs);
        } catch (InterruptedException e) {
            ThreadEx.interrupted();
        }
        info("running here");
        return false;
    }

    override
    void activateObject(IPooledObject pooledObject){
    }

    override
    void passivateObject(IPooledObject pooledObject){
    }
}