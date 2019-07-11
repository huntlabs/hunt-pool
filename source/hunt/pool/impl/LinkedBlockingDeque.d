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
module hunt.pool.impl.LinkedBlockingDeque;

// import java.io.Serializable;
// import java.util.AbstractQueue;
// import java.util.Collection;
// import java.util.Deque;
// import java.util.Iterator;
// import java.util.NoSuchElementException;
// import java.util.concurrent.TimeUnit;
// import java.util.concurrent.locks.Condition;

import hunt.collection;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;

import core.time;
// import core.sync.condition;
import hunt.pool.impl.Condition;
import hunt.pool.impl.Mutex;
// import core.sync.mutex;

import std.algorithm;
import std.range;


/**
 * An optionally-bounded {@linkplain java.util.concurrent.BlockingDeque blocking
 * deque} based on linked nodes.
 *
 * <p> The optional capacity bound constructor argument serves as a
 * way to prevent excessive expansion. The capacity, if unspecified,
 * is equal to {@link Integer#MAX_VALUE}.  Linked nodes are
 * dynamically created upon each insertion unless this would bring the
 * deque above capacity.
 *
 * <p>Most operations run in constant time (ignoring time spent
 * blocking).  Exceptions include {@link #remove(Object) remove},
 * {@link #removeFirstOccurrence removeFirstOccurrence}, {@link
 * #removeLastOccurrence removeLastOccurrence}, {@link #contains
 * contains}, {@link #iterator iterator.remove()}, and the bulk
 * operations, all of which run in linear time.
 *
 * <p>This class and its iterator implement all of the
 * <em>optional</em> methods of the {@link Collection} and {@link
 * Iterator} interfaces.
 *
 * <p>This class is a member of the
 * <a href="{@docRoot}/../technotes/guides/collections/index.html">
 * Java Collections Framework</a>.
 *
 * @param <E> the type of elements held in this collection
 *
 * Note: This was copied from Apache Harmony and modified to suit the needs of
 *       Commons Pool.
 *
 */
class LinkedBlockingDeque(E) : AbstractDeque!(E) { // , Serializable 

    /*
     * Implemented as a simple doubly-linked list protected by a
     * single lock and using conditions to manage blocking.
     *
     * To implement weakly consistent iterators, it appears we need to
     * keep all Nodes GC-reachable from a predecessor dequeued Node.
     * That would cause two problems:
     * - allow a rogue Iterator to cause unbounded memory retention
     * - cause cross-generational linking of old Nodes to new Nodes if
     *   a Node was tenured while live, which generational GCs have a
     *   hard time dealing with, causing repeated major collections.
     * However, only non-deleted Nodes need to be reachable from
     * dequeued Nodes, and reachability does not necessarily have to
     * be of the kind understood by the GC.  We use the trick of
     * linking a Node that has just been dequeued to itself.  Such a
     * self-link implicitly means to jump to "first" (for next links)
     * or "last" (for prev links).
     */

    /*
     * We have "diamond" multiple interface/abstract class inheritance
     * here, and that introduces ambiguities. Often we want the
     * BlockingDeque javadoc combined with the AbstractQueue
     * implementation, so a lot of method specs are duplicated here.
     */



    /**
     * Doubly-linked list node class.
     *
     * @param <E> node item type
     */
    private static class Node(E) {
        /**
         * The item, or null if this node has been removed.
         */
        E item;

        /**
         * One of:
         * - the real predecessor Node
         * - this Node, meaning the predecessor is tail
         * - null, meaning there is no predecessor
         */
        Node!(E) prev;

        /**
         * One of:
         * - the real successor Node
         * - this Node, meaning the successor is head
         * - null, meaning there is no successor
         */
        Node!(E) next;

        /**
         * Create a new list node.
         *
         * @param x The list item
         * @param p Previous item
         * @param n Next item
         */
        this(E x, Node!(E) p, Node!(E) n) {
            item = x;
            prev = p;
            next = n;
        }
    }

    /**
     * Pointer to first node.
     * Invariant: (first is null && last is null) ||
     *            (first.prev is null && first.item !is null)
     */
    private Node!(E) first; // @GuardedBy("lock")

    /**
     * Pointer to last node.
     * Invariant: (first is null && last is null) ||
     *            (last.next is null && last.item !is null)
     */
    private Node!(E) last; // @GuardedBy("lock")

