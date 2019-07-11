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

module test.impl.TestGenericObjectPool;

import test.TestBaseObjectPool;

// import java.lang.management.ManagementFactory;
// import java.nio.charset.UnsupportedCharsetException;
// import java.util.ArrayList;
// import java.util.HashSet;
// import java.util.List;
// import java.util.NoSuchElementException;
// import java.util.Random;
// import java.util.Set;
// import java.util.Timer;
// import java.util.TimerTask;
// import java.util.concurrent.Semaphore;
// import java.util.concurrent.atomic.Integer;

// import javax.management.MBeanServer;
// import javax.management.ObjectName;

import hunt.pool.BasePooledObjectFactory;
import hunt.pool.ObjectPool;
import hunt.pool.PoolUtils;
import hunt.pool.PooledObject;
import hunt.pool.PooledObjectFactory;
import hunt.pool.SwallowedExceptionListener;
import hunt.pool.TestBaseObjectPool;
import hunt.pool.VisitTracker;
import hunt.pool.VisitTrackerFactory;
import hunt.pool.Waiter;
import hunt.pool.WaiterFactory;

// import org.junit.After;
// import org.junit.Assert;
// import org.junit.Before;
// import org.junit.Test;

import hunt.Integer;


// protected class AtomicIntegerFactory
//     : BasePooledObjectFactory!(Integer) {

//     private long activateLatency = 0;
//     private long passivateLatency = 0;
//     private long createLatency = 0;
//     private long destroyLatency = 0;
//     private long validateLatency = 0;

//     override
//     void activateObject(PooledObject!(Integer) p) {
//         p.getObject().incrementAndGet();
//         try {
//             Thread.sleep(activateLatency);
//         } catch (InterruptedException ex) {}
//     }

//     override
//     Integer create() {
//         try {
//             Thread.sleep(createLatency);
//         } catch (InterruptedException ex) {}
//         return new Integer(0);
//     }

//     override
//     void destroyObject(PooledObject!(Integer) p) {
//         try {
//             Thread.sleep(destroyLatency);
//         } catch (InterruptedException ex) {}
//     }

//     override
//     void passivateObject(PooledObject!(Integer) p) {
//         p.getObject().decrementAndGet();
//         try {
//             Thread.sleep(passivateLatency);
//         } catch (InterruptedException ex) {}
//     }

//     /**
//      * @param activateLatency the activateLatency to set
//      */
//     void setActivateLatency(long activateLatency) {
//         this.activateLatency = activateLatency;
//     }

//     /**
//      * @param createLatency the createLatency to set
//      */
//     void setCreateLatency(long createLatency) {
//         this.createLatency = createLatency;
//     }


//     /**
//      * @param destroyLatency the destroyLatency to set
//      */
//     void setDestroyLatency(long destroyLatency) {
//         this.destroyLatency = destroyLatency;
//     }


//     /**
//      * @param passivateLatency the passivateLatency to set
//      */
//     void setPassivateLatency(long passivateLatency) {
//         this.passivateLatency = passivateLatency;
//     }


//     /**
//      * @param validateLatency the validateLatency to set
//      */
//     void setValidateLatency(long validateLatency) {
//         this.validateLatency = validateLatency;
//     }


//     override
//     bool validateObject(PooledObject!(Integer) instance) {
//         try {
//             Thread.sleep(validateLatency);
//         } catch (InterruptedException ex) {}
//         return instance.getObject().intValue() == 1;
//     }


//     override
//     PooledObject!(Integer) wrap(Integer integer) {
//         return new DefaultPooledObject!(Integer)(integer);
//     }
// }



//     private class ConcurrentBorrowAndEvictThread : Thread {
//         private bool borrow;
//         string obj;

//         this(bool borrow) {
//             this.borrow = borrow;
//         }

//         override
//         void run() {
//             try {
//                 if (borrow) {
//                     obj = genericObjectPool.borrowObject();
//                 } else {
//                     genericObjectPool.evict();
//                 }
//             } catch (Exception e) { /* Ignore */}
//         }
//     }

//     private static class CreateErrorFactory : BasePooledObjectFactory!(string) {

//         private Semaphore semaphore = new Semaphore(0);

//         override
//         string create(){
//             semaphore.acquire();
//             throw new UnknownError("wiggle");
//         }

//         bool hasQueuedThreads() {
//             return semaphore.hasQueuedThreads();
//         }

//         void release() {
//             semaphore.release();
//         }

//         override
//         PooledObject!(string) wrap(string obj) {
//             return new DefaultPooledObject<>(obj);
//         }
//     }

//     private static class CreateFailFactory : BasePooledObjectFactory!(string) {

//         private Semaphore semaphore = new Semaphore(0);

//         override
//         string create(){
//             semaphore.acquire();
//             throw new UnsupportedCharsetException("wibble");
//         }

//         bool hasQueuedThreads() {
//             return semaphore.hasQueuedThreads();
//         }

//         void release() {
//             semaphore.release();
//         }

//         override
//         PooledObject!(string) wrap(string obj) {
//             return new DefaultPooledObject<>(obj);
//         }
//     }

//     private static class DummyFactory
//             extends BasePooledObjectFactory!(Object) {
//         override
//         Object create(){
//             return null;
//         }
//         override
//         PooledObject!(Object) wrap(Object value) {
//             return new DefaultPooledObject<>(value);
//         }
//     }

//     private static class EvictionThread!(T) extends Thread {

//         private GenericObjectPool!(T) pool;

//         EvictionThread(GenericObjectPool!(T) pool) {
//             this.pool = pool;
//         }

//         override
//         void run() {
//             try {
//                 pool.evict();
//             } catch (Exception e) {
//                 // Ignore
//             }
//         }
//     }

//     /**
//      * Factory that creates HashSets.  Note that this means
//      *  0) All instances are initially equal (not discernible by equals)
//      *  1) Instances are mutable and mutation can cause change in identity / hashcode.
//      */
//     private static class HashSetFactory
//             extends BasePooledObjectFactory!(HashSet!(string)) {
//         override
//         HashSet!(string) create(){
//             return new HashSet<>();
//         }
//         override
//         PooledObject!(HashSet!(string)) wrap(HashSet!(string) value) {
//             return new DefaultPooledObject<>(value);
//         }
//     }

//     /**
//      * Attempts to invalidate an object, swallowing IllegalStateException.
//      */
//     static class InvalidateThread : Runnable {
//         private string obj;
//         private ObjectPool!(string) pool;
//         private bool done = false;
//         InvalidateThread(ObjectPool!(string) pool, string obj) {
//             this.obj = obj;
//             this.pool = pool;
//         }
//         bool complete() {
//             return done;
//         }
//         override
//         void run() {
//             try {
//                 pool.invalidateObject(obj);
//             } catch (IllegalStateException ex) {
//                 // Ignore
//             } catch (Exception ex) {
//                 Assert.fail("Unexpected exception " + ex.toString());
//             } finally {
//                 done = true;
//             }
//         }
//     }

//     private static class InvalidFactory
//             extends BasePooledObjectFactory!(Object) {

//         override
//         Object create(){
//             return new Object();
//         }
//         override
//         bool validateObject(PooledObject!(Object) obj) {
//             try {
//                 Thread.sleep(1000);
//             } catch (InterruptedException e) {
//                 // Ignore
//             }
//             return false;
//         }

//         override
//         PooledObject!(Object) wrap(Object value) {
//             return new DefaultPooledObject<>(value);
//         }
//     }

//     static class SimpleFactory : PooledObjectFactory!(string) {
//         int makeCounter = 0;

//         int activationCounter = 0;

//         int validateCounter = 0;

//         int activeCount = 0;

//         bool evenValid = true;

//         bool oddValid = true;

//         bool exceptionOnPassivate = false;

//         bool exceptionOnActivate = false;

//         bool exceptionOnDestroy = false;

//         bool enableValidation = true;

//         long destroyLatency = 0;

//         long makeLatency = 0;

//         long validateLatency = 0;

//         int maxTotal = Integer.MAX_VALUE;

//         SimpleFactory() {
//             this(true);
//         }

//         SimpleFactory(bool valid) {
//             this(valid,valid);
//         }
//         SimpleFactory(bool evalid, bool ovalid) {
//             evenValid = evalid;
//             oddValid = ovalid;
//         }
//         override
//         void activateObject(PooledObject!(string) obj){
//             bool hurl;
//             bool evenTest;
//             bool oddTest;
//             int counter;
//             synchronized(this) {
//                 hurl = exceptionOnActivate;
//                 evenTest = evenValid;
//                 oddTest = oddValid;
//                 counter = activationCounter++;
//             }
//             if (hurl) {
//                 if (!(counter%2 == 0 ? evenTest : oddTest)) {
//                     throw new Exception();
//                 }
//             }
//         }
//         override
//         void destroyObject(PooledObject!(string) obj){
//             long waitLatency;
//             bool hurl;
//             synchronized(this) {
//                 waitLatency = destroyLatency;
//                 hurl = exceptionOnDestroy;
//             }
//             if (waitLatency > 0) {
//                 doWait(waitLatency);
//             }
//             synchronized(this) {
//                 activeCount--;
//             }
//             if (hurl) {
//                 throw new Exception();
//             }
//         }
//         private void doWait(long latency) {
//             try {
//                 Thread.sleep(latency);
//             } catch (InterruptedException ex) {
//                 // ignore
//             }
//         }
//         synchronized int getMakeCounter() {
//             return makeCounter;
//         }
//         synchronized bool isThrowExceptionOnActivate() {
//             return exceptionOnActivate;
//         }
//         synchronized bool isValidationEnabled() {
//             return enableValidation;
//         }
//         override
//         PooledObject!(string) makeObject() {
//             long waitLatency;
//             synchronized(this) {
//                 activeCount++;
//                 if (activeCount > maxTotal) {
//                     throw new IllegalStateException(
//                         "Too many active instances: " + activeCount);
//                 }
//                 waitLatency = makeLatency;
//             }
//             if (waitLatency > 0) {
//                 doWait(waitLatency);
//             }
//             int counter;
//             synchronized(this) {
//                 counter = makeCounter++;
//             }
//             return new DefaultPooledObject<>(string.valueOf(counter));
//         }
//         override
//         void passivateObject(PooledObject!(string) obj){
//             bool hurl;
//             synchronized(this) {
//                 hurl = exceptionOnPassivate;
//             }
//             if (hurl) {
//                 throw new Exception();
//             }
//         }
//         synchronized void setDestroyLatency(long destroyLatency) {
//             this.destroyLatency = destroyLatency;
//         }
//         synchronized void setEvenValid(bool valid) {
//             evenValid = valid;
//         }
//         synchronized void setMakeLatency(long makeLatency) {
//             this.makeLatency = makeLatency;
//         }
//         synchronized void setMaxTotal(int maxTotal) {
//             this.maxTotal = maxTotal;
//         }
//         synchronized void setOddValid(bool valid) {
//             oddValid = valid;
//         }

//         synchronized void setThrowExceptionOnActivate(bool b) {
//             exceptionOnActivate = b;
//         }

//         synchronized void setThrowExceptionOnDestroy(bool b) {
//             exceptionOnDestroy = b;
//         }

//         synchronized void setThrowExceptionOnPassivate(bool bool) {
//             exceptionOnPassivate = bool;
//         }

//         synchronized void setValid(bool valid) {
//             setEvenValid(valid);
//             setOddValid(valid);
//         }

//         synchronized void setValidateLatency(long validateLatency) {
//             this.validateLatency = validateLatency;
//         }

//         synchronized void setValidationEnabled(bool b) {
//             enableValidation = b;
//         }

//         override
//         bool validateObject(PooledObject!(string) obj) {
//             bool validate;
//             bool evenTest;
//             bool oddTest;
//             long waitLatency;
//             int counter;
//             synchronized(this) {
//                 validate = enableValidation;
//                 evenTest = evenValid;
//                 oddTest = oddValid;
//                 counter = validateCounter++;
//                 waitLatency = validateLatency;
//             }
//             if (waitLatency > 0) {
//                 doWait(waitLatency);
//             }
//             if (validate) {
//                 return counter%2 == 0 ? evenTest : oddTest;
//             }
//             return true;
//         }
//     }

//     static class TestEvictionPolicy!(T) implements EvictionPolicy!(T) {

//         private Integer callCount = new Integer(0);

//         override
//         bool evict(EvictionConfig config, PooledObject!(T) underTest,
//                 int idleCount) {
//             if (callCount.incrementAndGet() > 1500) {
//                 return true;
//             }
//             return false;
//         }
//     }

