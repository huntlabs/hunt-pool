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
module hunt.pool.impl.SoftReferenceObjectPool;

// import java.lang.ref.Reference;
// import java.lang.ref.ReferenceQueue;
// import java.lang.ref.SoftReference;
// import java.util.ArrayList;
// import java.util.Iterator;
// import java.util.NoSuchElementException;

import hunt.Exceptions;

import hunt.pool.BaseObjectPool;
import hunt.pool.ObjectPool;
import hunt.pool.PoolUtils;
import hunt.pool.PooledObjectFactory;

/**
 * A {@link java.lang.ref.SoftReference SoftReference} based {@link ObjectPool}.
 * <p>
 * This class is intended to be thread-safe.
 *
 * @param <T>
 *            Type of element pooled in this pool.
 *
 */
// class SoftReferenceObjectPool(T) : BaseObjectPool!(T) {

//     /** Factory to source pooled objects */
//     private PooledObjectFactory!(T) factory;

//     /**
//      * Queue of broken references that might be able to be removed from
//      * <code>_pool</code>. This is used to help {@link #getNumIdle()} be more
//      * accurate with minimal performance overhead.
//      */
//     private ReferenceQueue!(T) refQueue = new ReferenceQueue<>();

//     /** Count of instances that have been checkout out to pool clients */
//     private int numActive = 0; // @GuardedBy("this")

//     /** Total number of instances that have been destroyed */
//     private long destroyCount = 0; // @GuardedBy("this")


//     /** Total number of instances that have been created */
//     private long createCount = 0; // @GuardedBy("this")

//     /** Idle references - waiting to be borrowed */
//     private LinkedBlockingDeque!(PooledSoftReference!(T)) idleReferences =
//         new LinkedBlockingDeque<>();

//     /** All references - checked out or waiting to be borrowed. */
//     private ArrayList!(PooledSoftReference!(T)) allReferences =
//         new ArrayList<>();

//     /**
//      * Create a <code>SoftReferenceObjectPool</code> with the specified factory.
//      *
//      * @param factory object factory to use.
//      */
//     this(PooledObjectFactory!(T) factory) {
//         this.factory = factory;
//     }

//     /**
//      * Borrows an object from the pool. If there are no idle instances available
//      * in the pool, the configured factory's
//      * {@link PooledObjectFactory#makeObject()} method is invoked to create a
//      * new instance.
//      * <p>
//      * All instances are {@link PooledObjectFactory#activateObject(
//      * hunt.pool.PooledObject) activated}
//      * and {@link PooledObjectFactory#validateObject(
//      * hunt.pool.PooledObject)
//      * validated} before being returned by this method. If validation fails or
//      * an exception occurs activating or validating an idle instance, the
//      * failing instance is {@link PooledObjectFactory#destroyObject(
//      * hunt.pool.PooledObject)
//      * destroyed} and another instance is retrieved from the pool, validated and
//      * activated. This process continues until either the pool is empty or an
//      * instance passes validation. If the pool is empty on activation or it does
//      * not contain any valid instances, the factory's <code>makeObject</code>
//      * method is used to create a new instance. If the created instance either
//      * raises an exception on activation or fails validation,
//      * <code>NoSuchElementException</code> is thrown. Exceptions thrown by
//      * <code>MakeObject</code> are propagated to the caller; but other than
//      * <code>ThreadDeath</code> or <code>VirtualMachineError</code>, exceptions
//      * generated by activation, validation or destroy methods are swallowed
//      * silently.
//      *
//      * @throws NoSuchElementException
//      *             if a valid object cannot be provided
//      * @throws IllegalStateException
//      *             if invoked on a {@link #close() closed} pool
//      * @throws Exception
//      *             if an exception occurs creating a new instance
//      * @return a valid, activated object instance
//      */
//     override
//     T borrowObject() { // synchronized
//         assertOpen();
//         T obj = null;
//         bool newlyCreated = false;
//         PooledSoftReference!(T) ref = null;
//         // while (null == obj) {
//         //     if (idleReferences.isEmpty()) {
//         //         if (null == factory) {
//         //             throw new NoSuchElementException();
//         //         }
//         //         newlyCreated = true;
//         //         obj = factory.makeObject().getObject();
//         //         createCount++;
//         //         // Do not register with the queue
//         //         ref = new PooledSoftReference<>(new SoftReference<>(obj));
//         //         allReferences.add(ref);
//         //     } else {
//         //         ref = idleReferences.pollFirst();
//         //         obj = ref.getObject();
//         //         // Clear the reference so it will not be queued, but replace with a
//         //         // a new, non-registered reference so we can still track this object
//         //         // in allReferences
//         //         ref.getReference().clear();
//         //         ref.setReference(new SoftReference<>(obj));
//         //     }
//         //     if (null != factory && null != obj) {
//         //         try {
//         //             factory.activateObject(ref);
//         //             if (!factory.validateObject(ref)) {
//         //                 throw new Exception("ValidateObject failed");
//         //             }
//         //         } catch (Throwable t) {
//         //             PoolUtils.checkRethrow(t);
//         //             try {
//         //                 destroy(ref);
//         //             } catch (Throwable t2) {
//         //                 PoolUtils.checkRethrow(t2);
//         //                 // Swallowed
//         //             } finally {
//         //                 obj = null;
//         //             }
//         //             if (newlyCreated) {
//         //                 throw new NoSuchElementException(
//         //                         "Could not create a validated object, cause: " ~
//         //                                 t.getMessage());
//         //             }
//         //         }
//         //     }
//         // }
//         // numActive++;
//         // ref.allocate();
//         implementationMissing(false);
//         return obj;
//     }