    /** Number of items in the deque */
    private int count; // @GuardedBy("lock")

    /** Maximum number of items in the deque */
    private int capacity;

    /** Main lock guarding all access */
    private Mutex lock;

    /** Condition for waiting takes */
    private Condition notEmpty;

    /** Condition for waiting puts */
    private Condition notFull;

    /**
     * Creates a {@code LinkedBlockingDeque} with a capacity of
     * {@link Integer#MAX_VALUE}.
     */
    this() {
        this(int.max);
    }

    /**
     * Creates a {@code LinkedBlockingDeque} with a capacity of
     * {@link Integer#MAX_VALUE} and the given fairness policy.
     * @param fairness true means threads waiting on the deque should be served
     * as if waiting in a FIFO request queue
     */
    this(bool fairness) {
        this(int.max, fairness);
    }

    /**
     * Creates a {@code LinkedBlockingDeque} with the given (fixed) capacity.
     *
     * @param capacity the capacity of this deque
     * @throws IllegalArgumentException if {@code capacity} is less than 1
     */
    this(int capacity) {
        this(capacity, false);
    }

    /**
     * Creates a {@code LinkedBlockingDeque} with the given (fixed) capacity
     * and fairness policy.
     *
     * @param capacity the capacity of this deque
     * @param fairness true means threads waiting on the deque should be served
     * as if waiting in a FIFO request queue
     * @throws IllegalArgumentException if {@code capacity} is less than 1
     */
    this(int capacity, bool fairness) {
        if (capacity <= 0) {
            throw new IllegalArgumentException();
        }
        this.capacity = capacity;
        lock = new Mutex(); // new InterruptibleReentrantLock(fairness);
        notEmpty = new Condition(lock); // lock.newCondition();
        notFull = new Condition(lock); // lock.newCondition();
    }

    /**
     * Creates a {@code LinkedBlockingDeque} with a capacity of
     * {@link Integer#MAX_VALUE}, initially containing the elements of
     * the given collection, added in traversal order of the
     * collection's iterator.
     *
     * @param c the collection of elements to initially contain
     * @throws NullPointerException if the specified collection or any
     *         of its elements are null
     */
    this(Collection!E c) {
        this(int.max);

        foreach(E e ; c) {
            if (e is null) {
                throw new NullPointerException();
            }
            if (!linkLast(e)) {
                throw new IllegalStateException("Deque full");
            }
        }
    }

    this(E[] c) {
        this(int.max);
        foreach(E e ; c) {
            if (e is null) {
                throw new NullPointerException();
            }
            if (!linkLast(e)) {
                throw new IllegalStateException("Deque full");
            }
        }
    }

    // Basic linking and unlinking operations, called only while holding lock

    /**
     * Links provided element as first element, or returns false if full.
     *
     * @param e The element to link as the first element.
     *
     * @return {@code true} if successful, otherwise {@code false}
     */
    private bool linkFirst(E e) {
        // assert lock.isHeldByCurrentThread();
        if (count >= capacity) {
            return false;
        }
        Node!(E) f = first;
        Node!(E) x = new Node!(E)(e, null, f);
        first = x;
        if (last is null) {
            last = x;
        } else {
            f.prev = x;
        }
        ++count;
        notEmpty.notify();
        return true;
    }

    /**
     * Links provided element as last element, or returns false if full.
     *
     * @param e The element to link as the last element.
     *
     * @return {@code true} if successful, otherwise {@code false}
     */
    private bool linkLast(E e) {
        // assert lock.isHeldByCurrentThread();
        if (count >= capacity) {
            return false;
        }
        Node!(E) l = last;
        Node!(E) x = new Node!E(e, l, null);
        last = x;
        if (first is null) {
            first = x;
        } else {
            l.next = x;
        }
        ++count;
        notEmpty.notify();
        return true;
    }

    /**
     * Removes and returns the first element, or null if empty.
     *
     * @return The first element or {@code null} if empty
     */
    private E unlinkFirst() {
        // assert lock.isHeldByCurrentThread();
        Node!(E) f = first;
        if (f is null) {
            return null;
        }
        Node!(E) n = f.next;
        E item = f.item;
        f.item = null;
        f.next = f; // help GC
        first = n;
        if (n is null) {
            last = null;
        } else {
            n.prev = null;
        }
        --count;
        notFull.notify();
        return item;
    }

