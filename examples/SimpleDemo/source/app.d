import hunt.pool.PooledObject;
import hunt.pool.PooledObjectFactory;
import hunt.pool.impl.DefaultPooledObject;

import hunt.pool.impl.GenericObjectPool;
import hunt.pool.impl.GenericObjectPoolConfig;

import hunt.logging.ConsoleLogger;

import std.conv;
import std.random;
import std.stdio;

class BigObj {
	__gshared int id = 0;
	int v;
	this() {
		this.v = id++;
		trace("create " ~ v.to!string());
	}

	void destroy() {
		trace("destroy " ~ v.to!string());
	}

	int getV() {
		return v;
	}
}

class BigObjFactory : PooledObjectFactory!(BigObj) {
	Random rnd;

	this() {
		rnd = Random();
	}

	override PooledObject!(BigObj) makeObject() {
		return new DefaultPooledObject!(BigObj)(new BigObj());
	}

	override void destroyObject(IPooledObject pooledObject) {
		(cast(PooledObject!(BigObj))pooledObject).getObject().destroy();
	}

	override bool validateObject(IPooledObject pooledObject) {
		bool r = rnd.front() % 2 == 0;
		// tracef("r=%s", r);
		rnd.popFront();

		return r;

	}

	override void activateObject(IPooledObject pooledObject) {
	}

	override void passivateObject(IPooledObject pooledObject) {
	}
}

// https://blog.csdn.net/weixin_33843947/article/details/86862826
void main() {
	GenericObjectPoolConfig conf = new GenericObjectPoolConfig();
	conf.setMaxTotal(5);
	conf.setTestOnReturn(true);
	GenericObjectPool!(BigObj) pool = new GenericObjectPool!(BigObj)(new BigObjFactory(), conf);
	for (int i = 0; i < 10; i++) {
		BigObj bigObj = pool.borrowObject();
		trace(i.to!string() ~ " time get " ~ bigObj.getV().to!string());
		pool.returnObject(bigObj);
	}
}
