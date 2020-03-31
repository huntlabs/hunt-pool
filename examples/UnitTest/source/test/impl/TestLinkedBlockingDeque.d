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
module test.impl.TestLinkedBlockingDeque;

import hunt.pool.impl.LinkedBlockingDeque;

import hunt.Assert;
import hunt.collection;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.UnitTest;

import hunt.Integer;

import core.time;
import std.range;

/**
 * Tests for {@link LinkedBlockingDeque}.
 */
class TestLinkedBlockingDeque {

    private __gshared Integer ONE;
    private __gshared Integer TWO;
    private __gshared Integer THREE;

    shared static this() {
        ONE = Integer.valueOf(1);
        TWO = Integer.valueOf(2);
        THREE = Integer.valueOf(3);        
    }

    LinkedBlockingDeque!(Integer) deque;

    @Before
    void setUp() {
        deque = new LinkedBlockingDeque!Integer(2);
    }

    @Test
    void testConstructors() {
        LinkedBlockingDeque!(Integer) deque = new LinkedBlockingDeque!(Integer)();
        assertEquals(Integer.MAX_VALUE, deque.remainingCapacity());

        deque = new LinkedBlockingDeque!(Integer)(2);
        assertEquals(2, deque.remainingCapacity());

        deque = new LinkedBlockingDeque!(Integer)([ONE, TWO]);
        assertEquals(2, deque.size());

        try {
            deque = new LinkedBlockingDeque!(Integer)([ONE, null]);
            fail("Not supposed to get here");
        } catch (NullPointerException npe) {
            // OK
        }
    }

    @Test
    void testAddFirst() {
        deque.addFirst(ONE);
        deque.addFirst(TWO);
        assertEquals(2, deque.size());
        try {
            deque.addFirst(THREE);
            fail("Not supposed to get here");
        } catch (IllegalStateException e) {}
        assertEquals(Integer.valueOf(2), deque.pop());
    }

    @Test
    void testAddLast() {
        deque.addLast(ONE);
        deque.addLast(TWO);
        assertEquals(2, deque.size());
        try {
            deque.addLast(THREE);
            fail("Not supposed to get here");
        } catch (IllegalStateException e) {}
        assertEquals(Integer.valueOf(1), deque.pop());
    }