    /**
     * Removes and returns the last element, or null if empty.
     *
     * @return The first element or {@code null} if empty
     */
    private E unlinkLast() {
        // assert lock.isHeldByCurrentThread();
        Node!(E) l = last;
        if (l is null) {
            return null;
        }
        Node!(E) p = l.prev;
        E item = l.item;
        l.item = null;
        l.prev = l; // help GC
        last = p;
        if (p is null) {
            first = null;
        } else {
            p.next = null;
        }
        --count;
        notFull.notify();
        return item;
    }

    /**
     * Unlinks the provided node.
     *
     * @param x The node to unlink
     */
    private void unlink(Node!(E) x) {
        // assert lock.isHeldByCurrentThread();
        Node!(E) p = x.prev;
        Node!(E) n = x.next;
        if (p is null) {
            unlinkFirst();
        } else if (n is null) {
            unlinkLast();
        } else {
            p.next = n;
            n.prev = p;
            x.item = null;
            // Don't mess with x's links.  They may still be in use by
            // an iterator.
        --count;
            notFull.notify();
        }
    }

    // BlockingDeque methods

    /**
     * {@inheritDoc}
     */
    override
    bool offerFirst(E e) {
        if (e is null) {
            throw new NullPointerException();
        }
        lock.lock();
        try {
            return linkFirst(e);
        } finally {
            lock.unlock();
        }
    }

    /**
     * {@inheritDoc}
     */
    override bool offerLast(E e) {
        if (e is null) {
            throw new NullPointerException();
        }
        lock.lock();
        try {
            return linkLast(e);
        } finally {
            lock.unlock();
        }
    }

    /**
     * Links the provided element as the first in the queue, waiting until there
     * is space to do so if the queue is full.
     *
     * @param e element to link
     *
     * @throws NullPointerException if e is null
     * @throws InterruptedException if the thread is interrupted whilst waiting
     *         for space
     */
    void putFirst(E e){
        if (e is null) {
            throw new NullPointerException();
        }
        lock.lock();
        try {
            while (!linkFirst(e)) {
                notFull.wait();
            }
        } finally {
            lock.unlock();
        }
    }

    /**
     * Links the provided element as the last in the queue, waiting until there
     * is space to do so if the queue is full.
     *
     * @param e element to link
     *
     * @throws NullPointerException if e is null
     * @throws InterruptedException if the thread is interrupted whilst waiting
     *         for space
     */
    override void putLast(E e) {
        if (e is null) {
            throw new NullPointerException();
        }
        lock.lock();
        try {
            while (!linkLast(e)) {
                notFull.wait();
            }
        } finally {
            lock.unlock();
        }
    }

