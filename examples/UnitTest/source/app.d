import std.stdio;

import hunt.util.UnitTest;
import hunt.logging.ConsoleLogger;

import test.PoolTest;

import test.impl.TestLinkedBlockingDeque;

import core.thread;

void main() {

	// Thread.getThis().isDaemon = false;
	Thread.getThis().name = "main-thread";
	trace("Main thread");
	
	// testUnits!(PoolTest);
	testUnits!(TestLinkedBlockingDeque);

	// thread_joinAll();
	trace("running here");
	getchar();
}