    @Test
    void testOfferFirst() {
        deque.offerFirst(ONE);
        deque.offerFirst(TWO);
        assertEquals(2, deque.size());
        try {
            deque.offerFirst(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        assertEquals(Integer.valueOf(2), deque.pop());
    }

    @Test
    void testOfferLast() {
        deque.offerLast(ONE);
        deque.offerLast(TWO);
        assertEquals(2, deque.size());
        try {
            deque.offerLast(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        assertEquals(Integer.valueOf(1), deque.pop());
    }

    @Test
    void testPutFirst(){
        try {
            deque.putFirst(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        deque.putFirst(ONE);
        deque.putFirst(TWO);
        assertEquals(2, deque.size());
        assertEquals(Integer.valueOf(2), deque.pop());
    }

    @Test
    void testPutLast(){
        try {
            deque.putLast(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        deque.putLast(ONE);
        deque.putLast(TWO);
        assertEquals(2, deque.size());
        assertEquals(Integer.valueOf(1), deque.pop());
    }

    @Test
    void testOfferFirstWithTimeout(){
        try {
            deque.offerFirst(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        assertTrue(deque.offerFirst(ONE, 50.msecs));
        assertTrue(deque.offerFirst(TWO, 50.msecs));
        assertFalse(deque.offerFirst(THREE, 50.msecs));
    }

    @Test
    void testOfferLastWithTimeout(){
        try {
            deque.offerLast(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        assertTrue(deque.offerLast(ONE, 50.msecs));
        assertTrue(deque.offerLast(TWO, 50.msecs));
        assertFalse(deque.offerLast(THREE, 50.msecs));
    }

    @Test
    void testRemoveFirst() {
        try {
            deque.removeFirst();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.removeFirst());
        try {
            deque.removeFirst();
            deque.removeFirst();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
    }

    @Test
    void testRemoveLast() {
        try {
            deque.removeLast();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(2), deque.removeLast());
        try {
            deque.removeLast();
            deque.removeLast();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
    }

    @Test
    void testPollFirst() {
        assertNull(deque.pollFirst());
        assertTrue(deque.offerFirst(ONE));
        assertTrue(deque.offerFirst(TWO));
        assertEquals(Integer.valueOf(2), deque.pollFirst());
    }

    @Test
    void testPollLast() {
        assertNull(deque.pollLast());
        assertTrue(deque.offerFirst(ONE));
        assertTrue(deque.offerFirst(TWO));
        assertEquals(Integer.valueOf(1), deque.pollLast());
    }

    @Test
    void testTakeFirst(){
        assertTrue(deque.offerFirst(ONE));
        assertTrue(deque.offerFirst(TWO));
        assertEquals(Integer.valueOf(2), deque.takeFirst());
    }

    @Test
    void testTakeLast(){
        assertTrue(deque.offerFirst(ONE));
        assertTrue(deque.offerFirst(TWO));
        assertEquals(Integer.valueOf(1), deque.takeLast());
    }

    @Test
    void testPollFirstWithTimeout(){
        assertNull(deque.pollFirst());
        Duration dur = 1.seconds; // 50.msecs;
        tracef("waiting for the result in %s", dur);
        assertNull(deque.pollFirst(dur));
        info("The time's up");
    }

    @Test
    void testPollLastWithTimeout(){
        assertNull(deque.pollLast());
        assertNull(deque.pollLast(50.msecs));
    }

    @Test
    void testGetFirst() {
        try {
            deque.getFirst();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e){}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.getFirst());
    }

    @Test
    void testGetLast() {
        try {
            deque.getLast();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e){}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(2), deque.getLast());
    }

    @Test
    void testPeekFirst() {
        assertNull(deque.peekFirst());
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.peekFirst());
    }

    @Test
    void testPeekLast() {
        assertNull(deque.peekLast());
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(2), deque.peekLast());
    }

    @Test
    void testRemoveLastOccurrence() {
        assertFalse(deque.removeLastOccurrence(null));
        assertFalse(deque.removeLastOccurrence(ONE));
        deque.add(ONE);
        deque.add(ONE);
        assertTrue(deque.removeLastOccurrence(ONE));
        assertTrue(deque.size() == 1);
    }

    @Test
    void testAdd() {
        assertTrue(deque.add(ONE));
        assertTrue(deque.add(TWO));
        try {
            assertTrue(deque.add(THREE));
            fail("Not supposed to get here");
        } catch (IllegalStateException e) {}
        try {
            assertTrue(deque.add(null));
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
    }

    @Test
    void testOffer() {
        assertTrue(deque.offer(ONE));
        assertTrue(deque.offer(TWO));
        assertFalse(deque.offer(THREE));
        try {
            deque.offer(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
    }

    @Test
    void testPut(){
        try {
            deque.put(null);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
        deque.put(ONE);
        deque.put(TWO);
    }

    @Test
    void testOfferWithTimeout(){
        assertTrue(deque.offer(ONE, 50.msecs));
        assertTrue(deque.offer(TWO, 50.msecs));
        assertFalse(deque.offer(THREE, 50.msecs));
        try {
            deque.offer(null, 50.msecs);
            fail("Not supposed to get here");
        } catch (NullPointerException e) {}
    }

    @Test
    void testRemove() {
        try {
            deque.remove();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.remove());
    }

    @Test
    void testTake(){
        assertTrue(deque.offerFirst(ONE));
        assertTrue(deque.offerFirst(TWO));
        assertEquals(Integer.valueOf(2), deque.take());
    }

    @Test
    void testPollWithTimeout(){
        assertNull(deque.poll(50.msecs));
        assertNull(deque.poll(50.msecs));
    }

    @Test
    void testElement() {
        try {
            deque.element();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e){}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.element());
    }

    @Test
    void testPeek() {
        assertNull(deque.peek());
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.peek());
    }

    @Test
    void testDrainTo() {
        Collection!(Integer) c = new ArrayList!(Integer)();
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(2, deque.drainTo(c));
        assertEquals(2, c.size());

        c = new ArrayList!(Integer)();
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(1, deque.drainTo(c, 1));
        assertEquals(1, deque.size());
        assertEquals(1, c.size());
        assertEquals(Integer.valueOf(1), c.iterator().front());
    }

    @Test
    void testPush() {
        deque.push(ONE);
        deque.push(TWO);
        assertEquals(2, deque.size());
        try {
            deque.push(THREE);
            fail("Not supposed to get here");
        } catch (IllegalStateException e) {}
        assertEquals(Integer.valueOf(2), deque.pop());
    }

    @Test
    void testPop() {
        try {
            deque.pop();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
        deque.add(ONE);
        deque.add(TWO);
        assertEquals(Integer.valueOf(1), deque.pop());
        try {
            deque.pop();
            deque.pop();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
    }

    @Test
    void testContains() {
        deque.add(ONE);
        assertTrue(deque.contains(ONE));
        assertFalse(deque.contains(TWO));
        assertFalse(deque.contains(null));
        deque.add(TWO);
        assertTrue(deque.contains(TWO));
        assertFalse(deque.contains(THREE));
    }

    @Test
    void testToArray() {
        deque.add(ONE);
        deque.add(TWO);
        Integer[] arr = deque.toArray();
        assertEquals(Integer.valueOf(1), arr[0]);
        assertEquals(Integer.valueOf(2), arr[1]);
    }

    @Test
    void testClear() {
        deque.add(ONE);
        deque.add(TWO);
        deque.clear();
        deque.add(ONE);
        assertEquals(1, deque.size());
    }

    @Test
    void testIterator() {
        try {
            deque.iterator().popFront();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
        deque.add(ONE);
        deque.add(TWO);
        InputRange!(Integer) iter = deque.iterator();
        assertEquals(Integer.valueOf(1), iter.front());
        // iter.remove();
        iter.popFront();
        assertEquals(Integer.valueOf(2), iter.front());
    }

    @Test
    void testDescendingIterator() {
        try {
            deque.descendingIterator().popFront();
            fail("Not supposed to get here");
        } catch (NoSuchElementException e) {}
        deque.add(ONE);
        deque.add(TWO);
        InputRange!(Integer) iter = deque.descendingIterator();
        assertEquals(Integer.valueOf(2), iter.front());
        iter.popFront();
        assertEquals(Integer.valueOf(1), iter.front());
    }

    /*
     * https://issues.apache.org/jira/browse/POOL-281
     *
     * Should complete almost instantly when the issue is fixed.
     */
    @Test(10000.msecs)
    void testPossibleBug() {

        deque = new LinkedBlockingDeque!(Integer)();
        for (int i = 0; i < 3; i++) {
            deque.add(Integer.valueOf(i));
        }

        // This particular sequence of method calls() (there may be others)
        // creates an internal state that triggers an infinite loop in the
        // iterator.
        InputRange!(Integer) iter = deque.iterator();
        iter.popFront();

        deque.remove(Integer.valueOf(1));
        deque.remove(Integer.valueOf(0));
        deque.remove(Integer.valueOf(2));

        iter.popFront();
    }
}