//     static class TestThread!(T) implements Runnable {

//         /** source of random delay times */
//         private java.util.Random _random;

//         /** pool to borrow from */
//         private ObjectPool!(T) _pool;

//         /** number of borrow attempts */
//         private int _iter;

//         /** delay before each borrow attempt */
//         private int _startDelay;

//         /** time to hold each borrowed object before returning it */
//         private int _holdTime;

//         /** whether or not start and hold time are randomly generated */
//         private bool _randomDelay;

//         /** object expected to be borrowed (fail otherwise) */
//         private Object _expectedObject;

//         private volatile bool _complete = false;
//         private volatile bool _failed = false;
//         private volatile Throwable _error;

//         TestThread(ObjectPool!(T) pool) {
//             this(pool, 100, 50, true, null);
//         }

//         TestThread(ObjectPool!(T) pool, int iter) {
//             this(pool, iter, 50, true, null);
//         }

//         TestThread(ObjectPool!(T) pool, int iter, int delay) {
//             this(pool, iter, delay, true, null);
//         }

//         TestThread(ObjectPool!(T) pool, int iter, int delay,
//                 bool randomDelay) {
//             this(pool, iter, delay, randomDelay, null);
//         }

//         TestThread(ObjectPool!(T) pool, int iter, int delay,
//                 bool randomDelay, Object obj) {
//             this(pool, iter, delay, delay, randomDelay, obj);
//         }

//         TestThread(ObjectPool!(T) pool, int iter, int startDelay,
//             int holdTime, bool randomDelay, Object obj) {
//         _pool = pool;
//         _iter = iter;
//         _startDelay = startDelay;
//         _holdTime = holdTime;
//         _randomDelay = randomDelay;
//         _random = _randomDelay ? new Random() : null;
//         _expectedObject = obj;
//     }

//         bool complete() {
//             return _complete;
//         }

//         bool failed() {
//             return _failed;
//         }

//         override
//         void run() {
//             for(int i=0;i<_iter;i++) {
//                 long startDelay =
//                     _randomDelay ? (long)_random.nextInt(_startDelay) : _startDelay;
//                 long holdTime =
//                     _randomDelay ? (long)_random.nextInt(_holdTime) : _holdTime;
//                 try {
//                     Thread.sleep(startDelay);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//                 T obj = null;
//                 try {
//                     obj = _pool.borrowObject();
//                 } catch(Exception e) {
//                     _error = e;
//                     _failed = true;
//                     _complete = true;
//                     break;
//                 }

//                 if (_expectedObject !is null && !_expectedObject == obj) {
//                     _error = new Throwable("Expected: "+_expectedObject+ " found: "+obj);
//                     _failed = true;
//                     _complete = true;
//                     break;
//                 }

//                 try {
//                     Thread.sleep(holdTime);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//                 try {
//                     _pool.returnObject(obj);
//                 } catch(Exception e) {
//                     _error = e;
//                     _failed = true;
//                     _complete = true;
//                     break;
//                 }
//             }
//             _complete = true;
//         }
//     }

//     /*
//      * Very simple test thread that just tries to borrow an object from
//      * the provided pool returns it after a wait
//      */
//     static class WaitingTestThread : ThreadEx {
//         private GenericObjectPool!(string) _pool;
//         private long _pause;
//         private Throwable _thrown;

//         private long preborrow; // just before borrow
//         private long postborrow; //  borrow returned
//         private long postreturn; // after object was returned
//         private long ended;
//         private string objectId;

//         this(GenericObjectPool!(string) pool, long pause) {
//             _pool = pool;
//             _pause = pause;
//             _thrown = null;
//         }

//         override
//         void run() {
//             try {
//                 preborrow = DateTimeHelper.currentTimeMillis();
//                 string obj = _pool.borrowObject();
//                 objectId = obj;
//                 postborrow = DateTimeHelper.currentTimeMillis();
//                 Thread.sleep(_pause);
//                 _pool.returnObject(obj);
//                 postreturn = DateTimeHelper.currentTimeMillis();
//             } catch (Throwable e) {
//                 _thrown = e;
//             } finally{
//                 ended = DateTimeHelper.currentTimeMillis();
//             }
//         }
//     }

// /**
//  */
// class TestGenericObjectPool : TestBaseObjectPool {


//     private static bool DISPLAY_THREAD_DETAILS=
//         Boolean.valueOf(System.getProperty("TestGenericObjectPool.display.thread.details", "false")).booleanValue();
//     // To pass this to a Maven test, use:
//     // mvn test -DargLine="-DTestGenericObjectPool.display.thread.details=true"
//     // @see http://jira.codehaus.org/browse/SUREFIRE-121

//     protected GenericObjectPool!(string) genericObjectPool = null;

//     private SimpleFactory simpleFactory = null;

//     private void assertConfiguration(GenericObjectPoolConfig<?> expected, GenericObjectPool<?> actual){
//         assertEquals("testOnCreate",Boolean.valueOf(expected.getTestOnCreate()),
//                 Boolean.valueOf(actual.getTestOnCreate()));
//         assertEquals("testOnBorrow",Boolean.valueOf(expected.getTestOnBorrow()),
//                 Boolean.valueOf(actual.getTestOnBorrow()));
//         assertEquals("testOnReturn",Boolean.valueOf(expected.getTestOnReturn()),
//                 Boolean.valueOf(actual.getTestOnReturn()));
//         assertEquals("testWhileIdle",Boolean.valueOf(expected.getTestWhileIdle()),
//                 Boolean.valueOf(actual.getTestWhileIdle()));
//         assertEquals("whenExhaustedAction",
//                 Boolean.valueOf(expected.getBlockWhenExhausted()),
//                 Boolean.valueOf(actual.getBlockWhenExhausted()));
//         assertEquals("maxTotal",expected.getMaxTotal(),actual.getMaxTotal());
//         assertEquals("maxIdle",expected.getMaxIdle(),actual.getMaxIdle());
//         assertEquals("maxWait",expected.getMaxWaitMillis(),actual.getMaxWaitMillis());
//         assertEquals("minEvictableIdleTimeMillis",expected.getMinEvictableIdleTimeMillis(),actual.getMinEvictableIdleTimeMillis());
//         assertEquals("numTestsPerEvictionRun",expected.getNumTestsPerEvictionRun(),actual.getNumTestsPerEvictionRun());
//         assertEquals("evictorShutdownTimeoutMillis",expected.getEvictorShutdownTimeoutMillis(),actual.getEvictorShutdownTimeoutMillis());
//         assertEquals("timeBetweenEvictionRunsMillis",expected.getTimeBetweenEvictionRunsMillis(),actual.getTimeBetweenEvictionRunsMillis());
//     }

//     private void checkEvict(bool lifo){
//         // yea this is hairy but it tests all the code paths in GOP.evict()
//         genericObjectPool.setSoftMinEvictableIdleTimeMillis(10);
//         genericObjectPool.setMinIdle(2);
//         genericObjectPool.setTestWhileIdle(true);
//         genericObjectPool.setLifo(lifo);
//         PoolUtils.prefill(genericObjectPool, 5);
//         genericObjectPool.evict();
//         simpleFactory.setEvenValid(false);
//         simpleFactory.setOddValid(false);
//         simpleFactory.setThrowExceptionOnActivate(true);
//         genericObjectPool.evict();
//         PoolUtils.prefill(genericObjectPool, 5);
//         simpleFactory.setThrowExceptionOnActivate(false);
//         simpleFactory.setThrowExceptionOnPassivate(true);
//         genericObjectPool.evict();
//         simpleFactory.setThrowExceptionOnPassivate(false);
//         simpleFactory.setEvenValid(true);
//         simpleFactory.setOddValid(true);
//         Thread.sleep(125);
//         genericObjectPool.evict();
//         assertEquals(2, genericObjectPool.getNumIdle());
//     }

//     private void checkEvictionOrder(bool lifo){
//         checkEvictionOrderPart1(lifo);
//         tearDown();
//         setUp();
//         checkEvictionOrderPart2(lifo);
//     }

//     private void checkEvictionOrderPart1(bool lifo){
//         genericObjectPool.setNumTestsPerEvictionRun(2);
//         genericObjectPool.setMinEvictableIdleTimeMillis(100);
//         genericObjectPool.setLifo(lifo);
//         for (int i = 0; i < 5; i++) {
//             genericObjectPool.addObject();
//             Thread.sleep(100);
//         }
//         // Order, oldest to youngest, is "0", "1", ...,"4"
//         genericObjectPool.evict(); // Should evict "0" and "1"
//         Object obj = genericObjectPool.borrowObject();
//         assertTrue("oldest not evicted", !obj.equals("0"));
//         assertTrue("second oldest not evicted", !obj.equals("1"));
//         // 2 should be next out for FIFO, 4 for LIFO
//         assertEquals("Wrong instance returned", lifo ? "4" : "2" , obj);
//     }

//     private void checkEvictionOrderPart2(bool lifo){
//         // Two eviction runs in sequence
//         genericObjectPool.setNumTestsPerEvictionRun(2);
//         genericObjectPool.setMinEvictableIdleTimeMillis(100);
//         genericObjectPool.setLifo(lifo);
//         for (int i = 0; i < 5; i++) {
//             genericObjectPool.addObject();
//             Thread.sleep(100);
//         }
//         genericObjectPool.evict(); // Should evict "0" and "1"
//         genericObjectPool.evict(); // Should evict "2" and "3"
//         Object obj = genericObjectPool.borrowObject();
//         assertEquals("Wrong instance remaining in pool", "4", obj);
//     }

//     private void checkEvictorVisiting(bool lifo){
//         VisitTracker!(Object) obj;
//         VisitTrackerFactory!(Object) trackerFactory = new VisitTrackerFactory<>();
//         try (GenericObjectPool!(VisitTracker!(Object)) trackerPool = new GenericObjectPool<>(trackerFactory)) {
//             trackerPool.setNumTestsPerEvictionRun(2);
//             trackerPool.setMinEvictableIdleTimeMillis(-1);
//             trackerPool.setTestWhileIdle(true);
//             trackerPool.setLifo(lifo);
//             trackerPool.setTestOnReturn(false);
//             trackerPool.setTestOnBorrow(false);
//             for (int i = 0; i < 8; i++) {
//                 trackerPool.addObject();
//             }
//             trackerPool.evict(); // Visit oldest 2 - 0 and 1
//             obj = trackerPool.borrowObject();
//             trackerPool.returnObject(obj);
//             obj = trackerPool.borrowObject();
//             trackerPool.returnObject(obj);
//             // borrow, return, borrow, return
//             // FIFO will move 0 and 1 to end
//             // LIFO, 7 out, then in, then out, then in
//             trackerPool.evict(); // Should visit 2 and 3 in either case
//             for (int i = 0; i < 8; i++) {
//                 VisitTracker!(Object) tracker = trackerPool.borrowObject();
//                 if (tracker.getId() >= 4) {
//                     assertEquals("Unexpected instance visited " + tracker.getId(), 0, tracker.getValidateCount());
//                 } else {
//                     assertEquals("Instance " + tracker.getId() + " visited wrong number of times.", 1,
//                             tracker.getValidateCount());
//                 }
//             }
//         }

//         trackerFactory = new VisitTrackerFactory<>();
//         try (GenericObjectPool!(VisitTracker!(Object)) trackerPool = new GenericObjectPool<>(trackerFactory)) {
//             trackerPool.setNumTestsPerEvictionRun(3);
//             trackerPool.setMinEvictableIdleTimeMillis(-1);
//             trackerPool.setTestWhileIdle(true);
//             trackerPool.setLifo(lifo);
//             trackerPool.setTestOnReturn(false);
//             trackerPool.setTestOnBorrow(false);
//             for (int i = 0; i < 8; i++) {
//                 trackerPool.addObject();
//             }
//             trackerPool.evict(); // 0, 1, 2
//             trackerPool.evict(); // 3, 4, 5
//             obj = trackerPool.borrowObject();
//             trackerPool.returnObject(obj);
//             obj = trackerPool.borrowObject();
//             trackerPool.returnObject(obj);
//             obj = trackerPool.borrowObject();
//             trackerPool.returnObject(obj);
//             // borrow, return, borrow, return
//             // FIFO 3,4,5,6,7,0,1,2
//             // LIFO 7,6,5,4,3,2,1,0
//             // In either case, pointer should be at 6
//             trackerPool.evict();
//             // Should hit 6,7,0 - 0 for second time
//             for (int i = 0; i < 8; i++) {
//                 VisitTracker!(Object) tracker = trackerPool.borrowObject();
//                 if (tracker.getId() != 0) {
//                     assertEquals("Instance " + tracker.getId() + " visited wrong number of times.", 1,
//                             tracker.getValidateCount());
//                 } else {
//                     assertEquals("Instance " + tracker.getId() + " visited wrong number of times.", 2,
//                             tracker.getValidateCount());
//                 }
//             }
//         }

