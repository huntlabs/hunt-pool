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
module hunt.pool.impl.ThrowableCallStack;

// import java.io.PrintWriter;
// import java.text.DateFormat;
// import java.text.SimpleDateFormat;

/**
 * CallStack strategy that uses the stack trace from a {@link Throwable}. This strategy, while slower than the
 * SecurityManager implementation, provides call stack method names and other metadata in addition to the call stack
 * of classes.
 *
 * @see Throwable#fillInStackTrace()
 */
// class ThrowableCallStack : CallStack {

//     private string messageFormat;
//     //@GuardedBy("dateFormat")
//     private DateFormat dateFormat;

//     // private Snapshot snapshot;

//     /**
//      * Create a new instance.
//      *
//      * @param messageFormat message format
//      * @param useTimestamp whether to format the dates in the output message or not
//      */
//     ThrowableCallStack(string messageFormat, bool useTimestamp) {
//         this.messageFormat = messageFormat;
//         this.dateFormat = useTimestamp ? new SimpleDateFormat(messageFormat) : null;
//     }

//     override
//     synchronized bool printStackTrace(PrintWriter writer) {
//         Snapshot snapshotRef = this.snapshot;
//         if (snapshotRef is null) {
//             return false;
//         }
//         string message;
//         if (dateFormat is null) {
//             message = messageFormat;
//         } else {
//             synchronized (dateFormat) {
//                 message = dateFormat.format(Long.valueOf(snapshotRef.timestamp));
//             }
//         }
//         writer.println(message);
//         snapshotRef.printStackTrace(writer);
//         return true;
//     }

//     override
//     void fillInStackTrace() {
//         snapshot = new Snapshot();
//     }

//     override
//     void clear() {
//         snapshot = null;
//     }

//     /**
//      * A snapshot of a throwable.
//      */
//     private static class Snapshot : Throwable {

//         private long timestamp = DateTimeHelper.currentTimeMillis();
//     }
// }
