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
module hunt.pool.impl.DefaultPooledObjectInfo;

import hunt.pool.impl.DefaultPooledObjectInfoMBean;
// import java.io.PrintWriter;
// import java.io.StringWriter;
// import java.text.SimpleDateFormat;

import hunt.Exceptions;

import hunt.pool.PooledObject;

/**
 * Implementation of object that is used to provide information on pooled
 * objects via JMX.
 *
 */
class DefaultPooledObjectInfo : DefaultPooledObjectInfoMBean {

    private IPooledObject pooledObject;

    /**
     * Create a new instance for the given pooled object.
     *
     * @param pooledObject The pooled object that this instance will represent
     */
    this(IPooledObject pooledObject) {
        this.pooledObject = pooledObject;
    }

    override
    long getCreateTime() {
        return pooledObject.getCreateTime();
    }

    override
    string getCreateTimeFormatted() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z");
        return sdf.format(Long.valueOf(pooledObject.getCreateTime()));
    }

    override
    long getLastBorrowTime() {
        return pooledObject.getLastBorrowTime();
    }

    override
    string getLastBorrowTimeFormatted() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z");
        return sdf.format(Long.valueOf(pooledObject.getLastBorrowTime()));
    }

    override
    string getLastBorrowTrace() {
        StringWriter sw = new StringWriter();
        pooledObject.printStackTrace(new PrintWriter(sw));
        return sw.toString();
    }

    override
    long getLastReturnTime() {
        return pooledObject.getLastReturnTime();
    }

    override
    string getLastReturnTimeFormatted() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z");
        return sdf.format(Long.valueOf(pooledObject.getLastReturnTime()));
    }

    override
    string getPooledObjectType() {
        return pooledObject.getObject().getClass().getName();
    }

    override
    string getPooledObjectToString() {
        return pooledObject.getObject().toString();
    }

    override
    long getBorrowedCount() {
        implementationMissing(false);
        // TODO Simplify this once getBorrowedCount has been added to PooledObject
        // if (pooledObject instanceof DefaultPooledObject) {
        //     return ((DefaultPooledObject<?>) pooledObject).getBorrowedCount();
        // }
        return -1;
    }

    /**
     */
    override
    string toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("DefaultPooledObjectInfo [pooledObject=");
        builder.append(pooledObject);
        builder.append("]");
        return builder.toString();
    }
}