//         // Randomly generate a pools with random numTests
//         // and make sure evictor cycles through elements appropriately
//         int[] smallPrimes = { 2, 3, 5, 7 };
//         Random random = new Random();
//         random.setSeed(DateTimeHelper.currentTimeMillis());
//         for (int i = 0; i < 4; i++) {
//             for (int j = 0; j < 5; j++) {
//                 try (GenericObjectPool!(VisitTracker!(Object)) trackerPool = new GenericObjectPool<>(trackerFactory)) {
//                     trackerPool.setNumTestsPerEvictionRun(smallPrimes[i]);
//                     trackerPool.setMinEvictableIdleTimeMillis(-1);
//                     trackerPool.setTestWhileIdle(true);
//                     trackerPool.setLifo(lifo);
//                     trackerPool.setTestOnReturn(false);
//                     trackerPool.setTestOnBorrow(false);
//                     trackerPool.setMaxIdle(-1);
//                     int instanceCount = 10 + random.nextInt(20);
//                     trackerPool.setMaxTotal(instanceCount);
//                     for (int k = 0; k < instanceCount; k++) {
//                         trackerPool.addObject();
//                     }

//                     // Execute a random number of evictor runs
//                     int runs = 10 + random.nextInt(50);
//                     for (int k = 0; k < runs; k++) {
//                         trackerPool.evict();
//                     }

//                     // Number of times evictor should have cycled through the pool
//                     int cycleCount = (runs * trackerPool.getNumTestsPerEvictionRun()) / instanceCount;

//                     // Look at elements and make sure they are visited cycleCount
//                     // or cycleCount + 1 times
//                     VisitTracker!(Object) tracker = null;
//                     int visitCount = 0;
//                     for (int k = 0; k < instanceCount; k++) {
//                         tracker = trackerPool.borrowObject();
//                         assertTrue(trackerPool.getNumActive() <= trackerPool.getMaxTotal());
//                         visitCount = tracker.getValidateCount();
//                         assertTrue(visitCount >= cycleCount && visitCount <= cycleCount + 1);
//                     }
//                 }
//             }
//         }
//     }

//     private BasePooledObjectFactory!(string) createDefaultPooledObjectFactory() {
//         return new BasePooledObjectFactory!(string)() {
//             override
//             string create() {
//                 // fake
//                 return null;
//             }

//             override
//             PooledObject!(string) wrap(string obj) {
//                 // fake
//                 return new DefaultPooledObject<>(obj);
//             }
//         };
//     }

//     private BasePooledObjectFactory!(string) createNullPooledObjectFactory() {
//         return new BasePooledObjectFactory!(string)() {
//             override
//             string create() {
//                 // fake
//                 return null;
//             }

//             override
//             PooledObject!(string) wrap(string obj) {
//                 // fake
//                 return null;
//             }
//         };
//     }

//     private BasePooledObjectFactory!(string) createSlowObjectFactory(long elapsedTimeMillis) {
//         return new BasePooledObjectFactory!(string)() {
//             override
//             string create(){
//                 Thread.sleep(elapsedTimeMillis);
//                 return "created";
//             }

//             override
//             PooledObject!(string) wrap(string obj) {
//                 // fake
//                 return new DefaultPooledObject<>(obj);
//             }
//         };
//     }

//     override
//     protected Object getNthObject(int n) {
//         return string.valueOf(n);
//     }

//     override
//     protected bool isFifo() {
//         return false;
//     }

//     override
//     protected bool isLifo() {
//         return true;
//     }

//     override
//     protected ObjectPool!(string) makeEmptyPool(int minCap) {
//        GenericObjectPool!(string) mtPool =
//                new GenericObjectPool<>(new SimpleFactory());
//        mtPool.setMaxTotal(minCap);
//        mtPool.setMaxIdle(minCap);
//        return mtPool;
//     }

//     override
//     protected ObjectPool!(Object) makeEmptyPool(
//             PooledObjectFactory!(Object) fac) {
//         return new GenericObjectPool<>(fac);
//     }

//     /**
//      * Kicks off <numThreads> test threads, each of which will go through
//      * <iterations> borrow-return cycles with random delay times <= delay
//      * in between.
//      */
//     @SuppressWarnings({
//         "rawtypes", "unchecked"
//     })
//     private void runTestThreads(int numThreads, int iterations, int delay, GenericObjectPool testPool) {
//         TestThread[] threads = new TestThread[numThreads];
//         for(int i=0;i<numThreads;i++) {
//             threads[i] = new TestThread!(string)(testPool,iterations,delay);
//             Thread t = new Thread(threads[i]);
//             t.start();
//         }
//         for(int i=0;i<numThreads;i++) {
//             while(!(threads[i]).complete()) {
//                 try {
//                     Thread.sleep(500L);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//             }
//             if(threads[i].failed()) {
//                 fail("Thread " + i + " failed: " + threads[i]._error.toString());
//             }
//         }
//     }

//     @Before
//     void setUp(){
//         simpleFactory = new SimpleFactory();
//         genericObjectPool = new GenericObjectPool<>(simpleFactory);
//     }

//     @After
//     void tearDown(){
//         string poolName = genericObjectPool.getJmxName().toString();
//         genericObjectPool.clear();
//         genericObjectPool.close();
//         genericObjectPool = null;
//         simpleFactory = null;

//         MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
//         Set!(ObjectName) result = mbs.queryNames(new ObjectName(
//                 "org.apache.commoms.pool2:type=GenericObjectPool,*"), null);
//         // There should be no registered pools at this point
//         int registeredPoolCount = result.size();
//         StringBuilder msg = new StringBuilder("Current pool is: ");
//         msg.append(poolName);
//         msg.append("  Still open pools are: ");
//         foreach(ObjectName name ; result) {
//             // Clean these up ready for the next test
//             msg.append(name.toString());
//             msg.append(" created via\n");
//             msg.append(mbs.getAttribute(name, "CreationStackTrace"));
//             msg.append('\n');
//             mbs.unregisterMBean(name);
//         }
//         Assert.assertEquals(msg.toString(), 0, registeredPoolCount);
//     }

//     @Test(timeout = 60000)
//     void testAddObject(){
//         assertEquals("should be zero idle", 0, genericObjectPool.getNumIdle());
//         genericObjectPool.addObject();
//         assertEquals("should be one idle", 1, genericObjectPool.getNumIdle());
//         assertEquals("should be zero active", 0, genericObjectPool.getNumActive());
//         string obj = genericObjectPool.borrowObject();
//         assertEquals("should be zero idle", 0, genericObjectPool.getNumIdle());
//         assertEquals("should be one active", 1, genericObjectPool.getNumActive());
//         genericObjectPool.returnObject(obj);
//         assertEquals("should be one idle", 1, genericObjectPool.getNumIdle());
//         assertEquals("should be zero active", 0, genericObjectPool.getNumActive());
//     }


//     /*
//      * Note: This test relies on timing for correct execution. There *should* be
//      * enough margin for this to work correctly on most (all?) systems but be
//      * aware of this if you see a failure of this test.
//      */
//     @SuppressWarnings({
//         "rawtypes", "unchecked"
//     })
//     @Test(timeout = 60000)
//     void testBorrowObjectFairness(){

//         int numThreads = 40;
//         int maxTotal = 40;

//         GenericObjectPoolConfig config = new GenericObjectPoolConfig();
//         config.setMaxTotal(maxTotal);
//         config.setMaxIdle(maxTotal);
//         config.setFairness(true);
//         config.setLifo(false);

//         genericObjectPool = new GenericObjectPool(simpleFactory, config);

//         // Exhaust the pool
//         string[] objects = new string[maxTotal];
//         for (int i = 0; i < maxTotal; i++) {
//             objects[i] = genericObjectPool.borrowObject();
//         }

//         // Start and park threads waiting to borrow objects
//         TestThread[] threads = new TestThread[numThreads];
//         for(int i=0;i<numThreads;i++) {
//             threads[i] = new TestThread(genericObjectPool, 1, 0, 2000, false, string.valueOf(i % maxTotal));
//             Thread t = new Thread(threads[i]);
//             t.start();
//             // Short delay to ensure threads start in correct order
//             try {
//                 Thread.sleep(10);
//             } catch (InterruptedException e) {
//                 fail(e.toString());
//             }
//         }

//         // Return objects, other threads should get served in order
//         for (int i = 0; i < maxTotal; i++) {
//             genericObjectPool.returnObject(objects[i]);
//         }

//         // Wait for threads to finish
//         for(int i=0;i<numThreads;i++) {
//             while(!(threads[i]).complete()) {
//                 try {
//                     Thread.sleep(500L);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//             }
//             if(threads[i].failed()) {
//                 fail("Thread "+i+" failed: "+threads[i]._error.toString());
//             }
//         }
//     }

//     /**
//      * On first borrow, first object fails validation, second object is OK.
//      * Subsequent borrows are OK. This was POOL-152.
//      */
//     @Test(timeout = 60000)
//     void testBrokenFactoryShouldNotBlockPool() {
//         int maxTotal = 1;

//         simpleFactory.setMaxTotal(maxTotal);
//         genericObjectPool.setMaxTotal(maxTotal);
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setTestOnBorrow(true);

//         // First borrow object will need to create a new object which will fail
//         // validation.
//         string obj = null;
//         Exception ex = null;
//         simpleFactory.setValid(false);
//         try {
//             obj = genericObjectPool.borrowObject();
//         } catch (Exception e) {
//             ex = e;
//         }
//         // Failure expected
//         assertNotNull(ex);
//         assertTrue(ex instanceof NoSuchElementException);
//         assertNull(obj);

//         // Configure factory to create valid objects so subsequent borrows work
//         simpleFactory.setValid(true);

//         // Subsequent borrows should be OK
//         try {
//             obj = genericObjectPool.borrowObject();
//         } catch (Exception e1) {
//             fail();
//         }
//         assertNotNull(obj);
//         try {
//             genericObjectPool.returnObject(obj);
//         } catch (Exception e) {
//             fail();
//         }
//     }