    /**
     * Links the provided element as the first in the queue, waiting up to the
     * specified time to do so if the queue is full.
     *
     * @param e         element to link
     * @param timeout   length of time to wait
     * @param unit      units that timeout is expressed in
     *
     * @return {@code true} if successful, otherwise {@code false}
     *
     * @throws NullPointerException if e is null
     * @throws InterruptedException if the thread is interrupted whilst waiting
     *         for space
     */
    bool offerFirst(E e, Duration timeout) {
        if (e is null) {
            throw new NullPointerException();
        }
        // long nanos = unit.toNanos(timeout);
        lock.lock();
        bool isTimeout = false;
        try {
            while (!linkFirst(e)) {
                if (isTimeout) {
                    return false;
                }
                // nanos = notFull.awaitNanos(nanos);
// TODO: Tasks pending completion -@zxp at 7/10/2019, 1:31:30 PM                
// 
                isTimeout = !notFull.wait(timeout);
            }
            return true;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Links the provided element as the last in the queue, waiting up to the
     * specified time to do so if the queue is full.
     *
     * @param e         element to link
     * @param timeout   length of time to wait
     * @param unit      units that timeout is expressed in
     *
     * @return {@code true} if successful, otherwise {@code false}
     *
     * @throws NullPointerException if e is null
     * @throws InterruptedException if the thread is interrupted whist waiting
     *         for space
     */
    override bool offerLast(E e, Duration timeout) {
        if (e is null) {
            throw new NullPointerException();
        }
        // long nanos = unit.toNanos(timeout);
        lock.lock();
        bool isTimeout = false;
        try {
            while (!linkLast(e)) {
                if (isTimeout) {
                    return false;
                }
                isTimeout = !notFull.wait(timeout);
            }
            return true;
        } finally {
            lock.unlock();
        }
    }

    override
    E pollFirst() {
        lock.lock();
        try {
            return unlinkFirst();
        } finally {
            lock.unlock();
        }
    }

    override
    E pollLast() {
        lock.lock();
        try {
            return unlinkLast();
        } finally {
            lock.unlock();
        }
    }

    /**
     * Unlinks the first element in the queue, waiting until there is an element
     * to unlink if the queue is empty.
     *
     * @return the unlinked element
     * @throws InterruptedException if the current thread is interrupted
     */
    override E takeFirst() {
        lock.lock();
        try {
            E x;
            while ( (x = unlinkFirst()) is null) {
                notEmpty.wait();
            }
            return x;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Unlinks the last element in the queue, waiting until there is an element
     * to unlink if the queue is empty.
     *
     * @return the unlinked element
     * @throws InterruptedException if the current thread is interrupted
     */
    E takeLast(){
        lock.lock();
        try {
            E x;
            while ( (x = unlinkLast()) is null) {
                notEmpty.wait();
            }
            return x;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Unlinks the first element in the queue, waiting up to the specified time
     * to do so if the queue is empty.
     *
     * @param timeout   length of time to wait
     * @param unit      units that timeout is expressed in
     *
     * @return the unlinked element
     * @throws InterruptedException if the current thread is interrupted
     */
    override E pollFirst(Duration timeout) {
        lock.lock();
        
        bool isTimeout = false;
        try {
            E x;
            while ( (x = unlinkFirst()) is null) {
                if (isTimeout) {
                    return null;
                }
                isTimeout = !notEmpty.wait(timeout);
            }
            return x;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Unlinks the last element in the queue, waiting up to the specified time
     * to do so if the queue is empty.
     *
     * @param timeout   length of time to wait
     * @param unit      units that timeout is expressed in
     *
     * @return the unlinked element
     * @throws InterruptedException if the current thread is interrupted
     */
    E pollLast(Duration timeout) {
        // long nanos = unit.toNanos(timeout);
        lock.lock();
        bool isTimeout = false;
        try {
            E x;
            while ( (x = unlinkLast()) is null) {
                if (isTimeout) {
                    return null;
                }
                isTimeout = !notEmpty.wait(timeout);
            }
            return x;
        } finally {
            lock.unlock();
        }
    }

    /**
     * {@inheritDoc}
     */
    override
    E getFirst() {
        E x = peekFirst();
        if (x is null) {
            throw new NoSuchElementException();
        }
        return x;
    }

    /**
     * {@inheritDoc}
     */
    override
    E getLast() {
        E x = peekLast();
        if (x is null) {
            throw new NoSuchElementException();
        }
        return x;
    }

    override
    E peekFirst() {
        lock.lock();
        try {
            return first is null ? null : first.item;
        } finally {
            lock.unlock();
        }
    }

    override
    E peekLast() {
        lock.lock();
        try {
            return last is null ? null : last.item;
        } finally {
            lock.unlock();
        }
    }

    override
    bool removeFirstOccurrence(E o) {
        if (o is null) {
            return false;
        }
        lock.lock();
        try {
            for (Node!(E) p = first; p !is null; p = p.next) {
                if (o == p.item) {
                    unlink(p);
                    return true;
                }
            }
            return false;
        } finally {
            lock.unlock();
        }
    }

    // override
    bool removeLastOccurrence(E o) {
        if (o is null) {
            return false;
        }
        lock.lock();
        try {
            for (Node!(E) p = last; p !is null; p = p.prev) {
                if (o == p.item) {
                    unlink(p);
                    return true;
                }
            }
            return false;
        } finally {
            lock.unlock();
        }
    }

    // BlockingQueue methods

    /**
     * Returns the number of additional elements that this deque can ideally
     * (in the absence of memory or resource constraints) accept without
     * blocking. This is always equal to the initial capacity of this deque
     * less the current {@code size} of this deque.
     *
     * <p>Note that you <em>cannot</em> always tell if an attempt to insert
     * an element will succeed by inspecting {@code remainingCapacity}
     * because it may be the case that another thread is about to
     * insert or remove an element.
     *
     * @return The number of additional elements the queue is able to accept
     */
    int remainingCapacity() {
        lock.lock();
        try {
            return capacity - count;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Drains the queue to the specified collection.
     *
     * @param c The collection to add the elements to
     *
     * @return number of elements added to the collection
     *
     * @throws UnsupportedOperationException if the add operation is not
     *         supported by the specified collection
     * @throws ClassCastException if the class of the elements held by this
     *         collection prevents them from being added to the specified
     *         collection
     * @throws NullPointerException if c is null
     * @throws IllegalArgumentException if c is this instance
     */
    int drainTo(Collection!E c) {
        return drainTo(c, int.max);
    }

    /**
     * Drains no more than the specified number of elements from the queue to the
     * specified collection.
     *
     * @param c           collection to add the elements to
     * @param maxElements maximum number of elements to remove from the queue
     *
     * @return number of elements added to the collection
     * @throws UnsupportedOperationException if the add operation is not
     *         supported by the specified collection
     * @throws ClassCastException if the class of the elements held by this
     *         collection prevents them from being added to the specified
     *         collection
     * @throws NullPointerException if c is null
     * @throws IllegalArgumentException if c is this instance
     */
    int drainTo(Collection!E c, int maxElements) {
        if (c is null) {
            throw new NullPointerException();
        }
        if (c is this) {
            throw new IllegalArgumentException();
        }
        lock.lock();
        try {
            int n = min(maxElements, count);
            for (int i = 0; i < n; i++) {
                c.add(first.item);   // In this order, in case add() throws.
                unlinkFirst();
            }
            return n;
        } finally {
            lock.unlock();
        }
    }

    // Collection methods

    /**
     * Returns the number of elements in this deque.
     *
     * @return the number of elements in this deque
     */
    override
    int size() {
        lock.lock();
        try {
            return count;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Returns {@code true} if this deque contains the specified element.
     * More formally, returns {@code true} if and only if this deque contains
     * at least one element {@code e} such that {@code o == e}.
     *
     * @param o object to be checked for containment in this deque
     * @return {@code true} if this deque contains the specified element
     */
    override
    bool contains(E o) {
        if (o is null) {
            return false;
        }
        lock.lock();
        try {
            for (Node!(E) p = first; p !is null; p = p.next) {
                if (o == p.item) {
                    return true;
                }
            }
            return false;
        } finally {
            lock.unlock();
        }
    }

    /*
     * TODO: Add support for more efficient bulk operations.
     *
     * We don't want to acquire the lock for every iteration, but we
     * also want other threads a chance to interact with the
     * collection, especially when count is close to capacity.
     */

//     /**
//      * Adds all of the elements in the specified collection to this
//      * queue.  Attempts to addAll of a queue to itself result in
//      * {@code IllegalArgumentException}. Further, the behavior of
//      * this operation is undefined if the specified collection is
//      * modified while the operation is in progress.
//      *
//      * @param c collection containing elements to be added to this queue
//      * @return {@code true} if this queue changed as a result of the call
//      * @throws ClassCastException
//      * @throws NullPointerException
//      * @throws IllegalArgumentException
//      * @throws IllegalStateException
//      * @see #add(Object)
//      */
//     bool addAll(Collection<? extends E> c) {
//         if (c is null)
//             throw new NullPointerException();
//         if (c == this)
//             throw new IllegalArgumentException();
//         ReentrantLock lock = this.lock;
//         lock.lock();
//         try {
//             bool modified = false;
//             foreach(E e ; c)
//                 if (linkLast(e))
//                     modified = true;
//             return modified;
//         } finally {
//             lock.unlock();
//         }
//     }

    /**
     * Returns an array containing all of the elements in this deque, in
     * proper sequence (from first to last element).
     *
     * <p>The returned array will be "safe" in that no references to it are
     * maintained by this deque.  (In other words, this method must allocate
     * a new array).  The caller is thus free to modify the returned array.
     *
     * <p>This method acts as bridge between array-based and collection-based
     * APIs.
     *
     * @return an array containing all of the elements in this deque
     */
    override
    E[] toArray() {
        lock.lock();
        try {
            E[] a = new E[count];
            int k = 0;
            for (Node!(E) p = first; p !is null; p = p.next) {
                a[k++] = p.item;
            }
            return a;
        } finally {
            lock.unlock();
        }
    }

    /**
     * {@inheritDoc}
     */
    // override
    // <T> T[] toArray(T[] a) {
    //     lock.lock();
    //     try {
    //         if (a.length < count) {
    //             a = (T[])java.lang.reflect.Array.newInstance
    //                 (a.getClass().getComponentType(), count);
    //         }
    //         int k = 0;
    //         for (Node!(E) p = first; p !is null; p = p.next) {
    //             a[k++] = (T)p.item;
    //         }
    //         if (a.length > k) {
    //             a[k] = null;
    //         }
    //         return a;
    //     } finally {
    //         lock.unlock();
    //     }
    // }

    override
    string toString() {
        lock.lock();
        try {
            return super.toString();
        } finally {
            lock.unlock();
        }
    }

    /**
     * Atomically removes all of the elements from this deque.
     * The deque will be empty after this call returns.
     */
    override
    void clear() {
        lock.lock();
        try {
            for (Node!(E) f = first; f !is null;) {
                f.item = null;
                Node!(E) n = f.next;
                f.prev = null;
                f.next = null;
                f = n;
            }
            first = last = null;
            count = 0;
            // notFull.signalAll();
            notFull.notifyAll();
        } finally {
            lock.unlock();
        }
    }

    /**
     * Returns an iterator over the elements in this deque in proper sequence.
     * The elements will be returned in order from first (head) to last (tail).
     * The returned {@code Iterator} is a "weakly consistent" iterator that
     * will never throw {@link java.util.ConcurrentModificationException
     * ConcurrentModificationException},
     * and guarantees to traverse elements as they existed upon
     * construction of the iterator, and may (but is not guaranteed to)
     * reflect any modifications subsequent to construction.
     *
     * @return an iterator over the elements in this deque in proper sequence
     */
    override
    InputRange!(E) iterator() {
        return new Itr();
    }

    /**
     * {@inheritDoc}
     */
    // override
    InputRange!(E) descendingIterator() {
        return new DescendingItr();
    }

    /**
     * Base class for Iterators for LinkedBlockingDeque
     */
    private abstract class AbstractItr : InputRange!(E) {
        /**
         * The next node to return in next()
         */
         Node!(E) next;

        /**
         * nextItem holds on to item fields because once we claim that
         * an element exists in hasNext(), we must return item read
         * under lock (in advance()) even if it was in the process of
         * being removed when hasNext() was called.
         */
        E nextItem;

        /**
         * Node returned by most recent call to next. Needed by remove.
         * Reset to null if this element is deleted by a call to remove.
         */
        private Node!(E) lastRet;

        /**
         * Obtain the first node to be returned by the iterator.
         *
         * @return first node
         */
        abstract Node!(E) firstNode();

        /**
         * For a given node, obtain the next node to be returned by the
         * iterator.
         *
         * @param n given node
         *
         * @return next node
         */
        abstract Node!(E) nextNode(Node!(E) n);

        /**
         * Create a new iterator. Sets the initial position.
         */
        this() {
            // set to initial position
            lock.lock();
            try {
                next = firstNode();
                nextItem = next is null ? null : next.item;
            } finally {
                lock.unlock();
            }
        }

        /**
         * Returns the successor node of the given non-null, but
         * possibly previously deleted, node.
         *
         * @param n node whose successor is sought
         * @return successor node
         */
        private Node!(E) succ(Node!(E) n) {
            // Chains of deleted nodes ending in null or self-links
            // are possible if multiple interior nodes are removed.
            for (;;) {
                Node!(E) s = nextNode(n);
                if (s is null) {
                    return null;
                } else if (s.item !is null) {
                    return s;
                } else if (s == n) {
                    return firstNode();
                } else {
                    n = s;
                }
            }
        }

        /**
         * Advances next.
         */
        void advance() {
            lock.lock();
            try {
                // assert next !is null;
                next = succ(next);
                nextItem = next is null ? null : next.item;
            } finally {
                lock.unlock();
            }
        }

        // override
        bool empty() {
            return next is null;
        }

        // override
        E front() {
            if (next is null) {
                throw new NoSuchElementException();
            }
            return nextItem;
            // lastRet = next;
            // E x = nextItem;
            // advance();
            // return x;
        }
        
        void popFront() {
            if (next is null) {
                throw new NoSuchElementException();
            }
            lastRet = next;
            advance();
        }

        // override
        void remove() {
            Node!(E) n = lastRet;
            if (n is null) {
                throw new IllegalStateException();
            }
            lastRet = null;
            lock.lock();
            try {
                if (n.item !is null) {
                    unlink(n);
                }
            } finally {
                lock.unlock();
            }
        }
        
        E moveFront() @property { throw new NotSupportedException(); }

        
        int opApply(scope int delegate(E) dg) {
            if(dg is null)
                throw new NullPointerException();
            
            int result = 0;
            lock.lock();
            scope(exit) {
                lock.unlock();
            }

            while(next !is null) {
                result = dg(nextItem);
                next = succ(next);
                nextItem = next is null ? null : next.item;                
            }
            
            return result;
        }

        /// Ditto
        int opApply(scope int delegate(size_t, E) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            lock.lock();
            scope(exit) {
                lock.unlock();
            }

            size_t index = 0;
            while(next !is null) {
                result = dg(index, nextItem);
                next = succ(next);
                nextItem = next is null ? null : next.item;
                index++;         
            }
            
            return result;                
        }
    }

    /** Forward iterator */
    private class Itr : AbstractItr {
        override Node!(E) firstNode() { return first; }

        override Node!(E) nextNode(Node!(E) n) { return n.next; }

        }

    /** Descending iterator */
    private class DescendingItr : AbstractItr {
        override Node!(E) firstNode() { return last; }

        override Node!(E) nextNode(Node!(E) n) { return n.prev; }
    }

    /**
     * Saves the state of this deque to a stream (that is, serialize it).
     *
     * @serialData The capacity (int), followed by elements (each an
     * {@code Object}) in the proper order, followed by a null
     * @param s the stream
     */
    // private void writeObject(java.io.ObjectOutputStream s) {
    //     lock.lock();
    //     try {
    //         // Write out capacity and any hidden stuff
    //         s.defaultWriteObject();
    //         // Write out all elements in the proper order.
    //         for (Node!(E) p = first; p !is null; p = p.next) {
    //             s.writeObject(p.item);
    //         }
    //         // Use trailing null as sentinel
    //         s.writeObject(null);
    //     } finally {
    //         lock.unlock();
    //     }
    // }

    /**
     * Reconstitutes this deque from a stream (that is,
     * deserialize it).
     * @param s the stream
     */
    // private void readObject(java.io.ObjectInputStream s)
    //     throws java.io.IOException, ClassNotFoundException {
    //     s.defaultReadObject();
    //     count = 0;
    //     first = null;
    //     last = null;
    //     // Read in all elements and place in queue
    //     for (;;) {
    //         @SuppressWarnings("unchecked")
    //         final
    //         E item = (E)s.readObject();
    //         if (item is null) {
    //             break;
    //         }
    //         add(item);
    //     }
    // }

    // Monitoring methods

    /**
     * Returns true if there are threads waiting to take instances from this deque. See disclaimer on accuracy in
     * {@link java.util.concurrent.locks.ReentrantLock#hasWaiters(Condition)}.
     *
     * @return true if there is at least one thread waiting on this deque's notEmpty condition.
     */
    bool hasTakeWaiters() {
        lock.lock();
        try {
            // return lock.hasWaiters(notEmpty);
            trace("waiters: ", notEmpty.getWaitQueueLength());
            return notEmpty.hasWaiters();
        } finally {
            lock.unlock();
        }
    }

    /**
     * Returns the length of the queue of threads waiting to take instances from this deque. See disclaimer on accuracy
     * in {@link java.util.concurrent.locks.ReentrantLock#getWaitQueueLength(Condition)}.
     *
     * @return number of threads waiting on this deque's notEmpty condition.
     */
    int getTakeQueueLength() {
        lock.lock();
        try {
        //    return lock.getWaitQueueLength(notEmpty);
            return notEmpty.getWaitQueueLength();
        } finally {
            lock.unlock();
        }
    }

    /**
     * Interrupts the threads currently waiting to take an object from the pool. See disclaimer on accuracy in
     * {@link java.util.concurrent.locks.ReentrantLock#getWaitingThreads(Condition)}.
     */
    void interuptTakeWaiters() {
        lock.lock();
        try {
        //    lock.interruptWaiters(notEmpty);
            notEmpty.notifyAll();
        } finally {
            lock.unlock();
        }
    }
}
