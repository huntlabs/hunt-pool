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
module test.TestBaseObjectPool;


import hunt.Assert;
import hunt.collection;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.UnitTest;



// /**
//  */
// class TestBaseObjectPool : TestObjectPool {
//     private ObjectPool!(String) _pool = null;

//     /**
//      * @param minCapacity Ignored by this implemented. Used by sub-classes.
//      *
//      * @return A newly created empty pool
//      */
//     protected ObjectPool!(String) makeEmptyPool(final int minCapacity) {
//         if (this.getClass() != TestBaseObjectPool.class) {
//             fail("Subclasses of TestBaseObjectPool must reimplement this method.");
//         }
//         throw new UnsupportedOperationException("BaseObjectPool isn't a complete implementation.");
//     }

//     override
//     protected ObjectPool!(Object) makeEmptyPool(final PooledObjectFactory!(Object) factory) {
//         if (this.getClass() != TestBaseObjectPool.class) {
//             fail("Subclasses of TestBaseObjectPool must reimplement this method.");
//         }
//         throw new UnsupportedOperationException("BaseObjectPool isn't a complete implementation.");
//     }

//     /**
//      * @param n Ignored by this implemented. Used by sub-classes.
//      *
//      * @return the Nth object (zero indexed)
//      */
//     protected Object getNthObject(final int n) {
//         if (this.getClass() != TestBaseObjectPool.class) {
//             fail("Subclasses of TestBaseObjectPool must reimplement this method.");
//         }
//         throw new UnsupportedOperationException("BaseObjectPool isn't a complete implementation.");
//     }

//     protected bool isLifo() {
//         if (this.getClass() != TestBaseObjectPool.class) {
//             fail("Subclasses of TestBaseObjectPool must reimplement this method.");
//         }
//         return false;
//     }

//     protected bool isFifo() {
//         if (this.getClass() != TestBaseObjectPool.class) {
//             fail("Subclasses of TestBaseObjectPool must reimplement this method.");
//         }
//         return false;
//     }

//     // tests
//     @Test
//     void testUnsupportedOperations(){
//         if (!getClass() == TestBaseObjectPool.class) {
//             return; // skip redundant tests
//         }
//         try (final ObjectPool!(Object) pool = new TestObjectPool()) {

//             assertTrue("Negative expected.", pool.getNumIdle() < 0);
//             assertTrue("Negative expected.", pool.getNumActive() < 0);

//             try {
//                 pool.clear();
//                 fail("Expected UnsupportedOperationException");
//             } catch (final UnsupportedOperationException e) {
//                 // expected
//             }

//             try {
//                 pool.addObject();
//                 fail("Expected UnsupportedOperationException");
//             } catch (final UnsupportedOperationException e) {
//                 // expected
//             }
//         }
//     }

//     @Test
//     void testClose(){
//         @SuppressWarnings("resource")
//         final ObjectPool!(Object) pool = new TestObjectPool();

//         pool.close();
//         pool.close(); // should not error as of Pool 2.0.
//     }

//     @Test
//     void testBaseBorrow(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch(final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         assertEquals(getNthObject(0), _pool.borrowObject());
//         assertEquals(getNthObject(1), _pool.borrowObject());
//         assertEquals(getNthObject(2), _pool.borrowObject());
//         _pool.close();
//     }

//     @Test
//     void testBaseAddObject(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch(final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         try {
//             assertEquals(0, _pool.getNumIdle());
//             assertEquals(0, _pool.getNumActive());
//             _pool.addObject();
//             assertEquals(1, _pool.getNumIdle());
//             assertEquals(0, _pool.getNumActive());
//             final String obj = _pool.borrowObject();
//             assertEquals(getNthObject(0), obj);
//             assertEquals(0, _pool.getNumIdle());
//             assertEquals(1, _pool.getNumActive());
//             _pool.returnObject(obj);
//             assertEquals(1, _pool.getNumIdle());
//             assertEquals(0, _pool.getNumActive());
//         } catch(final UnsupportedOperationException e) {
//             return; // skip this test if one of those calls is unsupported
//         } finally {
//             _pool.close();
//         }
//     }

//     @Test
//     void testBaseBorrowReturn(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch(final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         String obj0 = _pool.borrowObject();
//         assertEquals(getNthObject(0), obj0);
//         String obj1 = _pool.borrowObject();
//         assertEquals(getNthObject(1), obj1);
//         String obj2 = _pool.borrowObject();
//         assertEquals(getNthObject(2), obj2);
//         _pool.returnObject(obj2);
//         obj2 = _pool.borrowObject();
//         assertEquals(getNthObject(2), obj2);
//         _pool.returnObject(obj1);
//         obj1 = _pool.borrowObject();
//         assertEquals(getNthObject(1), obj1);
//         _pool.returnObject(obj0);
//         _pool.returnObject(obj2);
//         obj2 = _pool.borrowObject();
//         if (isLifo()) {
//             assertEquals(getNthObject(2),obj2);
//         }
//         if (isFifo()) {
//             assertEquals(getNthObject(0),obj2);
//         }

//         obj0 = _pool.borrowObject();
//         if (isLifo()) {
//             assertEquals(getNthObject(0),obj0);
//         }
//         if (isFifo()) {
//             assertEquals(getNthObject(2),obj0);
//         }
//         _pool.close();
//     }

//     @Test
//     void testBaseNumActiveNumIdle(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch (final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         final String obj0 = _pool.borrowObject();
//         assertEquals(1, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         final String obj1 = _pool.borrowObject();
//         assertEquals(2, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         _pool.returnObject(obj1);
//         assertEquals(1, _pool.getNumActive());
//         assertEquals(1, _pool.getNumIdle());
//         _pool.returnObject(obj0);
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(2, _pool.getNumIdle());
//         _pool.close();
//     }

//     @Test
//     void testBaseClear(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch (final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         final String obj0 = _pool.borrowObject();
//         final String obj1 = _pool.borrowObject();
//         assertEquals(2, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         _pool.returnObject(obj1);
//         _pool.returnObject(obj0);
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(2, _pool.getNumIdle());
//         _pool.clear();
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         final Object obj2 = _pool.borrowObject();
//         assertEquals(getNthObject(2), obj2);
//         _pool.close();
//     }

//     @Test
//     void testBaseInvalidateObject(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch (final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         final String obj0 = _pool.borrowObject();
//         final String obj1 = _pool.borrowObject();
//         assertEquals(2, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         _pool.invalidateObject(obj0);
//         assertEquals(1, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         _pool.invalidateObject(obj1);
//         assertEquals(0, _pool.getNumActive());
//         assertEquals(0, _pool.getNumIdle());
//         _pool.close();
//     }

//     @Test
//     void testBaseClosePool(){
//         try {
//             _pool = makeEmptyPool(3);
//         } catch(final UnsupportedOperationException e) {
//             return; // skip this test if unsupported
//         }
//         final String obj = _pool.borrowObject();
//         _pool.returnObject(obj);

//         _pool.close();
//         try {
//             _pool.borrowObject();
//             fail("Expected IllegalStateException");
//         } catch(final IllegalStateException e) {
//             // expected
//         }
//     }

//     private static class TestObjectPool : BaseObjectPool!(Object) {
//         override
//         Object borrowObject() {
//             return null;
//         }
//         override
//         void returnObject(final Object obj) {
//         }
//         override
//         void invalidateObject(final Object obj) {
//         }
//     }
// }