//     // POOL-259
//     @Test
//     void testClientWaitStats(){
//         SimpleFactory factory = new SimpleFactory();
//         // Give makeObject a little latency
//         factory.setMakeLatency(200);
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(factory, new GenericObjectPoolConfig!(string)())) {
//             string s = pool.borrowObject();
//             // First borrow waits on create, so wait time should be at least 200 ms
//             // Allow 100ms error in clock times
//             Assert.assertTrue(pool.getMaxBorrowWaitTimeMillis() >= 100);
//             Assert.assertTrue(pool.getMeanBorrowWaitTimeMillis() >= 100);
//             pool.returnObject(s);
//             pool.borrowObject();
//             // Second borrow does not have to wait on create, average should be about 100
//             Assert.assertTrue(pool.getMaxBorrowWaitTimeMillis() > 100);
//             Assert.assertTrue(pool.getMeanBorrowWaitTimeMillis() < 200);
//             Assert.assertTrue(pool.getMeanBorrowWaitTimeMillis() > 20);
//         }
//     }

//     @Test(timeout = 60000)
//     void testCloseMultiplePools1(){
//         try (GenericObjectPool!(string) genericObjectPool2 = new GenericObjectPool<>(simpleFactory)) {
//             genericObjectPool.setTimeBetweenEvictionRunsMillis(1);
//             genericObjectPool2.setTimeBetweenEvictionRunsMillis(1);
//         }
//         genericObjectPool.close();
//     }

//     @Test(timeout = 60000)
//     void testCloseMultiplePools2(){
//         try (GenericObjectPool!(string) genericObjectPool2 = new GenericObjectPool<>(simpleFactory)) {
//             // Ensure eviction takes a long time, during which time EvictionTimer.executor's queue is empty
//             simpleFactory.setDestroyLatency(1000L);
//             // Ensure there is an object to evict, so that above latency takes effect
//             genericObjectPool.setTimeBetweenEvictionRunsMillis(1);
//             genericObjectPool2.setTimeBetweenEvictionRunsMillis(1);
//             genericObjectPool.setMinEvictableIdleTimeMillis(1);
//             genericObjectPool2.setMinEvictableIdleTimeMillis(1);
//             genericObjectPool.addObject();
//             genericObjectPool2.addObject();
//             // Close both pools
//         }
//         genericObjectPool.close();
//     }

//     @Test(timeout = 60000)
//     void testConcurrentBorrowAndEvict(){

//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.addObject();

//         for (int i = 0; i < 5000; i++) {
//             ConcurrentBorrowAndEvictThread one =
//                     new ConcurrentBorrowAndEvictThread(true);
//             ConcurrentBorrowAndEvictThread two =
//                     new ConcurrentBorrowAndEvictThread(false);

//             one.start();
//             two.start();
//             one.join();
//             two.join();

//             genericObjectPool.returnObject(one.obj);

//             /* Uncomment this for a progress indication
//             if (i % 10 == 0) {
//                 System.out.println(i/10);
//             }
//             */
//         }
//     }

//     /**
//      * POOL-231 - verify that concurrent invalidates of the same object do not
//      * corrupt pool destroyCount.
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test
//     void testConcurrentInvalidate(){
//         // Get allObjects and idleObjects loaded with some instances
//         int nObjects = 1000;
//         genericObjectPool.setMaxTotal(nObjects);
//         genericObjectPool.setMaxIdle(nObjects);
//         string[] obj = new string[nObjects];
//         for (int i = 0; i < nObjects; i++) {
//             obj[i] = genericObjectPool.borrowObject();
//         }
//         for (int i = 0; i < nObjects; i++) {
//             if (i % 2 == 0) {
//                 genericObjectPool.returnObject(obj[i]);
//             }
//         }
//         int nThreads = 20;
//         int nIterations = 60;
//         InvalidateThread[] threads = new InvalidateThread[nThreads];
//         // Randomly generated list of distinct invalidation targets
//         ArrayList!(Integer) targets = new ArrayList<>();
//         Random random = new Random();
//         for (int j = 0; j < nIterations; j++) {
//             // Get a random invalidation target
//             Integer targ = Integer.valueOf(random.nextInt(nObjects));
//             while (targets.contains(targ)) {
//                 targ = Integer.valueOf(random.nextInt(nObjects));
//             }
//             targets.add(targ);
//             // Launch nThreads threads all trying to invalidate the target
//             for (int i = 0; i < nThreads; i++) {
//                 threads[i] = new InvalidateThread(genericObjectPool, obj[targ.intValue()]);
//             }
//             for (int i = 0; i < nThreads; i++) {
//                 new Thread(threads[i]).start();
//             }
//             bool done = false;
//             while (!done) {
//                 done = true;
//                 for (int i = 0; i < nThreads; i++) {
//                     done = done && threads[i].complete();
//                 }
//                 Thread.sleep(100);
//             }
//         }
//         Assert.assertEquals(nIterations, genericObjectPool.getDestroyedCount());
//     }

//     @Test(expected=IllegalArgumentException.class)
//     void testConstructorNullFactory() {
//         // add dummy assert (won't be invoked because of IAE) to avoid "unused" warning
//         try (GenericObjectPool!(string) object = new GenericObjectPool<>(null)) {
//             assertNotNull(object);
//             // TODO this currently causes tearDown to report an error
//             // Looks like GOP needs to call close() or jmxUnregister() before throwing IAE
//         }
//     }


//     @Test(timeout = 60000)
//     void testConstructors(){

//         // Make constructor arguments all different from defaults
//         int minIdle = 2;
//         long maxWait = 3;
//         int maxIdle = 4;
//         int maxTotal = 5;
//         long minEvictableIdleTimeMillis = 6;
//         int numTestsPerEvictionRun = 7;
//         bool testOnBorrow = true;
//         bool testOnReturn = true;
//         bool testWhileIdle = true;
//         long timeBetweenEvictionRunsMillis = 8;
//         bool blockWhenExhausted = false;
//         bool lifo = false;
//         PooledObjectFactory!(Object) dummyFactory = new DummyFactory();
//         try (GenericObjectPool!(Object) dummyPool = new GenericObjectPool<>(dummyFactory)) {
//             assertEquals(GenericObjectPoolConfig.DEFAULT_MAX_IDLE, dummyPool.getMaxIdle());
//             assertEquals(BaseObjectPoolConfig.DEFAULT_MAX_WAIT_MILLIS, dummyPool.getMaxWaitMillis());
//             assertEquals(GenericObjectPoolConfig.DEFAULT_MIN_IDLE, dummyPool.getMinIdle());
//             assertEquals(GenericObjectPoolConfig.DEFAULT_MAX_TOTAL, dummyPool.getMaxTotal());
//             assertEquals(BaseObjectPoolConfig.DEFAULT_MIN_EVICTABLE_IDLE_TIME_MILLIS,
//                     dummyPool.getMinEvictableIdleTimeMillis());
//             assertEquals(BaseObjectPoolConfig.DEFAULT_NUM_TESTS_PER_EVICTION_RUN,
//                     dummyPool.getNumTestsPerEvictionRun());
//             assertEquals(Boolean.valueOf(BaseObjectPoolConfig.DEFAULT_TEST_ON_BORROW),
//                     Boolean.valueOf(dummyPool.getTestOnBorrow()));
//             assertEquals(Boolean.valueOf(BaseObjectPoolConfig.DEFAULT_TEST_ON_RETURN),
//                     Boolean.valueOf(dummyPool.getTestOnReturn()));
//             assertEquals(Boolean.valueOf(BaseObjectPoolConfig.DEFAULT_TEST_WHILE_IDLE),
//                     Boolean.valueOf(dummyPool.getTestWhileIdle()));
//             assertEquals(BaseObjectPoolConfig.DEFAULT_TIME_BETWEEN_EVICTION_RUNS_MILLIS,
//                     dummyPool.getTimeBetweenEvictionRunsMillis());
//             assertEquals(Boolean.valueOf(BaseObjectPoolConfig.DEFAULT_BLOCK_WHEN_EXHAUSTED),
//                     Boolean.valueOf(dummyPool.getBlockWhenExhausted()));
//             assertEquals(Boolean.valueOf(BaseObjectPoolConfig.DEFAULT_LIFO), Boolean.valueOf(dummyPool.getLifo()));
//         }

//         GenericObjectPoolConfig!(Object) config = new GenericObjectPoolConfig<>();
//         config.setLifo(lifo);
//         config.setMaxIdle(maxIdle);
//         config.setMinIdle(minIdle);
//         config.setMaxTotal(maxTotal);
//         config.setMaxWaitMillis(maxWait);
//         config.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);
//         config.setNumTestsPerEvictionRun(numTestsPerEvictionRun);
//         config.setTestOnBorrow(testOnBorrow);
//         config.setTestOnReturn(testOnReturn);
//         config.setTestWhileIdle(testWhileIdle);
//         config.setTimeBetweenEvictionRunsMillis(timeBetweenEvictionRunsMillis);
//         config.setBlockWhenExhausted(blockWhenExhausted);
//         try (GenericObjectPool!(Object) dummyPool = new GenericObjectPool<>(dummyFactory, config)) {
//             assertEquals(maxIdle, dummyPool.getMaxIdle());
//             assertEquals(maxWait, dummyPool.getMaxWaitMillis());
//             assertEquals(minIdle, dummyPool.getMinIdle());
//             assertEquals(maxTotal, dummyPool.getMaxTotal());
//             assertEquals(minEvictableIdleTimeMillis, dummyPool.getMinEvictableIdleTimeMillis());
//             assertEquals(numTestsPerEvictionRun, dummyPool.getNumTestsPerEvictionRun());
//             assertEquals(Boolean.valueOf(testOnBorrow), Boolean.valueOf(dummyPool.getTestOnBorrow()));
//             assertEquals(Boolean.valueOf(testOnReturn), Boolean.valueOf(dummyPool.getTestOnReturn()));
//             assertEquals(Boolean.valueOf(testWhileIdle), Boolean.valueOf(dummyPool.getTestWhileIdle()));
//             assertEquals(timeBetweenEvictionRunsMillis, dummyPool.getTimeBetweenEvictionRunsMillis());
//             assertEquals(Boolean.valueOf(blockWhenExhausted), Boolean.valueOf(dummyPool.getBlockWhenExhausted()));
//             assertEquals(Boolean.valueOf(lifo), Boolean.valueOf(dummyPool.getLifo()));
//         }
//     }

//     @Test(timeout = 60000)
//     void testDefaultConfiguration(){
//         assertConfiguration(new GenericObjectPoolConfig<>(),genericObjectPool);
//     }

//     /**
//      * Verifies that when a factory's makeObject produces instances that are not
//      * discernible by equals, the pool can handle them.
//      *
//      * JIRA: POOL-283
//      */
//     @Test
//     void testEqualsIndiscernible(){
//         HashSetFactory factory = new HashSetFactory();
//         try (GenericObjectPool!(HashSet!(string)) pool = new GenericObjectPool<>(factory,
//                 new GenericObjectPoolConfig!(HashSet!(string))())) {
//             HashSet!(string) s1 = pool.borrowObject();
//             HashSet!(string) s2 = pool.borrowObject();
//             pool.returnObject(s1);
//             pool.returnObject(s2);
//         }
//     }

//     @Test
//     void testErrorFactoryDoesNotBlockThreads(){

//         CreateErrorFactory factory = new CreateErrorFactory();
//         try (GenericObjectPool!(string) createFailFactoryPool = new GenericObjectPool<>(factory)) {

//             createFailFactoryPool.setMaxTotal(1);

//             // Try and borrow the first object from the pool
//             WaitingTestThread thread1 = new WaitingTestThread(createFailFactoryPool, 0);
//             thread1.start();

//             // Wait for thread to reach semaphore
//             while (!factory.hasQueuedThreads()) {
//                 Thread.sleep(200);
//             }

//             // Try and borrow the second object from the pool
//             WaitingTestThread thread2 = new WaitingTestThread(createFailFactoryPool, 0);
//             thread2.start();
//             // Pool will not call factory since maximum number of object creations
//             // are already queued.

//             // Thread 2 will wait on an object being returned to the pool
//             // Give thread 2 a chance to reach this state
//             Thread.sleep(1000);

//             // Release thread1
//             factory.release();
//             // Pre-release thread2
//             factory.release();

//             // Both threads should now complete.
//             bool threadRunning = true;
//             int count = 0;
//             while (threadRunning && count < 15) {
//                 threadRunning = thread1.isAlive();
//                 threadRunning = thread2.isAlive();
//                 Thread.sleep(200);
//                 count++;
//             }
//             Assert.assertFalse(thread1.isAlive());
//             Assert.assertFalse(thread2.isAlive());

//             Assert.assertTrue(thread1._thrown instanceof UnknownError);
//             Assert.assertTrue(thread2._thrown instanceof UnknownError);
//         }
//     }

//     /**
//      * Tests addObject contention between ensureMinIdle triggered by
//      * the Evictor with minIdle &gt; 0 and borrowObject.
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test(timeout = 60000)
//     void testEvictAddObjects(){
//         simpleFactory.setMakeLatency(300);
//         simpleFactory.setMaxTotal(2);
//         genericObjectPool.setMaxTotal(2);
//         genericObjectPool.setMinIdle(1);
//         genericObjectPool.borrowObject(); // numActive = 1, numIdle = 0
//         // Create a test thread that will run once and try a borrow after
//         // 150ms fixed delay
//         TestThread!(string) borrower = new TestThread<>(genericObjectPool, 1, 150, false);
//         Thread borrowerThread = new Thread(borrower);
//         // Set evictor to run in 100 ms - will create idle instance
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(100);
//         borrowerThread.start();  // Off to the races
//         borrowerThread.join();
//         assertTrue(!borrower.failed());
//     }

//     @Test(timeout = 60000)
//     void testEvictFIFO(){
//         checkEvict(false);
//     }

//     @Test(timeout = 60000)
//     void testEviction(){
//         genericObjectPool.setMaxIdle(500);
//         genericObjectPool.setMaxTotal(500);
//         genericObjectPool.setNumTestsPerEvictionRun(100);
//         genericObjectPool.setMinEvictableIdleTimeMillis(250L);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(500L);
//         genericObjectPool.setTestWhileIdle(true);

//         string[] active = new string[500];
//         for (int i = 0; i < 500; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }
//         for (int i = 0; i < 500; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         try { Thread.sleep(1000L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 500 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 500);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 400 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 400);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 300 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 300);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 200 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 200);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 100 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 100);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertEquals("Should be zero idle, found " + genericObjectPool.getNumIdle(),0,genericObjectPool.getNumIdle());

//         for (int i = 0; i < 500; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }
//         for (int i = 0; i < 500; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         try { Thread.sleep(1000L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 500 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 500);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 400 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 400);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 300 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 300);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 200 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 200);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertTrue("Should be less than 100 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() < 100);
//         try { Thread.sleep(600L); } catch(InterruptedException e) { }
//         assertEquals("Should be zero idle, found " + genericObjectPool.getNumIdle(),0,genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testEvictionInvalid(){

//         try (GenericObjectPool!(Object) invalidFactoryPool = new GenericObjectPool<>(new InvalidFactory())) {

//             invalidFactoryPool.setMaxIdle(1);
//             invalidFactoryPool.setMaxTotal(1);
//             invalidFactoryPool.setTestOnBorrow(false);
//             invalidFactoryPool.setTestOnReturn(false);
//             invalidFactoryPool.setTestWhileIdle(true);
//             invalidFactoryPool.setMinEvictableIdleTimeMillis(100000);
//             invalidFactoryPool.setNumTestsPerEvictionRun(1);

//             Object p = invalidFactoryPool.borrowObject();
//             invalidFactoryPool.returnObject(p);

//             // Run eviction in a separate thread
//             Thread t = new EvictionThread<>(invalidFactoryPool);
//             t.start();

//             // Sleep to make sure evictor has started
//             Thread.sleep(300);

//             try {
//                 invalidFactoryPool.borrowObject(1);
//             } catch (NoSuchElementException nsee) {
//                 // Ignore
//             }

//             // Make sure evictor has finished
//             Thread.sleep(1000);

//             // Should have an empty pool
//             assertEquals("Idle count different than expected.", 0, invalidFactoryPool.getNumIdle());
//             assertEquals("Total count different than expected.", 0, invalidFactoryPool.getNumActive());
//         }
//     }

//     /**
//      * Test to make sure evictor visits least recently used objects first,
//      * regardless of FIFO/LIFO.
//      *
//      * JIRA: POOL-86
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test(timeout = 60000)
//     void testEvictionOrder(){
//         checkEvictionOrder(false);
//         tearDown();
//         setUp();
//         checkEvictionOrder(true);
//     }

//     @Test(timeout = 60000)
//     void testEvictionPolicy(){
//         genericObjectPool.setMaxIdle(500);
//         genericObjectPool.setMaxTotal(500);
//         genericObjectPool.setNumTestsPerEvictionRun(500);
//         genericObjectPool.setMinEvictableIdleTimeMillis(250L);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(500L);
//         genericObjectPool.setTestWhileIdle(true);

//         // ClassNotFoundException
//         try {
//             genericObjectPool.setEvictionPolicyClassName(Long.toString(DateTimeHelper.currentTimeMillis()));
//             fail("setEvictionPolicyClassName must throw an error if the class name is invalid.");
//         } catch (IllegalArgumentException e) {
//             // expected
//         }

//         // InstantiationException
//         try {
//             genericObjectPool.setEvictionPolicyClassName(java.io.typeid(Serializable).name);
//             fail("setEvictionPolicyClassName must throw an error if the class name is invalid.");
//         } catch (IllegalArgumentException e) {
//             // expected
//         }

//         // IllegalAccessException
//         try {
//             genericObjectPool.setEvictionPolicyClassName(java.util.typeid(Collections).name);
//             fail("setEvictionPolicyClassName must throw an error if the class name is invalid.");
//         } catch (IllegalArgumentException e) {
//             // expected
//         }

//         try {
//             genericObjectPool.setEvictionPolicyClassName(java.lang.typeid(string).name);
//             fail("setEvictionPolicyClassName must throw an error if a class that does not "
//                     + "implement EvictionPolicy is specified.");
//         } catch (IllegalArgumentException e) {
//             // expected
//         }

//         genericObjectPool.setEvictionPolicy(new TestEvictionPolicy!(string)());
//         assertEquals(typeid(TestEvictionPolicy).name, genericObjectPool.getEvictionPolicyClassName());

//         genericObjectPool.setEvictionPolicyClassName(typeid(TestEvictionPolicy).name);
//         assertEquals(typeid(TestEvictionPolicy).name, genericObjectPool.getEvictionPolicyClassName());

//         string[] active = new string[500];
//         for (int i = 0; i < 500; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }
//         for (int i = 0; i < 500; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         // Eviction policy ignores first 1500 attempts to evict and then always
//         // evicts. After 1s, there should have been two runs of 500 tests so no
//         // evictions
//         try { Thread.sleep(1000L); } catch(InterruptedException e) { }
//         assertEquals("Should be 500 idle", 500, genericObjectPool.getNumIdle());
//         // A further 1s wasn't enough so allow 2s for the evictor to clear out
//         // all of the idle objects.
//         try { Thread.sleep(2000L); } catch(InterruptedException e) { }
//         assertEquals("Should be 0 idle", 0, genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testEvictionSoftMinIdle(){
//         class TimeTest : BasePooledObjectFactory!(TimeTest) {
//             private long createTime;

//             TimeTest() {
//                 createTime = DateTimeHelper.currentTimeMillis();
//             }

//             override
//             TimeTest create(){
//                 return new TimeTest();
//             }

//             long getCreateTime() {
//                 return createTime;
//             }

//             override
//             PooledObject!(TimeTest) wrap(TimeTest value) {
//                 return new DefaultPooledObject<>(value);
//             }
//         }

//         try (GenericObjectPool!(TimeTest) timePool = new GenericObjectPool<>(new TimeTest())) {

//             timePool.setMaxIdle(5);
//             timePool.setMaxTotal(5);
//             timePool.setNumTestsPerEvictionRun(5);
//             timePool.setMinEvictableIdleTimeMillis(3000L);
//             timePool.setSoftMinEvictableIdleTimeMillis(1000L);
//             timePool.setMinIdle(2);

//             TimeTest[] active = new TimeTest[5];
//             Long[] creationTime = new Long[5];
//             for (int i = 0; i < 5; i++) {
//                 active[i] = timePool.borrowObject();
//                 creationTime[i] = Long.valueOf((active[i]).getCreateTime());
//             }

//             for (int i = 0; i < 5; i++) {
//                 timePool.returnObject(active[i]);
//             }

//             // Soft evict all but minIdle(2)
//             Thread.sleep(1500L);
//             timePool.evict();
//             assertEquals("Idle count different than expected.", 2, timePool.getNumIdle());

//             // Hard evict the rest.
//             Thread.sleep(2000L);
//             timePool.evict();
//             assertEquals("Idle count different than expected.", 0, timePool.getNumIdle());
//         }
//     }

//     @Test(timeout = 60000)
//     void testEvictionWithNegativeNumTests(){
//         // when numTestsPerEvictionRun is negative, it represents a fraction of the idle objects to test
//         genericObjectPool.setMaxIdle(6);
//         genericObjectPool.setMaxTotal(6);
//         genericObjectPool.setNumTestsPerEvictionRun(-2);
//         genericObjectPool.setMinEvictableIdleTimeMillis(50L);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(100L);

//         string[] active = new string[6];
//         for (int i = 0; i < 6; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }
//         for (int i = 0; i < 6; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         try { Thread.sleep(100L); } catch(InterruptedException e) { }
//         assertTrue("Should at most 6 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() <= 6);
//         try { Thread.sleep(100L); } catch(InterruptedException e) { }
//         assertTrue("Should at most 3 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() <= 3);
//         try { Thread.sleep(100L); } catch(InterruptedException e) { }
//         assertTrue("Should be at most 2 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() <= 2);
//         try { Thread.sleep(100L); } catch(InterruptedException e) { }
//         assertEquals("Should be zero idle, found " + genericObjectPool.getNumIdle(),0,genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testEvictLIFO(){
//         checkEvict(true);
//     }

//     /**
//      * Verifies that the evictor visits objects in expected order
//      * and frequency.
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test
//     void testEvictorVisiting(){
//         checkEvictorVisiting(true);
//         checkEvictorVisiting(false);
//     }

//     @Test(timeout = 60000)
//     void testEvictWhileEmpty(){
//         genericObjectPool.evict();
//         genericObjectPool.evict();
//         genericObjectPool.close();
//     }

//     @Test(timeout = 60000)
//     void testExceptionOnActivateDuringBorrow(){
//         string obj1 = genericObjectPool.borrowObject();
//         string obj2 = genericObjectPool.borrowObject();
//         genericObjectPool.returnObject(obj1);
//         genericObjectPool.returnObject(obj2);
//         simpleFactory.setThrowExceptionOnActivate(true);
//         simpleFactory.setEvenValid(false);
//         // Activation will now throw every other time
//         // First attempt throws, but loop continues and second succeeds
//         string obj = genericObjectPool.borrowObject();
//         assertEquals(1, genericObjectPool.getNumActive());
//         assertEquals(0, genericObjectPool.getNumIdle());

//         genericObjectPool.returnObject(obj);
//         simpleFactory.setValid(false);
//         // Validation will now fail on activation when borrowObject returns
//         // an idle instance, and then when attempting to create a new instance
//         try {
//             genericObjectPool.borrowObject();
//             fail("Expecting NoSuchElementException");
//         } catch (NoSuchElementException ex) {
//             // expected
//         }
//         assertEquals(0, genericObjectPool.getNumActive());
//         assertEquals(0, genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testExceptionOnDestroyDuringBorrow(){
//         simpleFactory.setThrowExceptionOnDestroy(true);
//         genericObjectPool.setTestOnBorrow(true);
//         genericObjectPool.borrowObject();
//         simpleFactory.setValid(false); // Make validation fail on next borrow attempt
//         try {
//             genericObjectPool.borrowObject();
//             fail("Expecting NoSuchElementException");
//         } catch (NoSuchElementException ex) {
//             // expected
//         }
//         assertEquals(1, genericObjectPool.getNumActive());
//         assertEquals(0, genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testExceptionOnDestroyDuringReturn(){
//         simpleFactory.setThrowExceptionOnDestroy(true);
//         genericObjectPool.setTestOnReturn(true);
//         string obj1 = genericObjectPool.borrowObject();
//         genericObjectPool.borrowObject();
//         simpleFactory.setValid(false); // Make validation fail
//         genericObjectPool.returnObject(obj1);
//         assertEquals(1, genericObjectPool.getNumActive());
//         assertEquals(0, genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testExceptionOnPassivateDuringReturn(){
//         string obj = genericObjectPool.borrowObject();
//         simpleFactory.setThrowExceptionOnPassivate(true);
//         genericObjectPool.returnObject(obj);
//         assertEquals(0,genericObjectPool.getNumIdle());
//     }

//     @Test
//     void testFailingFactoryDoesNotBlockThreads(){

//         CreateFailFactory factory = new CreateFailFactory();
//         try (GenericObjectPool!(string) createFailFactoryPool = new GenericObjectPool<>(factory)) {

//             createFailFactoryPool.setMaxTotal(1);

//             // Try and borrow the first object from the pool
//             WaitingTestThread thread1 = new WaitingTestThread(createFailFactoryPool, 0);
//             thread1.start();

//             // Wait for thread to reach semaphore
//             while (!factory.hasQueuedThreads()) {
//                 Thread.sleep(200);
//             }

//             // Try and borrow the second object from the pool
//             WaitingTestThread thread2 = new WaitingTestThread(createFailFactoryPool, 0);
//             thread2.start();
//             // Pool will not call factory since maximum number of object creations
//             // are already queued.

//             // Thread 2 will wait on an object being returned to the pool
//             // Give thread 2 a chance to reach this state
//             Thread.sleep(1000);

//             // Release thread1
//             factory.release();
//             // Pre-release thread2
//             factory.release();

//             // Both threads should now complete.
//             bool threadRunning = true;
//             int count = 0;
//             while (threadRunning && count < 15) {
//                 threadRunning = thread1.isAlive();
//                 threadRunning = thread2.isAlive();
//                 Thread.sleep(200);
//                 count++;
//             }
//             Assert.assertFalse(thread1.isAlive());
//             Assert.assertFalse(thread2.isAlive());

//             Assert.assertTrue(thread1._thrown instanceof UnsupportedCharsetException);
//             Assert.assertTrue(thread2._thrown instanceof UnsupportedCharsetException);
//         }
//     }

//     @Test(timeout = 60000)
//     void testFIFO(){
//         string o = null;
//         genericObjectPool.setLifo(false);
//         genericObjectPool.addObject(); // "0"
//         genericObjectPool.addObject(); // "1"
//         genericObjectPool.addObject(); // "2"
//         assertEquals("Oldest", "0", genericObjectPool.borrowObject());
//         assertEquals("Middle", "1", genericObjectPool.borrowObject());
//         assertEquals("Youngest", "2", genericObjectPool.borrowObject());
//         o = genericObjectPool.borrowObject();
//         assertEquals("new-3", "3", o);
//         genericObjectPool.returnObject(o);
//         assertEquals("returned-3", o, genericObjectPool.borrowObject());
//         assertEquals("new-4", "4", genericObjectPool.borrowObject());
//     }

//     @Test
//     void testGetFactoryType_DefaultPooledObjectFactory() {
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(createDefaultPooledObjectFactory())) {
//             Assert.assertNotNull((pool.getFactoryType()));
//         }
//     }

//     @Test
//     void testGetFactoryType_NullPooledObjectFactory() {
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(createNullPooledObjectFactory())) {
//             Assert.assertNotNull((pool.getFactoryType()));
//         }
//     }

//     @Test
//     void testGetFactoryType_PoolUtilsSynchronizedDefaultPooledFactory() {
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(
//                 PoolUtils.synchronizedPooledFactory(createDefaultPooledObjectFactory()))) {
//             Assert.assertNotNull((pool.getFactoryType()));
//         }
//     }

//     @Test
//     void testGetFactoryType_PoolUtilsSynchronizedNullPooledFactory() {
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(
//                 PoolUtils.synchronizedPooledFactory(createNullPooledObjectFactory()))) {
//             Assert.assertNotNull((pool.getFactoryType()));
//         }
//     }

//     @Test
//     void testGetFactoryType_SynchronizedDefaultPooledObjectFactory() {
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(
//                 new TestSynchronizedPooledObjectFactory<>(createDefaultPooledObjectFactory()))) {
//             Assert.assertNotNull((pool.getFactoryType()));
//         }
//     }

//     @Test
//     void testGetFactoryType_SynchronizedNullPooledObjectFactory() {
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(
//                 new TestSynchronizedPooledObjectFactory<>(createNullPooledObjectFactory()))) {
//             Assert.assertNotNull((pool.getFactoryType()));
//         }
//     }

//     /**
//      * Verify that threads waiting on a depleted pool get served when a checked out object is
//      * invalidated.
//      *
//      * JIRA: POOL-240
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test
//     void testInvalidateFreesCapacity(){
//         SimpleFactory factory = new SimpleFactory();
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(factory)) {
//             pool.setMaxTotal(2);
//             pool.setMaxWaitMillis(500);
//             // Borrow an instance and hold if for 5 seconds
//             WaitingTestThread thread1 = new WaitingTestThread(pool, 5000);
//             thread1.start();
//             // Borrow another instance
//             string obj = pool.borrowObject();
//             // Launch another thread - will block, but fail in 500 ms
//             WaitingTestThread thread2 = new WaitingTestThread(pool, 100);
//             thread2.start();
//             // Invalidate the object borrowed by this thread - should allow thread2 to create
//             Thread.sleep(20);
//             pool.invalidateObject(obj);
//             Thread.sleep(600); // Wait for thread2 to timeout
//             if (thread2._thrown !is null) {
//                 fail(thread2._thrown.toString());
//             }
//         }
//     }

//     /**
//      * Ensure the pool is registered.
//      */
//     @Test(timeout = 60000)
//     void testJmxRegistration() {
//         ObjectName oname = genericObjectPool.getJmxName();
//         MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
//         Set!(ObjectName) result = mbs.queryNames(oname, null);
//         Assert.assertEquals(1, result.size());
//         genericObjectPool.jmxUnregister();

//         GenericObjectPoolConfig!(string) config = new GenericObjectPoolConfig<>();
//         config.setJmxEnabled(false);
//         try (GenericObjectPool!(string) poolWithoutJmx = new GenericObjectPool<>(simpleFactory, config)) {
//             assertNull(poolWithoutJmx.getJmxName());
//             config.setJmxEnabled(true);
//             poolWithoutJmx.jmxUnregister();
//         }

//         config.setJmxNameBase(null);
//         try (GenericObjectPool!(string) poolWithDefaultJmxNameBase = new GenericObjectPool<>(simpleFactory, config)) {
//             assertNotNull(poolWithDefaultJmxNameBase.getJmxName());
//         }
//     }

//     @Test(timeout = 60000)
//     void testLIFO(){
//         string o = null;
//         genericObjectPool.setLifo(true);
//         genericObjectPool.addObject(); // "0"
//         genericObjectPool.addObject(); // "1"
//         genericObjectPool.addObject(); // "2"
//         assertEquals("Youngest", "2", genericObjectPool.borrowObject());
//         assertEquals("Middle", "1", genericObjectPool.borrowObject());
//         assertEquals("Oldest", "0", genericObjectPool.borrowObject());
//         o = genericObjectPool.borrowObject();
//         assertEquals("new-3", "3", o);
//         genericObjectPool.returnObject(o);
//         assertEquals("returned-3", o, genericObjectPool.borrowObject());
//         assertEquals("new-4", "4", genericObjectPool.borrowObject());
//     }

//     /**
//      * Test the following scenario:
//      *   Thread 1 borrows an instance
//      *   Thread 2 starts to borrow another instance before thread 1 returns its instance
//      *   Thread 1 returns its instance while thread 2 is validating its newly created instance
//      * The test verifies that the instance created by Thread 2 is not leaked.
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test(timeout = 60000)
//     void testMakeConcurrentWithReturn(){
//         genericObjectPool.setTestOnBorrow(true);
//         simpleFactory.setValid(true);
//         // Borrow and return an instance, with a short wait
//         WaitingTestThread thread1 = new WaitingTestThread(genericObjectPool, 200);
//         thread1.start();
//         Thread.sleep(50); // wait for validation to succeed
//         // Slow down validation and borrow an instance
//         simpleFactory.setValidateLatency(400);
//         string instance = genericObjectPool.borrowObject();
//         // Now make sure that we have not leaked an instance
//         assertEquals(simpleFactory.getMakeCounter(), genericObjectPool.getNumIdle() + 1);
//         genericObjectPool.returnObject(instance);
//         assertEquals(simpleFactory.getMakeCounter(), genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testMaxIdle(){
//         genericObjectPool.setMaxTotal(100);
//         genericObjectPool.setMaxIdle(8);
//         string[] active = new string[100];
//         for(int i=0;i<100;i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }
//         assertEquals(100,genericObjectPool.getNumActive());
//         assertEquals(0,genericObjectPool.getNumIdle());
//         for(int i=0;i<100;i++) {
//             genericObjectPool.returnObject(active[i]);
//             assertEquals(99 - i,genericObjectPool.getNumActive());
//             assertEquals((i < 8 ? i+1 : 8),genericObjectPool.getNumIdle());
//         }
//     }

//     @Test(timeout = 60000)
//     void testMaxIdleZero(){
//         genericObjectPool.setMaxTotal(100);
//         genericObjectPool.setMaxIdle(0);
//         string[] active = new string[100];
//         for(int i=0;i<100;i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }
//         assertEquals(100,genericObjectPool.getNumActive());
//         assertEquals(0,genericObjectPool.getNumIdle());
//         for(int i=0;i<100;i++) {
//             genericObjectPool.returnObject(active[i]);
//             assertEquals(99 - i,genericObjectPool.getNumActive());
//             assertEquals(0, genericObjectPool.getNumIdle());
//         }
//     }

//     /**
//      * Showcasing a possible deadlock situation as reported in POOL-356
//      */
//     @Test(timeout = 60000)
//     @SuppressWarnings("rawtypes")
//     void testMaxIdleZeroUnderLoad() {
//         // Config
//         int numThreads = 199; // And main thread makes a round 200.
//         int numIter = 20;
//         int delay = 25;
//         int maxTotal = 10;

//         simpleFactory.setMaxTotal(maxTotal);
//         genericObjectPool.setMaxTotal(maxTotal);
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(-1);

//         // this is important to trigger POOL-356
//         genericObjectPool.setMaxIdle(0);

//         // Start threads to borrow objects
//         TestThread[] threads = new TestThread[numThreads];
//         for(int i=0;i<numThreads;i++) {
//             // Factor of 2 on iterations so main thread does work whilst other
//             // threads are running. Factor of 2 on delay so average delay for
//             // other threads == actual delay for main thread
//             threads[i] = new TestThread<>(genericObjectPool, numIter * 2, delay * 2);
//             Thread t = new Thread(threads[i]);
//             t.start();
//         }
//         // Give the threads a chance to start doing some work
//         try {
//             Thread.sleep(100);
//         } catch(InterruptedException e) {
//             // ignored
//         }

//         for (int i = 0; i < numIter; i++) {
//             string obj = null;
//             try {
//                 try {
//                     Thread.sleep(delay);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//                 obj = genericObjectPool.borrowObject();
//                 // Under load, observed _numActive > _maxTotal
//                 if (genericObjectPool.getNumActive() > genericObjectPool.getMaxTotal()) {
//                     throw new IllegalStateException("Too many active objects");
//                 }
//                 try {
//                     Thread.sleep(delay);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//             } catch (Exception e) {
//                 // Shouldn't happen
//                 e.printStackTrace();
//                 fail("Exception on borrow");
//             } finally {
//                 if (obj !is null) {
//                     try {
//                         genericObjectPool.returnObject(obj);
//                     } catch (Exception e) {
//                         // Ignore
//                     }
//                 }
//             }
//         }

//         for(int i=0;i<numThreads;i++) {
//             while(!(threads[i]).complete()) {
//                 try {
//                     Thread.sleep(500L);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//             }
//             if(threads[i].failed()) {
//                 threads[i]._error.printStackTrace();
//                 fail("Thread "+i+" failed: "+threads[i]._error.toString());
//             }
//         }
//     }

//     @Test(timeout = 60000)
//     void testMaxTotal(){
//         genericObjectPool.setMaxTotal(3);
//         genericObjectPool.setBlockWhenExhausted(false);

//         genericObjectPool.borrowObject();
//         genericObjectPool.borrowObject();
//         genericObjectPool.borrowObject();
//         try {
//             genericObjectPool.borrowObject();
//             fail("Expected NoSuchElementException");
//         } catch(NoSuchElementException e) {
//             // expected
//         }
//     }

//     /**
//      * Verifies that maxTotal is not exceeded when factory destroyObject
//      * has high latency, testOnReturn is set and there is high incidence of
//      * validation failures.
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test(timeout = 60000)
//     void testMaxTotalInvariant(){
//         int maxTotal = 15;
//         simpleFactory.setEvenValid(false);     // Every other validation fails
//         simpleFactory.setDestroyLatency(100);  // Destroy takes 100 ms
//         simpleFactory.setMaxTotal(maxTotal); // (makes - destroys) bound
//         simpleFactory.setValidationEnabled(true);
//         genericObjectPool.setMaxTotal(maxTotal);
//         genericObjectPool.setMaxIdle(-1);
//         genericObjectPool.setTestOnReturn(true);
//         genericObjectPool.setMaxWaitMillis(1000L);
//         runTestThreads(5, 10, 50, genericObjectPool);
//     }

//     @Test(timeout = 60000)
//     @SuppressWarnings("rawtypes")
//     void testMaxTotalUnderLoad() {
//         // Config
//         int numThreads = 199; // And main thread makes a round 200.
//         int numIter = 20;
//         int delay = 25;
//         int maxTotal = 10;

//         simpleFactory.setMaxTotal(maxTotal);
//         genericObjectPool.setMaxTotal(maxTotal);
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(-1);

//         // Start threads to borrow objects
//         TestThread[] threads = new TestThread[numThreads];
//         for(int i=0;i<numThreads;i++) {
//             // Factor of 2 on iterations so main thread does work whilst other
//             // threads are running. Factor of 2 on delay so average delay for
//             // other threads == actual delay for main thread
//             threads[i] = new TestThread<>(genericObjectPool, numIter * 2, delay * 2);
//             Thread t = new Thread(threads[i]);
//             t.start();
//         }
//         // Give the threads a chance to start doing some work
//         try {
//             Thread.sleep(5000);
//         } catch(InterruptedException e) {
//             // ignored
//         }

//         for (int i = 0; i < numIter; i++) {
//             string obj = null;
//             try {
//                 try {
//                     Thread.sleep(delay);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//                 obj = genericObjectPool.borrowObject();
//                 // Under load, observed _numActive > _maxTotal
//                 if (genericObjectPool.getNumActive() > genericObjectPool.getMaxTotal()) {
//                     throw new IllegalStateException("Too many active objects");
//                 }
//                 try {
//                     Thread.sleep(delay);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//             } catch (Exception e) {
//                 // Shouldn't happen
//                 e.printStackTrace();
//                 fail("Exception on borrow");
//             } finally {
//                 if (obj !is null) {
//                     try {
//                         genericObjectPool.returnObject(obj);
//                     } catch (Exception e) {
//                         // Ignore
//                     }
//                 }
//             }
//         }

//         for (int i = 0; i < numThreads; i++) {
//             while(!(threads[i]).complete()) {
//                 try {
//                     Thread.sleep(500L);
//                 } catch(InterruptedException e) {
//                     // ignored
//                 }
//             }
//             if(threads[i].failed()) {
//                 fail("Thread " + i + " failed: " + threads[i]._error.toString());
//             }
//         }
//     }

//     @Test(timeout = 60000)
//     void testMaxTotalZero(){
//         genericObjectPool.setMaxTotal(0);
//         genericObjectPool.setBlockWhenExhausted(false);

//         try {
//             genericObjectPool.borrowObject();
//             fail("Expected NoSuchElementException");
//         } catch(NoSuchElementException e) {
//             // expected
//         }
//     }

//     /*
//      * Test multi-threaded pool access.
//      * Multiple threads, but maxTotal only allows half the threads to succeed.
//      *
//      * This test was prompted by Continuum build failures in the Commons DBCP test case:
//      * TestPerUserPoolDataSource.testMultipleThreads2()
//      * Let's see if the this fails on Continuum too!
//      */
//     @Test(timeout = 60000)
//     void testMaxWaitMultiThreaded(){
//         long maxWait = 500; // wait for connection
//         long holdTime = 2 * maxWait; // how long to hold connection
//         int threads = 10; // number of threads to grab the object initially
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setMaxWaitMillis(maxWait);
//         genericObjectPool.setMaxTotal(threads);
//         // Create enough threads so half the threads will have to wait
//         WaitingTestThread wtt[] = new WaitingTestThread[threads * 2];
//         for (int i = 0; i < wtt.length; i++) {
//             wtt[i] = new WaitingTestThread(genericObjectPool,holdTime);
//         }
//         long origin = DateTimeHelper.currentTimeMillis() - 1000;
//         foreach(WaitingTestThread element ; wtt) {
//             element.start();
//         }
//         int failed = 0;
//         foreach(WaitingTestThread element ; wtt) {
//             element.join();
//             if (element._thrown !is null){
//                 failed++;
//             }
//         }
//         if (DISPLAY_THREAD_DETAILS || wtt.length/2 != failed){
//             System.out.println(
//                     "MaxWait: " + maxWait +
//                     " HoldTime: " + holdTime +
//                      " MaxTotal: " + threads +
//                     " Threads: " + wtt.length +
//                     " Failed: " + failed
//                     );
//             foreach(WaitingTestThread wt ; wtt) {
//                 System.out.println(
//                         "PreBorrow: " + (wt.preborrow - origin) +
//                         " PostBorrow: " + (wt.postborrow != 0 ? wt.postborrow - origin : -1) +
//                         " BorrowTime: " + (wt.postborrow != 0 ? wt.postborrow - wt.preborrow : -1) +
//                         " PostReturn: " + (wt.postreturn != 0 ? wt.postreturn - origin : -1) +
//                         " Ended: " + (wt.ended - origin) +
//                         " ObjId: " + wt.objectId
//                         );
//             }
//         }
//         assertEquals("Expected half the threads to fail",wtt.length / 2, failed);
//     }

//     @Test(timeout = 60000)
//     void testMinIdle(){
//         genericObjectPool.setMaxIdle(500);
//         genericObjectPool.setMinIdle(5);
//         genericObjectPool.setMaxTotal(10);
//         genericObjectPool.setNumTestsPerEvictionRun(0);
//         genericObjectPool.setMinEvictableIdleTimeMillis(50L);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(100L);
//         genericObjectPool.setTestWhileIdle(true);

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 5 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 5);

//         string[] active = new string[5];
//         active[0] = genericObjectPool.borrowObject();

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 5 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 5);

//         for(int i=1 ; i<5 ; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 5 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 5);

//         for(int i=0 ; i<5 ; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 10 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 10);
//     }

//     @Test(timeout = 60000)
//     void testMinIdleMaxTotal(){
//         genericObjectPool.setMaxIdle(500);
//         genericObjectPool.setMinIdle(5);
//         genericObjectPool.setMaxTotal(10);
//         genericObjectPool.setNumTestsPerEvictionRun(0);
//         genericObjectPool.setMinEvictableIdleTimeMillis(50L);
//         genericObjectPool.setTimeBetweenEvictionRunsMillis(100L);
//         genericObjectPool.setTestWhileIdle(true);

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 5 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 5);

//         string[] active = new string[10];

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 5 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 5);

//         for (int i = 0; i < 5; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 5 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 5);

//         for(int i = 0 ; i < 5 ; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 10 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 10);

//         for (int i = 0; i < 10; i++) {
//             active[i] = genericObjectPool.borrowObject();
//         }

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 0 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 0);