//     /**
//      * Returns an instance to the pool after successful validation and
//      * passivation. The returning instance is destroyed if any of the following
//      * are true:
//      * <ul>
//      * <li>the pool is closed</li>
//      * <li>{@link PooledObjectFactory#validateObject(
//      * hunt.pool.PooledObject) validation} fails
//      * </li>
//      * <li>{@link PooledObjectFactory#passivateObject(
//      * hunt.pool.PooledObject) passivation}
//      *exception</li>
//      * </ul>
//      * Exceptions passivating or destroying instances are silently swallowed.
//      * Exceptions validating instances are propagated to the client.
//      *
//      * @param obj
//      *            instance to return to the pool
//      */
//     override
//     synchronized void returnObject(T obj){
//         bool success = !isClosed();
//         PooledSoftReference!(T) ref = findReference(obj);
//         if (ref is null) {
//             throw new IllegalStateException(
//                 "Returned object not currently part of this pool");
//         }
//         if (factory !is null) {
//             if (!factory.validateObject(ref)) {
//                 success = false;
//             } else {
//                 try {
//                     factory.passivateObject(ref);
//                 } catch (Exception e) {
//                     success = false;
//                 }
//             }
//         }

//         bool shouldDestroy = !success;
//         numActive--;
//         if (success) {

//             // Deallocate and add to the idle instance pool
//             ref.deallocate();
//             idleReferences.add(ref);
//         }
//         notifyAll(); // numActive has changed

//         if (shouldDestroy && factory !is null) {
//             try {
//                 destroy(ref);
//             } catch (Exception e) {
//                 // ignored
//             }
//         }
//     }

//     /**
//      * {@inheritDoc}
//      */
//     override
//     synchronized void invalidateObject(T obj){
//         PooledSoftReference!(T) ref = findReference(obj);
//         if (ref is null) {
//             throw new IllegalStateException(
//                 "Object to invalidate is not currently part of this pool");
//         }
//         if (factory !is null) {
//             destroy(ref);
//         }
//         numActive--;
//         notifyAll(); // numActive has changed
//     }

//     /**
//      * Creates an object, and places it into the pool. addObject() is useful for
//      * "pre-loading" a pool with idle objects.
//      * <p>
//      * Before being added to the pool, the newly created instance is
//      * {@link PooledObjectFactory#validateObject(
//      * hunt.pool.PooledObject) validated} and
//      * {@link PooledObjectFactory#passivateObject(
//      * hunt.pool.PooledObject) passivated}. If
//      * validation fails, the new instance is
//      * {@link PooledObjectFactory#destroyObject(
//      * hunt.pool.PooledObject) destroyed}. Exceptions
//      * generated by the factory <code>makeObject</code> or
//      * <code>passivate</code> are propagated to the caller. Exceptions
//      * destroying instances are silently swallowed.
//      *
//      * @throws IllegalStateException
//      *             if invoked on a {@link #close() closed} pool
//      * @throws Exception
//      *             when the {@link #getFactory() factory} has a problem creating
//      *             or passivating an object.
//      */
//     override
//     synchronized void addObject(){
//         assertOpen();
//         if (factory is null) {
//             throw new IllegalStateException(
//                     "Cannot add objects without a factory.");
//         }
//         T obj = factory.makeObject().getObject();
//         createCount++;
//         // Create and register with the queue
//         PooledSoftReference!(T) ref = new PooledSoftReference<>(
//                 new SoftReference<>(obj, refQueue));
//         allReferences.add(ref);

//         bool success = true;
//         if (!factory.validateObject(ref)) {
//             success = false;
//         } else {
//             factory.passivateObject(ref);
//         }

//         bool shouldDestroy = !success;
//         if (success) {
//             idleReferences.add(ref);
//             notifyAll(); // numActive has changed
//         }

