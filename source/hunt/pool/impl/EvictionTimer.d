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
module hunt.pool.impl.EvictionTimer;

import hunt.pool.impl.BaseGenericObjectPool;

import hunt.concurrency.thread;
import hunt.concurrency.Delayed;
import hunt.concurrency.Future;
import hunt.concurrency.ScheduledThreadPoolExecutor;
import hunt.concurrency.ThreadFactory;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.Runnable;
import hunt.util.StringBuilder;

import core.thread;
import core.time;

/**
 * Provides a shared idle object eviction timer for all pools.
 * <p>
 * This class is currently implemented using {@link ScheduledThreadPoolExecutor}. This implementation may change in any
 * future release. This class keeps track of how many pools are using it. If no pools are using the timer, it is
 * cancelled. This prevents a thread being left running which, in application server environments, can lead to memory
 * leads and/or prevent applications from shutting down or reloading cleanly.
 * </p>
 * <p>
 * This class has package scope to prevent its inclusion in the pool public API. The class declaration below should
 * *not* be changed to public.
 * </p>
 * <p>
 * This class is intended to be thread-safe.
 * </p>
 *
 */
class EvictionTimer {

    /** Executor instance */
    private __gshared ScheduledThreadPoolExecutor executor; //@GuardedBy("EvictionTimer.class")

    /** Prevent instantiation */
    private this() {
        // Hide the default constructor
    }


    /**
     */
    override
    string toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("EvictionTimer []");
        return builder.toString();
    }


    /**
     * Add the specified eviction task to the timer. Tasks that are added with a
     * call to this method *must* call {@link #cancel(TimerTask)} to cancel the
     * task to prevent memory and/or thread leaks in application server
     * environments.
     *
     * @param task      Task to be scheduled
     * @param delay     Delay in milliseconds before task is executed
     * @param period    Time in milliseconds between executions
     */
    static void schedule(BaseGenericObjectPool.Evictor task, long delay, long period) {
        if (executor is null) {
            executor = new ScheduledThreadPoolExecutor(1, new EvictorThreadFactory());
            executor.setRemoveOnCancelPolicy(true);
        }
        IFuture scheduledFuture =
                executor.scheduleWithFixedDelay(task, delay.msecs, period.msecs);
        task.setScheduledFuture(scheduledFuture);
    }

    /**
     * Remove the specified eviction task from the timer.
     *
     * @param evictor      Task to be cancelled
     * @param timeout   If the associated executor is no longer required, how
     *                  long should this thread wait for the executor to
     *                  terminate?
     * @param unit      The units for the specified timeout
     */
    static synchronized void cancel(BaseGenericObjectPool.Evictor evictor, Duration timeout) {
        if (evictor !is null) {
            evictor.cancel();
        }
        if (executor !is null && executor.getQueue().isEmpty()) {
            executor.shutdown();
            try {
                // executor.awaitTermination(timeout);
                // TODO: Tasks pending completion -@zhangxueping at 2019-12-06T16:11:54+08:00
                // 
            } catch (InterruptedException e) {
                version(HUNT_DEBUG) warning(e.msg);
                // Swallow
                // Significant API changes would be required to propagate this
            }
            executor.setCorePoolSize(0);
            executor = null;
        }
    }

    /**
     * Thread factory that creates a daemon thread, with the context class loader from this class.
     */
    private static class EvictorThreadFactory : ThreadFactory {

        Thread newThread(Runnable runnable) {
            ThreadEx thread = new ThreadEx(null, runnable, "commons-pool-evictor-thread");
            thread.setDaemon(true); // POOL-363 - Required for applications using Runtime.addShutdownHook(). --joshlandin 03.27.2019
            // AccessController.doPrivileged(new PrivilegedAction!(Void)() {
            //     override
            //     Void run() {
            //         thread.setContextClassLoader(EvictorThreadFactory.class.getClassLoader());
            //         return null;
            //     }
            // });

            return thread;
        }
    }
}