//         for (int i = 0; i < 10; i++) {
//             genericObjectPool.returnObject(active[i]);
//         }

//         try { Thread.sleep(150L); } catch(InterruptedException e) { }
//         assertTrue("Should be 10 idle, found " + genericObjectPool.getNumIdle(),genericObjectPool.getNumIdle() == 10);
//     }

//     /**
//      * Verifies that returning an object twice (without borrow in between) causes ISE
//      * but does not re-validate or re-passivate the instance.
//      *
//      * JIRA: POOL-285
//      */
//     @Test
//     void testMultipleReturn(){
//         WaiterFactory!(string) factory = new WaiterFactory<>(0, 0, 0, 0, 0, 0);
//         try (GenericObjectPool!(Waiter) pool = new GenericObjectPool<>(factory)) {
//             pool.setTestOnReturn(true);
//             Waiter waiter = pool.borrowObject();
//             pool.returnObject(waiter);
//             Assert.assertEquals(1, waiter.getValidationCount());
//             Assert.assertEquals(1, waiter.getPassivationCount());
//             try {
//                 pool.returnObject(waiter);
//                 fail("Expecting IllegalStateException from multiple return");
//             } catch (IllegalStateException ex) {
//                 // Exception is expected, now check no repeat validation/passivation
//                 Assert.assertEquals(1, waiter.getValidationCount());
//                 Assert.assertEquals(1, waiter.getPassivationCount());
//             }
//         }
//     }