//         if (shouldDestroy) {
//             try {
//                 destroy(ref);
//             } catch (Exception e) {
//                 // ignored
//             }
//         }
//     }

//     /**
//      * Returns an approximation not less than the of the number of idle
//      * instances in the pool.
//      *
//      * @return estimated number of idle instances in the pool
//      */
//     override
//     synchronized int getNumIdle() {
//         pruneClearedReferences();
//         return idleReferences.size();
//     }

//     /**
//      * Returns the number of instances currently borrowed from this pool.
//      *
//      * @return the number of instances currently borrowed from this pool
//      */
//     override
//     synchronized int getNumActive() {
//         return numActive;
//     }

//     /**
//      * Clears any objects sitting idle in the pool.
//      */
//     override
//     synchronized void clear() {
//         if (null != factory) {
//             Iterator!(PooledSoftReference!(T)) iter = idleReferences.iterator();
//             while (iter.hasNext()) {
//                 try {
//                     PooledSoftReference!(T) ref = iter.next();
//                     if (null != ref.getObject()) {
//                         factory.destroyObject(ref);
//                     }
//                 } catch (Exception e) {
//                     // ignore error, keep destroying the rest
//                 }
//             }
//         }
//         idleReferences.clear();
//         pruneClearedReferences();
//     }

//     /**
//      * Closes this pool, and frees any resources associated with it. Invokes
//      * {@link #clear()} to destroy and remove instances in the pool.
//      * <p>
//      * Calling {@link #addObject} or {@link #borrowObject} after invoking this
//      * method on a pool will cause them to throw an
//      * {@link IllegalStateException}.
//      */
//     override
//     void close() {
//         super.close();
//         clear();
//     }

//     /**
//      * Returns the {@link PooledObjectFactory} used by this pool to create and
//      * manage object instances.
//      *
//      * @return the factory
//      */
//     synchronized PooledObjectFactory!(T) getFactory() {
//         return factory;
//     }

//     /**
//      * If any idle objects were garbage collected, remove their
//      * {@link Reference} wrappers from the idle object pool.
//      */
//     private void pruneClearedReferences() {
//         // Remove wrappers for enqueued references from idle and allReferences lists
//         removeClearedReferences(idleReferences.iterator());
//         removeClearedReferences(allReferences.iterator());
//         while (refQueue.poll() !is null) {
//             // empty
//         }
//     }

//     /**
//      * Finds the PooledSoftReference in allReferences that points to obj.
//      *
//      * @param obj returning object
//      * @return PooledSoftReference wrapping a soft reference to obj
//      */
//     private PooledSoftReference!(T) findReference(T obj) {
//         Iterator!(PooledSoftReference!(T)) iterator = allReferences.iterator();
//         while (iterator.hasNext()) {
//             PooledSoftReference!(T) reference = iterator.next();
//             if (reference.getObject() !is null && reference.getObject() == obj) {
//                 return reference;
//             }
//         }
//         return null;
//     }

//     /**
//      * Destroys a {@code PooledSoftReference} and removes it from the idle and all
//      * references pools.
//      *
//      * @param toDestroy PooledSoftReference to destroy
//      *
//      * @throws Exception If an error occurs while trying to destroy the object
//      */
//     private void destroy(PooledSoftReference!(T) toDestroy){
//         toDestroy.invalidate();
//         idleReferences.remove(toDestroy);
//         allReferences.remove(toDestroy);
//         try {
//             factory.destroyObject(toDestroy);
//         } finally {
//             destroyCount++;
//             toDestroy.getReference().clear();
//         }
//     }

//     /**
//      * Clears cleared references from iterator's collection
//      * @param iterator iterator over idle/allReferences
//      */
//     private void removeClearedReferences(Iterator!(PooledSoftReference!(T)) iterator) {
//         PooledSoftReference!(T) ref;
//         while (iterator.hasNext()) {
//             ref = iterator.next();
//             if (ref.getReference() is null || ref.getReference().isEnqueued()) {
//                 iterator.remove();
//             }
//         }
//     }

//     override
//     protected void toStringAppendFields(StringBuilder builder) {
//         super.toStringAppendFields(builder);
//         builder.append(", factory=");
//         builder.append(factory);
//         builder.append(", refQueue=");
//         builder.append(refQueue);
//         builder.append(", numActive=");
//         builder.append(numActive);
//         builder.append(", destroyCount=");
//         builder.append(destroyCount);
//         builder.append(", createCount=");
//         builder.append(createCount);
//         builder.append(", idleReferences=");
//         builder.append(idleReferences);
//         builder.append(", allReferences=");
//         builder.append(allReferences);
//     }
// }