//     // POOL-248
//     @Test(expected=IllegalStateException.class)
//     void testMultipleReturnOfSameObject(){
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(simpleFactory, new GenericObjectPoolConfig!(string)())) {

//             Assert.assertEquals(0, pool.getNumActive());
//             Assert.assertEquals(0, pool.getNumIdle());

//             string obj = pool.borrowObject();

//             Assert.assertEquals(1, pool.getNumActive());
//             Assert.assertEquals(0, pool.getNumIdle());

//             pool.returnObject(obj);

//             Assert.assertEquals(0, pool.getNumActive());
//             Assert.assertEquals(1, pool.getNumIdle());

//             pool.returnObject(obj);

//             Assert.assertEquals(0, pool.getNumActive());
//             Assert.assertEquals(1, pool.getNumIdle());
//         }
//     }

//     /**
//      * Verifies that when a borrowed object is mutated in a way that does not
//      * preserve equality and hashcode, the pool can recognized it on return.
//      *
//      * JIRA: POOL-284
//      */
//     @Test
//     void testMutable(){
//         HashSetFactory factory = new HashSetFactory();
//         try (GenericObjectPool!(HashSet!(string)) pool = new GenericObjectPool<>(factory,
//                 new GenericObjectPoolConfig!(HashSet!(string))())) {
//             HashSet!(string) s1 = pool.borrowObject();
//             HashSet!(string) s2 = pool.borrowObject();
//             s1.add("One");
//             s2.add("One");
//             pool.returnObject(s1);
//             pool.returnObject(s2);
//         }
//     }

//     @Test(timeout = 60000)
//     void testNegativeMaxTotal(){
//         genericObjectPool.setMaxTotal(-1);
//         genericObjectPool.setBlockWhenExhausted(false);
//         string obj = genericObjectPool.borrowObject();
//         assertEquals(getNthObject(0),obj);
//         genericObjectPool.returnObject(obj);
//     }

//     /**
//      * Verifies that concurrent threads never "share" instances
//      */
//     @Test
//     void testNoInstanceOverlap() {
//         int maxTotal = 5;
//         int numThreads = 100;
//         int delay = 1;
//         int iterations = 1000;
//         AtomicIntegerFactory factory = new AtomicIntegerFactory();
//         try (GenericObjectPool!(Integer) pool = new GenericObjectPool<>(factory)) {
//             pool.setMaxTotal(maxTotal);
//             pool.setMaxIdle(maxTotal);
//             pool.setTestOnBorrow(true);
//             pool.setBlockWhenExhausted(true);
//             pool.setMaxWaitMillis(-1);
//             runTestThreads(numThreads, iterations, delay, pool);
//             Assert.assertEquals(0, pool.getDestroyedByBorrowValidationCount());
//         }
//     }

//     void testPreparePool(){
//         genericObjectPool.setMinIdle(1);
//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.preparePool();
//         Assert.assertEquals(1, genericObjectPool.getNumIdle());
//         string obj = genericObjectPool.borrowObject();
//         genericObjectPool.preparePool();
//         Assert.assertEquals(0, genericObjectPool.getNumIdle());
//         genericObjectPool.setMinIdle(0);
//         genericObjectPool.returnObject(obj);
//         genericObjectPool.preparePool();
//         Assert.assertEquals(0, genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 1200 /* maxWaitMillis x2 + padding */)
//     void testReturnBorrowObjectWithingMaxWaitMillis(){
//         long maxWaitMillis = 500;

//         try (GenericObjectPool!(string) createSlowObjectFactoryPool = new GenericObjectPool<>(
//                 createSlowObjectFactory(60000))) {
//             createSlowObjectFactoryPool.setMaxTotal(1);
//             createSlowObjectFactoryPool.setMaxWaitMillis(maxWaitMillis);

//             // thread1 tries creating a slow object to make pool full.
//             WaitingTestThread thread1 = new WaitingTestThread(createSlowObjectFactoryPool, 0);
//             thread1.start();

//             // Wait for thread1's reaching to create().
//             Thread.sleep(100);

//             // another one tries borrowObject. It should return within maxWaitMillis.
//             try {
//                 createSlowObjectFactoryPool.borrowObject(maxWaitMillis);
//                 fail("borrowObject must fail due to timeout by maxWaitMillis");
//             } catch (NoSuchElementException e) {
//                 // ignore
//             }

//             Assert.assertTrue(thread1.isAlive());
//         }
//     }

//     /**
//      * This is the test case for POOL-263. It is disabled since it will always
//      * pass without artificial delay being injected into GOP.returnObject() and
//      * a way to this hasn't currently been found that doesn't involve
//      * polluting the GOP implementation. The artificial delay needs to be
//      * inserted just before the call to isLifo() in the returnObject()
//      * method.
//      */
//     //@Test(timeout = 60000)
//     void testReturnObject(){

//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.setMaxIdle(-1);
//         string active = genericObjectPool.borrowObject();

//         assertEquals(1, genericObjectPool.getNumActive());
//         assertEquals(0, genericObjectPool.getNumIdle());

//         Thread t = new Thread() {

//             override
//             void run() {
//                 genericObjectPool.close();
//             }

//         };
//         t.start();

//         genericObjectPool.returnObject(active);

//         // Wait for the close() thread to complete
//         while (t.isAlive()) {
//             Thread.sleep(50);
//         }

//         assertEquals(0, genericObjectPool.getNumIdle());
//     }

//     @Test(timeout = 60000)
//     void testSetConfig(){
//         GenericObjectPoolConfig!(string) expected = new GenericObjectPoolConfig<>();
//         assertConfiguration(expected,genericObjectPool);
//         expected.setMaxTotal(2);
//         expected.setMaxIdle(3);
//         expected.setMaxWaitMillis(5L);
//         expected.setMinEvictableIdleTimeMillis(7L);
//         expected.setNumTestsPerEvictionRun(9);
//         expected.setTestOnCreate(true);
//         expected.setTestOnBorrow(true);
//         expected.setTestOnReturn(true);
//         expected.setTestWhileIdle(true);
//         expected.setTimeBetweenEvictionRunsMillis(11L);
//         expected.setBlockWhenExhausted(false);
//         genericObjectPool.setConfig(expected);
//         assertConfiguration(expected,genericObjectPool);
//     }

//     @Test(timeout = 60000)
//     void testSettersAndGetters(){
//         {
//             // The object receives an Exception during its creation to prevent
//             // memory leaks. See BaseGenericObjectPool constructor for more details.
//             assertTrue(false == "" == genericObjectPool.getCreationStackTrace());
//         }
//         {
//             assertEquals(0, genericObjectPool.getBorrowedCount());
//         }
//         {
//             assertEquals(0, genericObjectPool.getReturnedCount());
//         }
//         {
//             assertEquals(0, genericObjectPool.getCreatedCount());
//         }
//         {
//             assertEquals(0, genericObjectPool.getDestroyedCount());
//         }
//         {
//             assertEquals(0, genericObjectPool.getDestroyedByEvictorCount());
//         }
//         {
//             assertEquals(0, genericObjectPool.getDestroyedByBorrowValidationCount());
//         }
//         {
//             assertEquals(0, genericObjectPool.getMeanActiveTimeMillis());
//         }
//         {
//             assertEquals(0, genericObjectPool.getMeanIdleTimeMillis());
//         }
//         {
//             assertEquals(0, genericObjectPool.getMeanBorrowWaitTimeMillis());
//         }
//         {
//             assertEquals(0, genericObjectPool.getMaxBorrowWaitTimeMillis());
//         }
//         {
//             assertEquals(0, genericObjectPool.getNumIdle());
//         }
//         {
//             genericObjectPool.setMaxTotal(123);
//             assertEquals(123,genericObjectPool.getMaxTotal());
//         }
//         {
//             genericObjectPool.setMaxIdle(12);
//             assertEquals(12,genericObjectPool.getMaxIdle());
//         }
//         {
//             genericObjectPool.setMaxWaitMillis(1234L);
//             assertEquals(1234L,genericObjectPool.getMaxWaitMillis());
//         }
//         {
//             genericObjectPool.setMinEvictableIdleTimeMillis(12345L);
//             assertEquals(12345L,genericObjectPool.getMinEvictableIdleTimeMillis());
//         }
//         {
//             genericObjectPool.setNumTestsPerEvictionRun(11);
//             assertEquals(11,genericObjectPool.getNumTestsPerEvictionRun());
//         }
//         {
//             genericObjectPool.setTestOnBorrow(true);
//             assertTrue(genericObjectPool.getTestOnBorrow());
//             genericObjectPool.setTestOnBorrow(false);
//             assertTrue(!genericObjectPool.getTestOnBorrow());
//         }
//         {
//             genericObjectPool.setTestOnReturn(true);
//             assertTrue(genericObjectPool.getTestOnReturn());
//             genericObjectPool.setTestOnReturn(false);
//             assertTrue(!genericObjectPool.getTestOnReturn());
//         }
//         {
//             genericObjectPool.setTestWhileIdle(true);
//             assertTrue(genericObjectPool.getTestWhileIdle());
//             genericObjectPool.setTestWhileIdle(false);
//             assertTrue(!genericObjectPool.getTestWhileIdle());
//         }
//         {
//             genericObjectPool.setTimeBetweenEvictionRunsMillis(11235L);
//             assertEquals(11235L,genericObjectPool.getTimeBetweenEvictionRunsMillis());
//         }
//         {
//             genericObjectPool.setSoftMinEvictableIdleTimeMillis(12135L);
//             assertEquals(12135L,genericObjectPool.getSoftMinEvictableIdleTimeMillis());
//         }
//         {
//             genericObjectPool.setBlockWhenExhausted(true);
//             assertTrue(genericObjectPool.getBlockWhenExhausted());
//             genericObjectPool.setBlockWhenExhausted(false);
//             assertFalse(genericObjectPool.getBlockWhenExhausted());
//         }
//     }

//     @Test(timeout = 60000)
//     void testStartAndStopEvictor(){
//         // set up pool without evictor
//         genericObjectPool.setMaxIdle(6);
//         genericObjectPool.setMaxTotal(6);
//         genericObjectPool.setNumTestsPerEvictionRun(6);
//         genericObjectPool.setMinEvictableIdleTimeMillis(100L);

//         for (int j = 0; j < 2; j++) {
//             // populate the pool
//             {
//                 string[] active = new string[6];
//                 for (int i = 0; i < 6; i++) {
//                     active[i] = genericObjectPool.borrowObject();
//                 }
//                 for (int i = 0; i < 6; i++) {
//                     genericObjectPool.returnObject(active[i]);
//                 }
//             }

//             // note that it stays populated
//             assertEquals("Should have 6 idle",6,genericObjectPool.getNumIdle());

//             // start the evictor
//             genericObjectPool.setTimeBetweenEvictionRunsMillis(50L);

//             // wait a second (well, .2 seconds)
//             try { Thread.sleep(200L); } catch(InterruptedException e) { }

//             // assert that the evictor has cleared out the pool
//             assertEquals("Should have 0 idle",0,genericObjectPool.getNumIdle());

//             // stop the evictor
//             genericObjectPool.startEvictor(0L);
//         }
//     }

//     @Test
//     void testSwallowedExceptionListener() {
//         genericObjectPool.setSwallowedExceptionListener(null); // must simply return
//         List!(Exception) swallowedExceptions = new ArrayList<>();
//         /*
//          * A simple listener, that will throw a OOM on 3rd exception.
//          */
//         SwallowedExceptionListener listener = new SwallowedExceptionListener() {
//             override
//             void onSwallowException(Exception e) {
//                 if (swallowedExceptions.size() == 2) {
//                     throw new OutOfMemoryError();
//                 }
//                 swallowedExceptions.add(e);
//             }
//         };
//         genericObjectPool.setSwallowedExceptionListener(listener);

//         Exception e1 = new Exception();
//         Exception e2 = new ArrayIndexOutOfBoundsException();

//         genericObjectPool.swallowException(e1);
//         genericObjectPool.swallowException(e2);

//         try {
//             genericObjectPool.swallowException(e1);
//             fail("Not supposed to get here");
//         } catch (OutOfMemoryError oom) {
//             // expected
//         }

//         assertEquals(2, swallowedExceptions.size());
//     }

//     @Test(timeout = 60000)
//     void testThreaded1(){
//         genericObjectPool.setMaxTotal(15);
//         genericObjectPool.setMaxIdle(15);
//         genericObjectPool.setMaxWaitMillis(1000L);
//         runTestThreads(20, 100, 50, genericObjectPool);
//     }

//     @Test(timeout = 60000)
//     void testTimeoutNoLeak(){
//         genericObjectPool.setMaxTotal(2);
//         genericObjectPool.setMaxWaitMillis(10);
//         genericObjectPool.setBlockWhenExhausted(true);
//         string obj = genericObjectPool.borrowObject();
//         string obj2 = genericObjectPool.borrowObject();
//         try {
//             genericObjectPool.borrowObject();
//             fail("Expecting NoSuchElementException");
//         } catch (NoSuchElementException ex) {
//             // expected
//         }
//         genericObjectPool.returnObject(obj2);
//         genericObjectPool.returnObject(obj);

//         genericObjectPool.borrowObject();
//         genericObjectPool.borrowObject();
//     }

//     /**
//      * Verify that threads waiting on a depleted pool get served when a returning object fails
//      * validation.
//      *
//      * JIRA: POOL-240
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test
//     void testValidationFailureOnReturnFreesCapacity(){
//         SimpleFactory factory = new SimpleFactory();
//         factory.setValid(false); // Validate will always fail
//         factory.setValidationEnabled(true);
//         try (GenericObjectPool!(string) pool = new GenericObjectPool<>(factory)) {
//             pool.setMaxTotal(2);
//             pool.setMaxWaitMillis(1500);
//             pool.setTestOnReturn(true);
//             pool.setTestOnBorrow(false);
//             // Borrow an instance and hold if for 5 seconds
//             WaitingTestThread thread1 = new WaitingTestThread(pool, 5000);
//             thread1.start();
//             // Borrow another instance and return it after 500 ms (validation will fail)
//             WaitingTestThread thread2 = new WaitingTestThread(pool, 500);
//             thread2.start();
//             Thread.sleep(50);
//             // Try to borrow an object
//             string obj = pool.borrowObject();
//             pool.returnObject(obj);
//         }
//     }

//     // POOL-276
//     @Test
//     void testValidationOnCreateOnly(){
//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.setTestOnCreate(true);
//         genericObjectPool.setTestOnBorrow(false);
//         genericObjectPool.setTestOnReturn(false);
//         genericObjectPool.setTestWhileIdle(false);

//         string o1 = genericObjectPool.borrowObject();
//         Assert.assertEquals("0", o1);
//         Timer t = new Timer();
//         t.schedule(
//                 new TimerTask() {
//                     override
//                     void run() {
//                         genericObjectPool.returnObject(o1);
//                     }
//                 }, 3000);

//         string o2 = genericObjectPool.borrowObject();
//         Assert.assertEquals("0", o2);

//         Assert.assertEquals(1, simpleFactory.validateCounter);
//     }

//     @Test(timeout = 60000)
//     void testWhenExhaustedBlock(){
//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setMaxWaitMillis(10L);
//         string obj1 = genericObjectPool.borrowObject();
//         assertNotNull(obj1);
//         try {
//             genericObjectPool.borrowObject();
//             fail("Expected NoSuchElementException");
//         } catch(NoSuchElementException e) {
//             // expected
//         }
//         genericObjectPool.returnObject(obj1);
//         genericObjectPool.close();
//     }

//     /**
//      * POOL-189
//      *
//      * @throws Exception May occur in some failure modes
//      */
//     @Test(timeout = 60000)
//     void testWhenExhaustedBlockClosePool(){
//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setMaxWaitMillis(-1);
//         Object obj1 = genericObjectPool.borrowObject();

//         // Make sure an object was obtained
//         assertNotNull(obj1);

//         // Create a separate thread to try and borrow another object
//         WaitingTestThread wtt = new WaitingTestThread(genericObjectPool, 200);
//         wtt.start();
//         // Give wtt time to start
//         Thread.sleep(200);

//         // close the pool (Bug POOL-189)
//         genericObjectPool.close();

//         // Give interrupt time to take effect
//         Thread.sleep(200);

//         // Check thread was interrupted
//         assertTrue(wtt._thrown instanceof InterruptedException);
//     }

//     @Test(timeout = 60000)
//     void testWhenExhaustedBlockInterrupt(){
//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.setBlockWhenExhausted(true);
//         genericObjectPool.setMaxWaitMillis(-1);
//         string obj1 = genericObjectPool.borrowObject();

//         // Make sure on object was obtained
//         assertNotNull(obj1);

//         // Create a separate thread to try and borrow another object
//         WaitingTestThread wtt = new WaitingTestThread(genericObjectPool, 200000);
//         wtt.start();
//         // Give wtt time to start
//         Thread.sleep(200);
//         wtt.interrupt();

//         // Give interrupt time to take effect
//         Thread.sleep(200);

//         // Check thread was interrupted
//         assertTrue(wtt._thrown instanceof InterruptedException);

//         // Return object to the pool
//         genericObjectPool.returnObject(obj1);

//         // Bug POOL-162 - check there is now an object in the pool
//         genericObjectPool.setMaxWaitMillis(10L);
//         string obj2 = null;
//         try {
//              obj2 = genericObjectPool.borrowObject();
//             assertNotNull(obj2);
//         } catch(NoSuchElementException e) {
//             // Not expected
//             fail("NoSuchElementException not expected");
//         }
//         genericObjectPool.returnObject(obj2);
//         genericObjectPool.close();

//     }

//     @Test(timeout = 60000)
//     void testWhenExhaustedFail(){
//         genericObjectPool.setMaxTotal(1);
//         genericObjectPool.setBlockWhenExhausted(false);
//         string obj1 = genericObjectPool.borrowObject();
//         assertNotNull(obj1);
//         try {
//             genericObjectPool.borrowObject();
//             fail("Expected NoSuchElementException");
//         } catch(NoSuchElementException e) {
//             // expected
//         }
//         genericObjectPool.returnObject(obj1);
//         assertEquals(1, genericObjectPool.getNumIdle());
//         genericObjectPool.close();
//     }

// }
